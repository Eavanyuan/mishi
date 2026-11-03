# 打卡闭环实现记录（2026-03-22）

## 已实现
1. Poem 模型补充打卡关联字段
- `relatedPoiId`
- `relatedPoiName`

2. 推荐/详情接口映射增强
- 推荐列表从 `related_poi` 映射 POI
- 详情页从 `related_pois` 提取主 POI

3. 打卡服务重构
- `submitCheckin`：按后端 envelope 解析
- `fetchHistory`：拉取历史与统计
- 新增模型：
  - `CheckinSubmitResult`
  - `CheckinHistoryItem`
  - `CheckinHistoryResponse`

4. 定位服务
- 新增 `LocationService`（`geolocator`）
- 负责定位权限校验与坐标获取

5. UI 闭环
- 首页卡片增加“打卡”按钮
- 详情页增加“在此打卡”按钮
- 个人中心增加“我的打卡记录”入口
- 新增打卡历史页，展示统计与列表

6. 路由
- 新增 `/profile/checkins`

## 验证
- `flutter pub get`
- `build_runner build --delete-conflicting-outputs`
- `flutter analyze` 通过
- `flutter test` 通过

## 后续建议
1. 打卡失败错误码映射为友好文案（40301/40302/40303）
2. 历史页支持分页加载与下拉刷新联动
3. 打卡成功后联动刷新 profile 统计与 history provider
