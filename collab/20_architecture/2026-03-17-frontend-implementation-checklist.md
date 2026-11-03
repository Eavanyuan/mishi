# 前端项目实施检查清单

**生成时间**: 2026-03-17 10:20  
**负责人**: 架构指导Agent D017  
**目标**: 指导 Frontend Agent D011 完成前端项目基础架构搭建

## 1. 当前状态
- ✅ 项目已初始化 (React + TypeScript + Vite + Tailwind CSS)
- ✅ 基础配置文件已创建
- ⚠️ 项目结构不完整，缺少核心模块
- ❌ 未与 API 契约对接

## 2. 项目结构搭建清单

### 2.1 创建目录结构
```bash
src/
├── api/                    # API 客户端
│   ├── client.ts          # Axios 实例配置
│   ├── services/          # 业务服务
│   │   ├── geoService.ts
│   │   ├── poemService.ts
│   │   └── checkinService.ts
│   └── models/            # TypeScript 类型定义
│       ├── poem.ts
│       ├── poi.ts
│       ├── checkin.ts
│       └── index.ts       # 统一导出
├── components/            # 通用组件
│   ├── ui/               # 基础 UI 组件
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   └── index.ts
│   └── shared/           # 业务共享组件
│       ├── PoemCard.tsx
│       ├── LocationPicker.tsx
│       └── index.ts
├── features/              # 功能模块
│   ├── auth/             # 认证模块
│   │   ├── components/
│   │   ├── hooks/
│   │   └── pages/
│   ├── home/             # 首页模块
│   └── poem/             # 诗词模块
├── hooks/                 # 自定义 Hook
│   ├── useAuth.ts
│   ├── useLocation.ts
│   ├── useCheckin.ts
│   └── index.ts
├── stores/                # 状态管理
│   ├── authStore.ts
│   ├── poemStore.ts
│   └── checkinStore.ts
├── utils/                 # 工具函数
│   ├── format.ts
│   ├── validation.ts
│   └── constants.ts
└── App.tsx
```

### 2.2 立即创建的核心文件

#### 1. API 客户端配置 (`src/api/client.ts`)
```typescript
import axios from 'axios';

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'https://api.mishi.app/v1',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// 请求拦截器 - 添加认证头
apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  
  const deviceId = localStorage.getItem('device_id') || 'web-' + crypto.randomUUID();
  config.headers['X-Device-Id'] = deviceId;
  
  config.headers['X-App-Version'] = import.meta.env.VITE_APP_VERSION || '1.0.0';
  
  return config;
});

// 响应拦截器 - 统一错误处理
apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // 清除认证状态，跳转登录
      localStorage.removeItem('access_token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```

#### 2. 环境变量配置 (`.env.development`)
```env
VITE_API_BASE_URL=https://staging-api.mishi.app/v1
VITE_APP_VERSION=1.0.0
```

#### 3. 状态管理配置 (`src/stores/authStore.ts`)
```typescript
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface AuthState {
  token: string | null;
  user: User | null;
  isAuthenticated: boolean;
  login: (token: string, user: User) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      isAuthenticated: false,
      login: (token, user) => set({ token, user, isAuthenticated: true }),
      logout: () => set({ token: null, user: null, isAuthenticated: false }),
    }),
    { name: 'auth-storage' }
  )
);
```

#### 4. TanStack Query 配置 (`src/providers/QueryProvider.tsx`)
```typescript
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ReactQueryDevtools } from '@tanstack/react-query-devtools';
import { ReactNode } from 'react';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5分钟
      gcTime: 10 * 60 * 1000,   // 10分钟
      retry: 1,
    },
  },
});

export function QueryProvider({ children }: { children: ReactNode }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  );
}
```

#### 5. 路由配置 (`src/router.tsx`)
```typescript
import { createBrowserRouter } from 'react-router-dom';
import { Layout } from './components/layout/Layout';
import { HomePage } from './features/home/pages/HomePage';
import { LoginPage } from './features/auth/pages/LoginPage';
import { PoemDetailPage } from './features/poem/pages/PoemDetailPage';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    children: [
      {
        index: true,
        element: <HomePage />,
      },
      {
        path: 'login',
        element: <LoginPage />,
      },
      {
        path: 'poems/:poemId',
        element: <PoemDetailPage />,
      },
    ],
  },
]);
```

## 3. API 服务层实现清单

### 3.1 GeoService (`src/api/services/geoService.ts`)
```typescript
import { apiClient } from '../client';
import type { GeoNearbyResponse } from '../models';

export const geoService = {
  getNearby: async (params: { lat: number; lon: number; radius?: number; limit?: number }) => {
    const response = await apiClient.get('/geo/nearby', { params });
    return response.data.data as { pois: Poi[] };
  },
  
  checkGeofence: async (data: { userLat: number; userLon: number; poiId: number }) => {
    const response = await apiClient.post('/geo/geofence/check', data);
    return response.data.data as GeofenceCheck;
  },
};
```

### 3.2 PoemService (`src/api/services/poemService.ts`)
```typescript
import { apiClient } from '../client';
import type { PoemDetail, Recommendation } from '../models';

export const poemService = {
  recommend: async (params: { lat: number; lon: number; limit?: number; season?: string }) => {
    const response = await apiClient.get('/poems/recommend', { params });
    return response.data.data as { poems: Recommendation[] };
  },
  
  getDetail: async (poemId: number) => {
    const response = await apiClient.get(`/poems/${poemId}`);
    return response.data.data as PoemDetail;
  },
  
  getAudioInfo: async (poemId: number) => {
    const response = await apiClient.get(`/audio/${poemId}`);
    return response.data.data as AudioInfo;
  },
};
```

### 3.3 类型定义 (`src/api/models/poem.ts`)
```typescript
export interface Poem {
  poem_id: number;
  title: string;
  author: string;
  dynasty: string;
  content: string[];
  tags?: string[];
  best_seasons?: string[];
  solar_terms?: string[];
}

export interface PoemDetail extends Poem {
  interpretations: {
    textbook?: Interpretation;
    academic?: Interpretation;
    basic?: Interpretation;
  };
  related_pois: RelatedPoi[];
  media: MediaInfo;
  stats: PoemStats;
}

export interface Interpretation {
  source: string;
  content: string;
}

export interface Recommendation extends Poem {
  distance: number;
  season_tag: string;
  score: number;
  score_breakdown: ScoreBreakdown;
  related_poi: RelatedPoi;
}
```

## 4. 核心功能页面清单

### 4.1 首页 (`src/features/home/pages/HomePage.tsx`)
**功能要求**:
- 获取用户位置
- 显示附近 POI
- 显示推荐诗词列表
- 支持下拉刷新

**实现要点**:
- 使用 `useLocation` hook 获取地理位置
- 使用 TanStack Query 获取推荐数据
- 响应式布局

### 4.2 诗词详情页 (`src/features/poem/pages/PoemDetailPage.tsx`)
**功能要求**:
- 显示完整诗词内容
- 显示解读、标签、相关地点
- 音频播放功能
- 打卡按钮

### 4.3 登录页 (`src/features/auth/pages/LoginPage.tsx`)
**功能要求**:
- 手机号/密码登录
- 表单验证
- 错误提示
- 记住登录状态

## 5. 状态管理集成清单

### 5.1 自定义 Hook (`src/hooks/useLocation.ts`)
```typescript
import { useEffect, useState } from 'react';

interface Location {
  lat: number;
  lon: number;
  accuracy?: number;
}

export function useLocation() {
  const [location, setLocation] = useState<Location | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    if (!navigator.geolocation) {
      setError('浏览器不支持地理位置');
      setLoading(false);
      return;
    }
    
    navigator.geolocation.getCurrentPosition(
      (position) => {
        setLocation({
          lat: position.coords.latitude,
          lon: position.coords.longitude,
          accuracy: position.coords.accuracy,
        });
        setLoading(false);
      },
      (error) => {
        setError(`获取位置失败: ${error.message}`);
        setLoading(false);
      }
    );
  }, []);
  
  return { location, error, loading };
}
```

### 5.2 数据获取 Hook (`src/hooks/useRecommendedPoems.ts`)
```typescript
import { useQuery } from '@tanstack/react-query';
import { poemService } from '../api/services/poemService';
import { useLocation } from './useLocation';

export function useRecommendedPoems() {
  const { location } = useLocation();
  
  return useQuery({
    queryKey: ['poems', 'recommended', location?.lat, location?.lon],
    queryFn: () => {
      if (!location) throw new Error('位置未获取');
      return poemService.recommend({
        lat: location.lat,
        lon: location.lon,
        limit: 10,
      });
    },
    enabled: !!location,
    staleTime: 5 * 60 * 1000, // 5分钟
  });
}
```

## 6. 样式与 UI 组件清单

### 6.1 Tailwind CSS 配置检查
- [ ] `tailwind.config.js` 配置完整
- [ ] 设计 token 一致 (颜色、间距、字体)
- [ ] 响应式断点合理

### 6.2 基础 UI 组件
- [ ] `Button` - 支持 primary/secondary/ghost 变体
- [ ] `Card` - 诗词卡片、POI 卡片
- [ ] `Input` - 表单输入框
- [ ] `Modal` - 弹窗组件
- [ ] `LoadingSpinner` - 加载状态
- [ ] `ErrorDisplay` - 错误显示

### 6.3 业务组件
- [ ] `PoemCard` - 诗词卡片，用于列表展示
- [ ] `LocationPicker` - 位置选择器
- [ ] `CheckinButton` - 打卡按钮
- [ ] `AudioPlayer` - 音频播放器

## 7. 测试与验证清单

### 7.1 开发环境验证
```bash
# 安装依赖
npm install

# 开发服务器
npm run dev

# 代码检查
npm run lint

# 类型检查
npm run type-check
```

### 7.2 测试配置
- [ ] 配置 Vitest + Testing Library
- [ ] 编写核心工具函数测试
- [ ] 编写组件单元测试
- [ ] 配置 Mock Service Worker 模拟 API

### 7.3 构建验证
```bash
# 生产构建
npm run build

# 预览构建结果
npm run preview
```

## 8. 实施优先级与时间线

### P0 (今日完成)
1. [ ] 创建项目目录结构
2. [ ] 配置 API 客户端和认证头
3. [ ] 配置状态管理 (Zustand + TanStack Query)
4. [ ] 创建核心类型定义
5. [ ] 实现 GeoService 和 PoemService

### P1 (明日完成)
6. [ ] 创建首页基础布局
7. [ ] 实现地理位置 Hook
8. [ ] 实现诗词推荐数据获取
9. [ ] 创建基础 UI 组件库
10. [ ] 配置路由和导航

### P2 (本周完成)
11. [ ] 完成诗词详情页
12. [ ] 实现打卡功能
13. [ ] 添加错误处理和加载状态
14. [ ] 优化响应式设计
15. [ ] 添加基本测试

## 9. 质量要求

### 9.1 代码质量
- [ ] TypeScript 严格模式启用
- [ ] ESLint 规则配置合理
- [ ] 组件单一职责，合理拆分
- [ ] 适当的代码注释和文档

### 9.2 性能要求
- [ ] 代码分割配置合理
- [ ] 图片懒加载实现
- [ ] 列表虚拟化 (如需要)
- [ ] 避免不必要的重渲染

### 9.3 用户体验
- [ ] 加载状态显示
- [ ] 错误友好提示
- [ ] 离线状态处理
- [ ] 移动端触摸友好

## 10. 验收标准

### 10.1 基础功能
- [ ] 首页能获取用户位置并显示推荐诗词
- [ ] 点击诗词卡片能进入详情页
- [ ] 详情页显示完整诗词信息和解读
- [ ] 用户能进行打卡操作

### 10.2 技术指标
- [ ] 首次内容绘制 (FCP) < 1.5秒
- [ ] 最大内容绘制 (LCP) < 2.5秒
- [ ] 累计布局偏移 (CLS) < 0.1
- [ ] 打包体积 < 500KB (gzipped)

### 10.3 代码质量
- [ ] TypeScript 无类型错误
- [ ] ESLint 无错误
- [ ] 测试覆盖率 > 70% (核心功能)
- [ ] 文档完整

---

**负责人**: Frontend Agent D011  
**截止时间**: 今日完成 P0 项，明日完成 P1 项  
**状态**: 🔄 进行中  
**最后检查**: 2026-03-17 10:20