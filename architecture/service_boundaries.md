# 觅诗服务边界定义（Task 3）

## 1. API Gateway
职责：统一入口、鉴权、限流、路由、灰度开关。
不负责：业务规则与持久化。

## 2. Content Service
职责：
- 诗词、诗人、朝代、背景故事、人物关系、权威解读管理
- 多版本解读（教材/学术/通俗）返回
- 内容来源、版本、发布时间管理

数据：poems, poets, dynasties, interpretations, stories, references

## 3. Geo Service
职责：
- 用户位置附近点位查询
- 围栏命中判定
- 古今地名映射与置信度计算
- 地点季节标签与节气映射

数据：poi, geofence, historical_name_mapping, place_season_profile

## 4. Recommend Service
职责：
- 推荐召回与排序
- 排序因子：距离、热度、时段、季节匹配、用户偏好
- 推荐解释字段返回（为什么推荐）

数据：recommend_rules, feature_weights, ranking_logs

## 5. Checkin & Route Service
职责：
- 到地打卡写入与幂等校验
- 打卡卡片生成元数据
- 旅行路线编排（半日/一日）
- 路线进度统计与成就计算

数据：checkin_records, route_templates, route_progress, badges

## 6. Media Service
职责：
- 语音与视频资源 URL 下发
- CDN 签名、缓存策略、转码回调
- 播放与下载行为统计

数据：media_assets, playback_events, transcoding_jobs

## 7. AI Orchestrator
职责：
- 统一编排 LLM/TTS/视频生成任务
- Prompt 模板治理与安全策略
- 成本控制（限额、熔断、重试）

数据：ai_jobs, ai_policies, ai_usage_quota

## 8. CMS Admin
职责：
- 内容录入、双审发布
- 来源合规校验
- 运营配置（季节推荐权重、路线模板）

## 9. 边界协作约定
- 跨服务通信优先 HTTP/gRPC + 事件总线（异步）
- 所有服务输出 trace_id 供链路追踪
- 对外响应统一错误码模型：`code` / `message` / `trace_id`
