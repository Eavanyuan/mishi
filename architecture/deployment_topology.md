# 觅诗部署拓扑（Task 3）

## 1. 环境拓扑
- `dev`：单区低成本，开发联调
- `staging`：生产镜像拓扑，灰度验证
- `prod`：多可用区部署，核心服务高可用

## 2. 生产部署建议
### 2.1 接入层
- 全球/区域流量入口（CDN + WAF）
- API Gateway（至少 2 实例）

### 2.2 业务层（K8s）
- content-service（HPA）
- geo-service（HPA）
- recommend-service（HPA）
- checkin-route-service（HPA）
- media-service（HPA）
- ai-orchestrator（独立资源池）
- cms-admin（内网访问）

### 2.3 数据层
- PostgreSQL + PostGIS（主从+备份）
- Redis（哨兵/集群）
- Elasticsearch（3 节点起）
- Object Storage + CDN
- MQ（Kafka/RabbitMQ）

### 2.4 可观测层
- 日志：EFK / Loki
- 指标：Prometheus + Grafana
- 链路：OpenTelemetry + Tempo/Jaeger
- 告警：PagerDuty/企业微信告警机器人

## 3. 高可用策略
- API 与核心服务跨 AZ 部署
- 读写分离与自动故障转移
- 打卡写入幂等 key 防止重放
- 推荐服务降级：失败时回退到规则推荐缓存
- AI 服务降级：排队超时后降级为仅语音推荐

## 4. 性能与容量基线（首发）
- DAU：3-5 万
- 峰值 QPS：300（核心接口）
- 推荐缓存命中率目标：>70%
- 打卡写入成功率：>99.9%

## 5. 发布策略
- 蓝绿或金丝雀发布（5% -> 20% -> 50% -> 100%）
- 每阶段观测：错误率、P95、崩溃率、打卡成功率
- 任一核心指标恶化触发自动回滚
