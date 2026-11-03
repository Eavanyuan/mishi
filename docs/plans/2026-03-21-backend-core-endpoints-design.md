# 后端核心接口落地设计（geo/poems/checkins/auth）

## 目标
在不大改现有目录结构的前提下，将后端占位接口落地为可调用的真实实现，保证 Flutter 与 Web 客户端可联调。

## 范围
- `GET /v1/geo/nearby`
- `GET /v1/poems/recommend`
- `GET /v1/poems/:id`
- `POST /v1/checkins`
- `GET /v1/checkins/history`
- `POST /v1/auth/login`
- `POST /v1/auth/refresh`

## 设计决策
1. 采用 Handler 直连 SQL（`db.Pool.Query/QueryRow/Exec`），避免本轮引入额外 service/repository 重构。
2. 请求参数兼容双命名：
   - 地理参数兼容 `lat/lon` 与 `latitude/longitude`。
3. 统一返回项目既有响应格式：`{code,message,data,timestamp}`。
4. 认证先提供开发可用令牌机制：
   - 登录根据手机号/邮箱查用户。
   - refresh token 使用可解析格式（含 user_id）并做基础校验。
5. 打卡先落地基础风控：
   - 距离校验（默认 100m）。
   - 一小时内同用户同 POI 去重（由唯一索引 + 错误码映射保障）。

## 数据流
- Geo nearby：坐标 -> PostGIS 距离查询 -> POI 列表
- Poem recommend：坐标 -> 邻近 POI 关联诗词 -> 按距离/关联度排序 -> 返回推荐分解分数
- Poem detail：poem 主表 + 关联 POI 聚合 -> 详情对象
- Checkin create：校验参数 -> 查询 POI 距离 -> 插入 checkins
- Checkin history：按 user_id + 分页查询，附带统计
- Auth：用户查找 -> 返回 user_profile + access/refresh token

## 测试策略
- 新增 handler 级测试（参数解析、token 编解码、关键路径成功/失败）。
- 保留现有 health/ping 测试。
- 本轮优先覆盖高风险逻辑：参数校验、token 解析、打卡请求体校验。

## 非目标
- JWT 真签发/验签
- 完整权限中间件
- Redis 缓存与限流
- 全量 SQL 优化
