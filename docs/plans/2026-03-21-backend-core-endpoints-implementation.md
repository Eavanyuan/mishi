# Backend Core Endpoints Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将后端核心占位接口替换为真实数据库实现，并补齐关键测试，支持客户端联调。

**Architecture:** 保持现有 Gin + pgx 架构，采用 handler 直连数据库的轻量实现方式；通过共享的参数解析与 token 工具函数减少重复逻辑。

**Tech Stack:** Go 1.21, Gin, pgx/PostgreSQL(PostGIS), testify

---

### Task 1: 新增失败测试（参数与token）

**Files:**
- Create: `backend/internal/handler/request_helpers_test.go`
- Create: `backend/internal/handler/auth_token_test.go`

1. 添加 `lat/lon` 与 `latitude/longitude` 兼容解析测试。
2. 添加分页参数边界测试（limit/offset）。
3. 添加 refresh token 生成/解析测试（含非法 token 失败场景）。
4. 运行 `go test ./internal/handler -run TestParse -v`，确认先失败。

### Task 2: 实现公共请求解析与token工具

**Files:**
- Create: `backend/internal/handler/request_helpers.go`
- Modify: `backend/internal/handler/auth.go`

1. 实现地理参数解析函数与分页解析函数。
2. 实现 access/refresh token 生成与 refresh token 解析函数。
3. 再次运行上述测试，确保通过。

### Task 3: 落地 geo/poems 接口

**Files:**
- Modify: `backend/internal/handler/geo.go`
- Modify: `backend/internal/handler/poems.go`

1. `geo/nearby` 使用 PostGIS 按半径查询 POI。
2. `poems/recommend` 基于 nearby POI + poi_poems 返回推荐。
3. `poems/:id` 返回诗词详情 + 关联 POI + 媒体/统计字段。
4. 新增最小回归测试（参数错误时返回 40001）。

### Task 4: 落地 checkins/auth 接口

**Files:**
- Modify: `backend/internal/handler/checkins.go`
- Modify: `backend/internal/handler/auth.go`

1. `checkins` 创建：参数校验、距离校验、插入记录、唯一约束冲突映射。
2. `checkins/history`：分页查询 + 统计信息。
3. `auth/login`：根据 phone/email 查用户并返回 profile + token。
4. `auth/refresh`：校验 refresh token 并返回新 token。

### Task 5: 验证

**Files:**
- Modify: `backend/internal/handler/health_test.go`（仅当编译/接口签名需要）

1. 运行 `go test ./...`。
2. 如有失败，修复后再次运行直至全绿。
3. 总结变更点与后续建议（JWT、鉴权中间件、限流）。
