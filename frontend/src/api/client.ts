import axios, { AxiosError } from 'axios';
import type { AxiosRequestConfig } from 'axios';

export interface ApiError {
  code: number;
  message: string;
  error_detail?: unknown;
  timestamp?: number;
}

interface ApiEnvelope<T> {
  code: number;
  message: string;
  data: T;
  timestamp: number;
  error_detail?: unknown;
}

interface RetryableRequestConfig extends AxiosRequestConfig {
  _retry?: boolean;
}

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8080/v1';
const APP_VERSION = import.meta.env.VITE_APP_VERSION ?? '1.0.0-web';

export const apiClient = axios.create({
  baseURL: BASE_URL,
  timeout: 12000,
  headers: {
    'Content-Type': 'application/json',
    'X-App-Version': APP_VERSION,
  },
});

let refreshingTokenPromise: Promise<string | null> | null = null;

function clearAuthStorage() {
  localStorage.removeItem('access_token');
  localStorage.removeItem('refresh_token');
  localStorage.removeItem('device_id');
  localStorage.removeItem('user_id');
}

function toApiError(payload: Partial<ApiError>, fallbackMessage: string): ApiError {
  return {
    code: typeof payload.code === 'number' ? payload.code : -1,
    message: payload.message ?? fallbackMessage,
    error_detail: payload.error_detail,
    timestamp: payload.timestamp,
  };
}

async function refreshAccessToken(): Promise<string | null> {
  const refreshToken = localStorage.getItem('refresh_token');
  if (!refreshToken) {
    clearAuthStorage();
    return null;
  }

  if (!refreshingTokenPromise) {
    refreshingTokenPromise = axios
      .post<ApiEnvelope<{ access_token: string; refresh_token?: string }>>(
        `${BASE_URL}/auth/refresh`,
        { refresh_token: refreshToken },
        {
          timeout: 12000,
          headers: {
            'Content-Type': 'application/json',
            'X-App-Version': APP_VERSION,
          },
        }
      )
      .then((res) => {
        const body = res.data;
        if (body.code !== 0 || !body.data?.access_token) {
          throw new Error(body.message || '刷新令牌失败');
        }
        localStorage.setItem('access_token', body.data.access_token);
        if (body.data.refresh_token) {
          localStorage.setItem('refresh_token', body.data.refresh_token);
        }
        return body.data.access_token;
      })
      .catch(() => {
        clearAuthStorage();
        return null;
      })
      .finally(() => {
        refreshingTokenPromise = null;
      });
  }

  return refreshingTokenPromise;
}

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  const deviceId = localStorage.getItem('device_id');

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  if (deviceId) {
    config.headers['X-Device-Id'] = deviceId;
  }

  return config;
});

apiClient.interceptors.response.use(
  async (response) => {
    if (response.data && typeof response.data === 'object' && 'code' in response.data) {
      const envelope = response.data as ApiEnvelope<unknown>;
      if (envelope.code === 0) {
        return envelope.data;
      }

      const config = response.config as RetryableRequestConfig;
      const isUnauthorized = envelope.code === 40101;
      const isRefreshRequest = config.url?.includes('/auth/refresh');

      if (isUnauthorized && !isRefreshRequest && !config._retry) {
        config._retry = true;
        const newToken = await refreshAccessToken();
        if (newToken) {
          config.headers = config.headers ?? {};
          config.headers.Authorization = `Bearer ${newToken}`;
          return apiClient(config);
        }
      }

      return Promise.reject(toApiError(envelope, '请求失败'));
    }

    return response.data;
  },
  async (error: AxiosError<ApiEnvelope<unknown>>) => {
    const config = (error.config ?? {}) as RetryableRequestConfig;
    const status = error.response?.status;
    const isRefreshRequest = config.url?.includes('/auth/refresh');

    if (status === 401 && !isRefreshRequest && !config._retry) {
      config._retry = true;
      const newToken = await refreshAccessToken();
      if (newToken) {
        config.headers = config.headers ?? {};
        config.headers.Authorization = `Bearer ${newToken}`;
        return apiClient(config);
      }
    }

    if (error.response?.data) {
      const body = error.response.data;
      if (typeof body.code === 'number') {
        return Promise.reject(toApiError(body, body.message || '服务异常'));
      }

      return Promise.reject(
        toApiError(
          {
            code: status ?? -1,
            message: error.message,
            error_detail: body,
          },
          '服务异常'
        )
      );
    }

    if (error.request) {
      return Promise.reject(toApiError({ code: -1, message: '网络连接失败，请检查后端是否启动' }, '网络错误'));
    }

    return Promise.reject(toApiError({ code: -2, message: error.message || '请求配置错误' }, '请求配置错误'));
  }
);

export function getErrorMessage(error: unknown, fallback = '操作失败，请稍后再试'): string {
  if (!error) return fallback;
  if (typeof error === 'string') return error;
  if (typeof error === 'object' && error !== null && 'message' in error) {
    const message = (error as { message?: unknown }).message;
    if (typeof message === 'string' && message.trim()) {
      return message;
    }
  }
  return fallback;
}

export function getApiErrorCode(error: unknown): number | undefined {
  if (typeof error === 'object' && error !== null && 'code' in error) {
    const code = (error as { code?: unknown }).code;
    if (typeof code === 'number' && Number.isFinite(code)) {
      return code;
    }
  }
  return undefined;
}

export interface PaginationParams {
  limit?: number;
  offset?: number;
}
