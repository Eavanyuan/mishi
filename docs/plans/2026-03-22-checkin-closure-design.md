# 打卡闭环需求细化与前后端架构设计（Home + Detail + History）

## 目标
在现有认证与诗词能力基础上，完成可用的“打卡闭环”：
- 首页卡片可打卡
- 详情页可打卡
- 个人中心可查看打卡历史

## 需求细化
1. 用户在首页或详情页点击“打卡”后，系统尝试获取当前定位并提交打卡。
2. 打卡成功后展示即时反馈（地点名、成功提示）。
3. 打卡失败要可解释（如无权限、距离过远、重复打卡、未登录）。
4. 用户可在个人中心进入“我的打卡记录”查看历史和统计。

## 前端架构
### 分层
- `core/location`：定位服务（权限与坐标获取）
- `services/api/checkin_service.dart`：打卡接口与历史接口适配
- `providers/checkin_provider.dart`：历史数据状态
- `features/home` + `features/poem_detail`：打卡入口
- `features/profile/checkin_history_page.dart`：历史页面

### 关键数据流
1. 用户点击打卡
2. `LocationService.getCurrentPosition`
3. `CheckinService.submitCheckin`
4. Snackbar 反馈 +（可选）刷新历史 Provider

## 后端架构（沿用现状）
- 路由：`/v1/checkins/`, `/v1/checkins/history`
- 鉴权：JWT middleware 注入 `auth_user_id`
- 风控：定位精度、距离阈值、重复打卡（唯一约束）
- 响应：统一 envelope `{code,message,data,timestamp}`

## 非目标
- 打卡卡片图像生成
- 轨迹回放与地图历史可视化
- 离线打卡补偿
