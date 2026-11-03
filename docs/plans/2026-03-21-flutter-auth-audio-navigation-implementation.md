# Flutter Auth Audio Navigation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Flutter 客户端完成真实后端联调关键路径：自动 token 刷新、详情音频播放、首页跳转。

**Architecture:** 采用“网络层刷新 + 服务层映射 + 页面层交互”三段式改造。Dio 负责会话续期，Service 负责 API 到模型转换，UI 只消费稳定模型与状态。

**Tech Stack:** Flutter, Riverpod, Dio, GoRouter, just_audio, SharedPreferences

---

### Task 1: 网络层 Token Refresh

**Files:**
- Modify: `mishi_app/lib/core/network/api_client.dart`

1. 在 401 场景实现 refresh token 流程。
2. 刷新成功后重放原请求（仅一次）。
3. 刷新失败时清理本地 token。

### Task 2: Auth 服务真实后端化

**Files:**
- Modify: `mishi_app/lib/services/api/auth_service.dart`
- Modify: `mishi_app/lib/providers/auth_provider.dart`

1. 关闭登录 mock，改为真实 `/auth/login`、`/auth/refresh`。
2. 兼容后端用户字段映射（nickname -> username）。
3. 加固 prefs 初始化时序，避免异步未初始化访问。

### Task 3: 诗词数据真实 API 映射

**Files:**
- Modify: `mishi_app/lib/services/api/poem_service.dart`
- Modify: `mishi_app/lib/providers/poem_provider.dart`

1. 将推荐和详情接口响应映射为 `Poem`。
2. 移除 provider 内 mock 数据。
3. 保留加载/错误状态语义。

### Task 4: 首页跳转与详情音频

**Files:**
- Modify: `mishi_app/lib/features/home/pages/home_page.dart`
- Modify: `mishi_app/lib/features/poem_detail/pages/poem_detail_page.dart`
- Modify: `mishi_app/pubspec.yaml`

1. 首页按钮跳转到诗词详情。
2. 详情页接入 `just_audio`：播放、暂停、进度和错误提示。
3. 确保播放器释放与页面生命周期一致。

### Task 5: 验证

**Files:**
- Modify: 无（仅运行验证命令）

1. 运行 Flutter 相关检查（`flutter analyze` 或可用替代）。
2. 如环境不可运行 Flutter，记录阻塞并给出本地验证命令。
