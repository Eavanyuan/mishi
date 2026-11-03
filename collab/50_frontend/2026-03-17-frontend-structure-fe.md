# 前端项目结构完善 - 执行计划

**任务 ID**: MISHI-006  
**Owner**: Frontend Agent D011  
**Approver**: 架构指导 Agent D017  
**状态**: blocked → [待解除阻塞]  
**优先级**: P2  
**前置依赖**: MISHI-002 (Flutter Base URL 修正), MISHI-018 (前端项目结构设计文档)  
**due_date**: 2026-03-18 18:00  
**检查时间**: 2026-03-17 15:22  

---

## 📋 当前状态与阻塞分析

### ✅ 前置依赖 MISHI-002 状态
```
状态: in_progress → [预计已完成]
截止时间: 2026-03-17 14:00（已过）
影响: Base URL 修正完成后前端可正常调用 API
下一步: 需要确认 MISHI-002 是否完成，如完成则解除此依赖阻塞
```

### ⏳ 前置依赖 MISHI-018 状态
```
状态: todo → [待创建]
截止时间: 2026-03-18 10:00
影响: 项目结构设计文档是实施前的必要准备
下一步: 创建 MISHI-018 设计文档后解除此依赖阻塞
```

**当前阻塞原因**: 
1. MISHI-002 状态未明确为 done（需确认）
2. MISHI-018 尚未创建（正在进行中）

---

## 📦 待执行计划

### Phase 0: 设计文档创建（立即执行） - 预计 30 分钟

#### 0.1 项目结构设计规范

**文件**: `collab/50_frontend/design/architecture/frontend-structure.md`

```markdown
# 觅诗前端项目结构规范 v1.0

## 目录规划

/mishi-frontend/
├── src/
│   ├── components/          # 可复用组件库
│   │   ├── Layout/          # 布局组件（Header, Footer, Container）
│   │   ├── SeasonLabel/     # 季节标签组件
│   │   ├── CheckInFlow/     # 打卡流程组件
│   │   └── SeasonalTheme/   # 季节主题切换组件
│   ├── pages/               # 页面模块
│   │   ├── index.html       # 主页面
│   │   ├── checkins.html    # 打卡记录页
│   │   └── seasons.html     # 季节展示页
│   ├── styles/              # 样式集合
│   │   ├── variables.css    # CSS 变量（颜色、间距等）
│   │   ├── tokens.css       # UI 令牌（引用 design/ui_spec_tokens.md）
│   │   ├── responsive.css   # 响应式断点
│   │   └── accessibility.css # 可访问性规范
│   ├── utils/               # 工具函数
│   │   ├── api.js           # API 请求封装
│   │   ├── storage.js       # 本地存储管理
│   │   └── date-utils.js    # 日期格式化与计算
│   └── assets/              # 静态资源
│       ├── icons/           # 图标集合
│       └── images/          # 图片资源
├── config/                  # 环境配置
│   ├── base.json            # 基础配置
│   ├── dev.json             # 开发环境
│   └── prod.json            # 生产环境
└── docs/                    # 文档
    ├── api-contracts.md     # API 契约说明
    └── component-api.md     # 组件 API 文档
```

## UI 设计参考源

- `design/high_fidelity_prototype.html` - 高保真原型（交互流程参考）
- `design/figma_ready_spec_modern_mishi_v1.md` - Figma 准备规格（设计规范）
- `design/ui_spec_tokens.md` - UI 令牌定义（颜色、字体、间距等）

## 组件实现要求

### 季节标签组件 (SeasonLabel)
- **职责**: 显示当前季节，提供季节性主题切换
- **Props**: 
  - `season`: string (spring|summer|autumn|winter)
  - `active`: boolean (是否激活高亮)
- **Events**:
  - `themeChange`: 触发主题切换
- **样式**: 符合 tokens.css 中的季节色板

### 打卡流程组件 (CheckInFlow)
- **职责**: 展示打卡记录与流程指引
- **Props**:
  - `checkinData`: object[] (打卡记录数组)
  - `currentSeason`: string
- **Events**:
  - `checkSubmit`: 提交打卡请求
  - `errorReport`: 上报错误信息
- **样式**: 移动端优先，支持横屏布局

## 移动端适配策略

- **断点定义**:
  - mobile: 320px - 600px
  - tablet: 601px - 1024px  
  - desktop: 1025px+
- **响应式技术**: CSS Grid + Flexbox + media queries
- **触摸优化**: 触控区域≥44px，手势操作规范

## 可访问性 (A11Y) 要求

- 语义化 HTML5 标签（header, main, nav, section）
- ARIA 属性正确应用（role, aria-label, aria-describedby）
- 焦点管理（tabindex, focus-visible）
- 颜色对比度≥4.5:1 (WCAG AA 标准)
- 键盘导航支持
```

#### 0.2 API 契约对齐文档

**文件**: `collab/50_frontend/docs/api-contracts.md`

```markdown
# 觅诗前端 API 契约说明

## 通用请求配置

### Headers
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <token>",
  "X-Client-Version": "1.0.0"
}
```

### Base URL
- 从环境变量读取: `process.env.API_BASE_URL`
- MISHI-002 完成后将提供稳定配置

## API 接口列表

### 1. 季节数据获取

**Endpoint**: GET `/api/seasons/current`  
**Method**: GET  
**响应格式**:
```json
{
  "success": true,
  "data": {
    "season": "spring",
    "label": "春",
    "color": "#FFB6C1",
    "theme": {
      "primary": "#98FB98",
      "secondary": "#FFFACD",
      "accent": "#DDA0DD"
    }
  }
}
```

**错误处理**:
- 404: 未找到当前季节数据
- 500: 服务端错误，显示降级页面

### 2. 打卡记录查询

**Endpoint**: GET `/api/checkins?date=YYYY-MM`  
**Method**: GET  
**响应格式**:
```json
{
  "success": true,
  "data": [
    {
      "id": "chk_123456",
      "date": "2026-03-17",
      "season": "spring",
      "location": "深圳",
      "mood": "happy",
      "content": "...",
      "image_url": "..."
    }
  ]
}
```

### 3. 打卡提交

**Endpoint**: POST `/api/checkins`  
**Method**: POST  
**请求体**:
```json
{
  "season": "spring",
  "location": "深圳",
  "mood": "happy",
  "content": "今日春花开...",
  "image_url": "..."
}
```

**响应格式**:
```json
{
  "success": true,
  "message": "打卡成功",
  "data": {
    "id": "chk_123456",
    "timestamp": "2026-03-17T10:30:00Z"
  }
}
```

**错误处理**:
- 400: 参数验证失败
- 409: 当天已打卡（唯一约束冲突）
- 500: 服务端错误

## 联调问题清单

| ID | 问题描述 | 优先级 | 状态 |
|----|---------|-------|------|
| FE-001 | API Base URL 配置待 MISHI-002 完成后更新 | P1 | blocked |
| FE-002 | 季节颜色 token 需从 tokens.css 加载 | P2 | todo |
| FE-003 | 打卡图片上传接口未定义，需补充 API 契约 | P2 | todo |

## 待确认事项

1. **API Base URL**: 等待 MISHI-002 提供稳定配置后更新 `config/base.json`
2. **错误态页面**: 需要后端提供标准化错误响应格式
3. **图片上传接口**: 需补充 `/api/checkins/image` 上传接口契约
```

#### 0.3 组件映射表

**文件**: `collab/50_frontend/component-mapping/index.md`

```markdown
# 前端组件映射表

## 组件清单

| 组件 ID | 组件名称 | 所属模块 | 依赖 | 状态 |
|--------|---------|---------|------|------|
| CLM-001 | SeasonLabel | components/SeasonLabel | none | todo |
| CLM-002 | CheckInFlow | components/CheckInFlow | CLM-001, API contracts | todo |
| CLM-003 | Layout.Header | components/Layout/Header | - | todo |
| CLM-004 | Layout.Footer | components/Layout/Footer | - | todo |

## 组件实现顺序

### Priority 1 (P1)
1. **SeasonLabel** (CLM-001)
   - 职责：季节标签展示与主题切换
   - 文件：`src/components/SeasonLabel/season-label.html`
   - 样式：`src/styles/SeasonLabel.css`
   - 实现时间：30 分钟

2. **CheckInFlow** (CLM-002)
   - 职责：打卡流程与记录展示
   - 文件：`src/components/CheckInFlow/checkin-flow.html`
   - 样式：`src/styles/CheckInFlow.css`
   - 实现时间：60 分钟

### Priority 2 (P2)
3. **Layout.Header** (CLM-003)
4. **Layout.Footer** (CLM-004)

## 组件 API 规范

所有组件遵循以下规范：
- Props 类型注解（JSDoc）
- Events 统一命名格式 `on<EventName>`
- 默认值明确定义
- 文档化使用示例
```

---

## 🚧 Scheduling Request

### ⏳ 依赖状态更新请求

#### 1. MISHI-002 (Flutter Base URL 修正)
- **当前状态**: in_progress
- **截止时间**: 2026-03-17 14:00（已过）
- **影响任务**: MISHI-005, MISHI-006
- **请求**: 确认该任务已完成，如完成则更新为 done 状态
- **联系**: App Agent D019

#### 2. MISHI-018 (前端项目结构设计文档)
- **当前状态**: todo → [本次正在创建]
- **截止时间**: 2026-03-18 10:00
- **负责人**: Frontend Agent D011 (本人)
- **请求**: 完成后将解锁 MISHI-006 的阻塞状态

### 📋 需要协调的事项

**阻塞项解除条件**:
```
MISHI-002 = done AND MISHI-018 = done
⇒ 更新 MISHI-006 state: blocked → todo/in_progress
```

**建议行动**:
1. App Agent 确认 MISHI-002 完成状态并更新队列
2. 架构师评审 MISHI-018 设计文档（MISHI-010）
3. 完成后 Coordinator 更新任务状态

### 📝 变更日志

| ts | actor | change |
|----|-------|--------|
| 2026-03-17 15:22 | Frontend Agent D011 | 创建执行计划，MISHI-006 保持 blocked 状态等待 MISHI-002, MISHI-018 |

---

**下一检查点**: 2026-03-17 16:00（再次确认阻塞依赖状态）  
**若前置任务全部完成**: 立即将 MISHI-006 状态转为 in_progress 并开始 Phase 1 实施
