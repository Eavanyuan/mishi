# 觅诗 Mishi

觅诗是一款把古典诗词与地理位置结合的应用。用户可以发现附近的诗词与地点、阅读诗词详情、完成地点打卡，并通过 AI 服务生成诗词解读。仓库包含 Go 后端、React Web 前端和 Flutter 客户端。

## 功能概览

- 按位置查找附近地点并推荐相关诗词。
- 查看诗词正文、作者、朝代和现代解读。
- 注册/登录、令牌刷新、个人资料和打卡记录。
- 按城市和主题初始化诗词与地点数据，当前种子数据包含扬州相关诗词。
- 通过统一接口配置 OpenAI、DeepSeek 或 SeedDance 兼容服务。
- 创建并查询 AI 任务，失败时按配置重试。

## 系统结构

```mermaid
flowchart LR
  Web[React Web] --> API[Go REST API]
  App[Flutter App] --> API
  API --> DB[(PostgreSQL + PostGIS)]
  API --> Redis[(Redis)]
  API --> LLM[OpenAI-compatible LLM]
```

| 模块 | 目录 | 主要技术 |
| --- | --- | --- |
| 后端 API | `backend/` | Go 1.21、Gin、PostgreSQL、Redis |
| Web 前端 | `frontend/` | React、TypeScript、Vite、TanStack Query |
| 移动端 | `mishi_app/` | Flutter、Riverpod、Dio |
| 数据库初始化与种子 | `sql/` | PostgreSQL、PostGIS |
| 架构与协作文档 | `architecture/`、`collab/`、`docs/` | API 契约、设计决策和实施记录 |

## 环境要求

- Go 1.21 或更高版本。
- PostgreSQL 15、PostGIS 3.3、`pg_cron` 扩展，以及 Redis 7。
- Node.js 与 npm（需满足仓库当前 Vite 版本要求）。
- Flutter SDK 满足 [`mishi_app/pubspec.yaml`](mishi_app/pubspec.yaml) 中声明的 SDK 约束。
- 可选：Docker Compose、`psql`、Android Studio 或 Xcode。

## 启动后端

### 1. 准备数据库和 Redis

启动一个带 PostGIS 和 `pg_cron` 扩展的 PostgreSQL 15 实例，以及 Redis 7。也可以使用 `backend/docker-compose.yml` 中的 Compose 服务，但需确认所用 PostgreSQL 镜像已安装并启用 `pg_cron`。

数据库基线脚本会执行 `CREATE EXTENSION pg_cron`。如果数据库镜像缺少该扩展，初始化会失败；这时需换用带扩展的镜像或先准备兼容的 PostgreSQL 实例。

### 2. 配置环境变量

```bash
cd backend
cp .env.example .env
```

编辑 `backend/.env`，至少设置数据库和 Redis 的连接信息。使用本机运行后端时，数据库和 Redis 主机通常为 `localhost`；在 Compose 网络内运行后端时，主机名使用 `postgres` 和 `redis`。

如需真实 AI 诗词解读，选择一个兼容厂商并填写对应 API Key：

```dotenv
MISHI_AI_PROVIDER=deepseek
MISHI_AI_DEEPSEEK_API_KEY=替换为你的密钥
```

也可以设置 `MISHI_AI_PROVIDER=openai` 与 `MISHI_AI_OPENAI_API_KEY`，或使用 `seeddance` 与 `MISHI_AI_SEEDDANCE_API_KEY`/`MISHI_AI_SEEDDANCE_BASE_URL`。API Key 只放在本地 `.env` 或部署环境变量中，不要提交到 Git。

### 3. 初始化数据库并启动

```bash
# 在 backend 目录下执行。连接串按本机数据库配置修改。
export DATABASE_URL='postgres://mishi:你的数据库密码@localhost:5432/mishi?sslmode=disable'
make db-init
make db-seed
make run
```

健康检查地址：<http://localhost:8080/health>

后端更多命令见 [`backend/README.md`](backend/README.md) 和 [`backend/Makefile`](backend/Makefile)。

## 启动 Web 前端

```bash
cd frontend
npm ci
```

开发时默认访问 `http://localhost:8080/v1`。如果后端地址不同，可在启动前设置：

```bash
VITE_API_BASE_URL=http://localhost:8080/v1 npm run dev
```

然后打开 <http://localhost:5173>。生产构建和代码检查命令：

```bash
npm run build
npm run lint
```

## 启动 Flutter 客户端

```bash
cd mishi_app
flutter pub get
flutter run --dart-define=MISHI_API_BASE_URL=http://127.0.0.1:8080/v1
```

Android 模拟器访问宿主机时通常需要使用 `http://10.0.2.2:8080/v1`；实体设备请使用电脑在局域网中的 IP 地址。API 地址通过 `MISHI_API_BASE_URL` 编译参数配置。

## AI 能力现状

- 当前 OpenAI、DeepSeek 和 SeedDance 适配器都通过兼容 Chat Completions 的接口生成诗词解读。
- 当前三个适配器都没有接通 TTS 或视频生成 API；相应 AI 任务会标记为不支持，不会返回伪造的成功结果。
- AI 任务写入 PostgreSQL 后由当前后端进程异步执行，并依据 `MISHI_AI_MAX_RETRIES` 重试。现在还没有独立 worker/Redis 持久队列；后端进程退出时，正在运行的任务可能中断。
- `story_video` 任务会构建可供外部视频模型使用的提示词，但尚未完成视频厂商的真实生成和素材存储链路。

## 数据和 API 文档

- 数据库基线：[`sql/init-database-v1.sql`](sql/init-database-v1.sql)
- 示例诗词种子：[`sql/seeds/`](sql/seeds/)
- API 契约：[`collab/70_api_contracts/2026-03-16-api-contract-v1.1.md`](collab/70_api_contracts/2026-03-16-api-contract-v1.1.md)
- 后端接口和本地开发说明：[`backend/README.md`](backend/README.md)
- Web 前端说明：[`frontend/README.md`](frontend/README.md)
- Flutter 客户端说明：[`mishi_app/README.md`](mishi_app/README.md)

## 测试

在各模块目录运行对应命令：

```bash
# Go 后端
cd backend && go test ./...

# Web 前端
cd frontend && npm run build && npm run lint

# Flutter 客户端
cd mishi_app && flutter test
```

集成测试需要可访问的 PostgreSQL/Redis；AI 相关测试或手工验证需要配置有效的厂商 API Key。
