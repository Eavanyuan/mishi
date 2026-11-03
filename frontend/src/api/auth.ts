import { apiClient } from './client';

export interface LoginRequest {
  email?: string;
  phone?: string;
  password: string;
  device_id?: string;
}

export interface LoginUser {
  id: number;
  nickname: string;
  avatar_url?: string;
}

export interface LoginResponse {
  user: LoginUser;
  access_token: string;
  refresh_token?: string;
  expires_in: number;
  token_type: string;
}

export interface RefreshTokenResponse {
  access_token: string;
  refresh_token?: string;
  expires_in: number;
  token_type: string;
}

export async function login(req: LoginRequest): Promise<LoginResponse> {
  return apiClient.post('/auth/login', req);
}

export async function refreshToken(refreshTokenValue: string): Promise<RefreshTokenResponse> {
  return apiClient.post('/auth/refresh', { refresh_token: refreshTokenValue });
}

export async function logout(): Promise<{ logged_out: boolean }> {
  return apiClient.post('/auth/logout');
}
