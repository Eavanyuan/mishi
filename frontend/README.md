# 觅诗前端项目 (mishi-web)

觅诗项目的React前端应用，基于地理位置推荐古典诗词，提供打卡、收藏、个性化推荐等功能。

## 技术栈

- **框架**: React 18 + TypeScript
- **构建工具**: Vite
- **样式**: Tailwind CSS
- **状态管理**: Zustand
- **路由**: React Router DOM v6
- **HTTP客户端**: Axios + TanStack Query
- **UI组件库**: Lucide React (图标)
- **表单**: React Hook Form + Zod
- **日期处理**: date-fns
- **代码规范**: ESLint + Prettier + TypeScript严格模式
- **测试**: Vitest + React Testing Library (待配置)

## 项目结构

```
frontend/
├── src/
│   ├── api/           # API服务层
│   │   ├── client.ts  # HTTP客户端配置
│   │   ├── geo.ts     # 地理相关API
│   │   ├── poems.ts   # 诗词相关API
│   │   ├── checkins.ts # 打卡相关API
│   │   └── index.ts   # 统一导出
│   ├── components/    # 通用组件
│   │   ├── ui/        # 基础UI组件
│   │   ├── layout/    # 布局组件
│   │   └── features/  # 功能组件
│   ├── pages/         # 页面组件
│   │   ├── Home/      # 首页
│   │   ├── PoemDetail/# 诗词详情页
│   │   ├── Checkin/   # 打卡页面
│   │   └── Profile/   # 个人中心
│   ├── stores/        # 状态管理 (Zustand)
│   ├── hooks/         # 自定义Hook
│   ├── utils/         # 工具函数
│   ├── types/         # TypeScript类型定义
│   ├── styles/        # 全局样式
│   ├── assets/        # 静态资源
│   └── main.tsx       # 应用入口
├── public/
├── package.json
├── vite.config.ts
├── tailwind.config.js
├── tsconfig.json
└── README.md
```

## 环境要求

- Node.js >= 18
- npm >= 9

## 开发环境配置

### 1. 安装依赖

```bash
npm install
```

### 2. 启动开发服务器

```bash
npm run dev
```

应用将在 `http://localhost:5173` 启动。

### 3. 构建生产版本

```bash
npm run build
```

### 4. 预览生产构建

```bash
npm run preview
```

### 5. 代码检查

```bash
npm run lint
```

## API配置

项目已配置API基础URL为 `https://api.mishi.app/v1`。

**认证头**:
- `Authorization: Bearer <access_token>`
- `X-Device-Id: <device_id>`
- `X-App-Version: <app_version>`

## 核心功能实现

### 已实现功能

1. **项目骨架**：React + TypeScript + Vite 基础项目
2. **样式框架**：Tailwind CSS 配置完成
3. **路由系统**：React Router DOM v6 配置完成
4. **API服务层**：
   - `GeoService`: 附近POI查询
   - `PoemService`: 诗词推荐、详情查询
   - `CheckinService`: 打卡提交、历史查询
5. **状态管理**：Zustand store (用户认证、诗词数据)
6. **页面组件**：
   - 首页：欢迎区域、功能亮点、地图占位、诗词推荐
   - 诗词详情页：完整内容、解读、相关地点、音频播放
   - 打卡页面：地点识别、打卡表单、历史记录、徽章进度
   - 个人中心：用户信息、足迹地图、收藏诗词、年度报告
7. **开发工具**：TypeScript路径别名配置 (`@/` 指向 `src/`)

### 待实现功能

1. **地图集成**：接入地图服务显示附近POI
2. **用户认证**：完整的登录/注册流程
3. **实时定位**：持续监听用户位置变化
4. **图片上传**：打卡照片上传功能
5. **音频播放**：诗词朗诵音频播放器
6. **测试覆盖**：单元测试和集成测试
7. **PWA支持**：离线访问能力

## 开发说明

### 路径别名

TypeScript配置了路径别名，方便导入：

```typescript
import { getNearbyPOIs } from '@/api/geo';
import Button from '@/components/ui/Button';
```

### 状态管理

使用Zustand进行状态管理，已创建：

- `useAuthStore`: 用户认证状态
- `usePoemStore`: 诗词数据缓存

### 自定义Hook

- `useGeoLocation`: 获取用户地理位置

### 代码规范

- ESLint已配置React + TypeScript规则
- Prettier已集成
- Git提交前检查待配置 (Husky + lint-staged)

## 部署说明

### 构建

```bash
npm run build
```

构建产物位于 `dist/` 目录。

### 环境变量

创建 `.env` 文件：

```env
VITE_API_BASE_URL=https://api.mishi.app/v1
VITE_APP_VERSION=1.0.0
```

## 相关文档

- [API契约文档](../collab/70_api_contracts/2026-03-16-api-contract-v1.1.md)
- [项目架构文档](../architecture/README.md)

## 开发团队

- **前端负责人**: [负责人姓名]
- **UI/UX设计**: [设计师姓名]
- **后端对接**: [后端工程师姓名]

## 许可证

觅诗项目组 © 2026