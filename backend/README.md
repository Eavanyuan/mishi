# 觅诗项目后端

基于Go语言的REST API后端，为觅诗App提供地理感知、诗词推荐、打卡记录等功能。

## 技术栈

- **语言**: Go 1.21+
- **Web框架**: Gin
- **数据库**: PostgreSQL 15 + PostGIS 3.3 (使用pgx驱动)
- **缓存**: Redis 7+
- **配置管理**: Viper
- **日志**: Zerolog
- **测试**: testify

## 项目结构

```
backend/
├── cmd/
│   └── server/          # 主程序入口
│       └── main.go
├── internal/           # 私有应用代码
│   ├── config/         # 配置管理
│   ├── server/         # HTTP服务器
│   ├── database/       # 数据库层
│   ├── cache/          # 缓存层
│   ├── handler/        # HTTP处理器
│   ├── service/        # 业务逻辑
│   └── model/          # 数据模型
├── pkg/               # 可公开的库代码
│   ├── middleware/     # 中间件
│   ├── util/          # 工具函数
│   └── response/      # 统一响应格式
├── api/               # API定义（OpenAPI/Swagger）
├── migrations/        # 数据库迁移（如果需要）
├── scripts/           # 构建和部署脚本
├── docker-compose.yml # 开发环境
├── Dockerfile         # 生产构建
├── Makefile          # 构建命令
├── go.mod
└── go.sum
```

## 快速开始

### 前提条件

- Docker & Docker Compose
- Go 1.21+ (可选，如果使用本地开发)

### 使用 Docker Compose 启动

1. 克隆项目并进入目录：
   ```bash
   cd /Users/yuanyuan/Documents/workspace/mishi/backend
   ```

2. 准备环境变量：
   ```bash
   cp .env.example .env
   ```
   如果你希望容器里的 AI 解读可真实调用，请至少填写以下字段之一：
   ```bash
   MISHI_AI_PROVIDER=deepseek
   MISHI_AI_DEEPSEEK_API_KEY=你的_key
   ```
   或：
   ```bash
   MISHI_AI_PROVIDER=openai
   MISHI_AI_OPENAI_API_KEY=你的_key
   ```

3. 启动所有服务：
   ```bash
   make docker-up
   ```
   或直接使用：
   ```bash
   docker compose up -d
   ```

4. 验证服务是否正常运行：
   ```bash
   make health
   ```
   或手动访问：`http://localhost:8080/health`

5. 可选：执行接口级 smoke 验证：
   ```bash
   make e2e-web
   ```
   说明：
   - 如果容器环境未配置 AI API Key，`interpretation` 任务会返回明确失败（如 `50102 provider not configured`），这是预期保护行为，不再伪造 mock 成功。
   - 如果 `.env` 中已经配置了可用厂商和 API Key，容器模式下的 AI 解读会走真实调用。

6. 停止服务：
   ```bash
   make docker-down
   ```

### 本地开发

1. 安装Go依赖：
   ```bash
   make dev-setup
   ```

2. 启动依赖服务（PostgreSQL和Redis）：
   ```bash
   make docker-up
   ```

3. 运行后端服务：
   ```bash
   make run
   ```

4. 运行测试：
   ```bash
   make test
   ```

## API接口

### 基础信息

- **Base URL**: `http://localhost:8080/v1`
- **内容类型**: `application/json`
- **认证**: JWT Bearer Token (已实现，Access + Refresh)

### 健康检查

```
GET /health
```

响应示例：
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "status": "healthy",
    "timestamp": 1710394800,
    "services": {
      "database": {
        "status": "healthy",
        "error": null
      },
      "redis": {
        "status": "healthy",
        "error": null
      }
    },
    "uptime": "12.345ms"
  },
  "timestamp": 1710394800
}
```

### API分组

- `GET /v1/geo/nearby` - 查询附近POI
- `GET /v1/poems/recommend` - 推荐诗词
- `GET /v1/poems/{id}` - 诗词详情
- `POST /v1/checkins` - 提交打卡
- `GET /v1/checkins/history` - 打卡历史
- `POST /v1/auth/login` - 用户登录
- `POST /v1/auth/sms/send-code` - 发送手机号验证码（开发模式返回调试验证码）
- `POST /v1/auth/sms/login` - 手机号验证码登录/自动注册
- `POST /v1/auth/refresh` - 刷新令牌
- `POST /v1/auth/forgot-password` - 发送重置密码邮件
- `POST /v1/auth/reset-password` - 使用令牌重置密码
- `GET /v1/profile/{id}` - 用户资料
- `POST /v1/ai/jobs` - 创建 AI 任务（interpretation/tts_reading/story_video）
- `GET /v1/ai/jobs/{job_id}` - 查询 AI 任务状态
- `GET /v1/poems/{id}/interpretation/ai` - 读取最新 AI 解读

详细API文档参考：[API契约v1.1](../collab/70_api_contracts/2026-03-16-api-contract-v1.1.md)

## 配置管理

### 配置文件

配置文件使用YAML格式，位置：`config.yaml`

### 环境变量

所有配置都可以通过环境变量覆盖，环境变量前缀为`MISHI_`，例如：

- `MISHI_SERVER_ADDRESS` - 服务器地址
- `MISHI_DATABASE_HOST` - 数据库主机
- `MISHI_REDIS_PASSWORD` - Redis密码
- `MISHI_EMAIL_HOST` - SMTP主机
- `MISHI_EMAIL_PORT` - SMTP端口
- `MISHI_EMAIL_USERNAME` - SMTP用户名
- `MISHI_EMAIL_PASSWORD` - SMTP密码
- `MISHI_EMAIL_FROM_ADDRESS` - 发件邮箱
- `MISHI_EMAIL_FROM_NAME` - 发件人名称
- `MISHI_EMAIL_RESET_URL` - 密码重置页面URL
- `MISHI_AI_PROVIDER` - AI 厂商全局切换（openai/deepseek/seeddance）
- `MISHI_AI_TIMEOUT_SECONDS` - AI 请求超时（秒）
- `MISHI_AI_MAX_RETRIES` - AI 任务重试次数
- `MISHI_AI_OPENAI_*` / `MISHI_AI_DEEPSEEK_*` / `MISHI_AI_SEEDDANCE_*` - 各厂商模型与鉴权配置

参考 `.env.example` 文件创建 `.env` 文件。`docker compose` 会读取当前目录下的 `.env` 做变量替换，并把后端容器运行所需的 AI 环境变量显式传入服务。

## 数据库

### 初始化

项目使用PostgreSQL + PostGIS扩展。数据库初始化脚本位于 `../../sql/init-database-v1.sql`。

Docker Compose 会自动运行初始化脚本，创建以下表：

- `poems` - 诗词表
- `pois` - POI地点表
- `poi_poems` - POI-诗词关联表
- `users` - 用户表
- `checkins` - 打卡记录表（按月分区）
- `video_jobs` - 视频生成任务表
- `ai_jobs` - AI 任务表
- 等共13张表

### 数据模型

详细的数据模型设计参考数据库初始化脚本。

## 开发指南

### 代码规范

1. 使用 `go fmt` 格式化代码
2. 使用 `golangci-lint` 进行代码检查
3. 遵循Go项目最佳实践

### 添加新功能

1. 在 `internal/handler` 添加处理器
2. 在 `internal/service` 实现业务逻辑
3. 在 `internal/database` 添加数据访问层
4. 在 `internal/server/server.go` 注册路由
5. 添加单元测试

### 测试

```bash
# 运行所有测试
make test

# 运行接口级集成测试（需要可访问的 PostgreSQL）
# 可选：先设置 TEST_DATABASE_URL
# export TEST_DATABASE_URL='postgres://mishi:mishi_password@localhost:5432/mishi?sslmode=disable'
make test-integration

# 清理已使用/过期的密码重置令牌
make db-clean-reset-tokens

# 运行测试并生成覆盖率报告
make test-coverage
```

## 部署

### 生产环境构建

```bash
# 构建Docker镜像
docker build -t mishi-backend:latest .

# 运行容器
docker run -d -p 8080:8080 --env-file .env mishi-backend:latest
```

### Kubernetes部署

Kubernetes部署文件位于 `devops/` 目录（待完善）。

## 监控与日志

- 日志：使用Zerolog，支持JSON格式输出
- 指标：Prometheus指标端点（待实现）
- 追踪：OpenTelemetry集成（待实现）

## 故障排除

### 常见问题

1. **数据库连接失败**
   - 检查PostgreSQL容器是否运行：`docker ps | grep postgres`
   - 验证数据库配置：`config.yaml` 或环境变量

2. **Redis连接失败**
   - 检查Redis容器是否运行：`docker ps | grep redis`
   - 验证Redis配置

3. **端口冲突**
   - 修改 `config.yaml` 中的 `server.address`
   - 或修改 `docker-compose.yml` 中的端口映射

### 日志查看

```bash
# 查看后端日志
docker logs mishi-backend -f

# 查看数据库日志
docker logs mishi-postgres -f

# 查看Redis日志
docker logs mishi-redis -f
```

## 贡献指南

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建Pull Request

## 许可证

本项目采用MIT许可证。详见LICENSE文件。
