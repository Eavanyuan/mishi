# 打卡防作弊技术方案

**文档版本**: v1.0  
**输出时间**: 2026-03-14 18:13  
**责任人**: Arch Agent  
**依赖方**: Backend Agent (Checkin Service), App Agent  
**前置依赖**: D003 打卡防作弊需求 ✅  
**状态**: 待 Coordinator 评审

---

## 1. 问题定义

### 1.1 需求来源

基于 **D003 打卡防作弊需求文档**:

> 系统需要识别和拦截虚假打卡行为,保证打卡榜单的公平性,目标拦截率 >= 90%,误杀率 < 5%。

**核心作弊手段**:
- 🔴 虚拟定位工具 (Mock Location)
- 🔴 瞬移打卡 (快速切换位置)
- 🔴 批量注册刷榜
- 🔴 设备指纹伪造

### 1.2 技术目标

| 目标 | 指标 | 目标值 |
|-----|------|--------|
| 拦截效果 | 作弊拦截率 | >= 90% |
| 用户体验 | 误杀率 | < 5% |
| 性能 | 风控判定延迟 | < 100ms |
| 可维护性 | 规则迭代周期 | < 1 天 |

---

## 2. 整体架构

### 2.1 架构图

```
App 端                      后端服务
  ↓                           ↓
设备指纹采集            风控引擎 (Rule Engine)
  ↓                           ↓
GPS 数据收集     →     规则链执行 (L1→L2→L3)
  ↓                           ↓
打卡请求         →     风险评分计算
                              ↓
                    [< 60: 通过] [60-99: 审核] [>= 100: 拒绝]
                              ↓
                        Redis 缓存 / 数据库持久化
                              ↓
                        人工审核队列 (可选)
```

### 2.2 技术栈

| 组件 | 技术选型 | 用途 |
|-----|---------|------|
| **规则引擎** | Drools / 自研 | 动态规则配置与执行 |
| **风险存储** | Redis + PostgreSQL | 用户行为历史、风险评分 |
| **设备指纹** | DeviceId + 多维特征 | 设备唯一性识别 |
| **地理计算** | PostGIS + Haversine | 距离、速度计算 |
| **监控告警** | Prometheus + Grafana | 实时监控拦截率、误杀率 |

---

## 3. 防作弊规则设计

### 3.1 规则分层架构

```
L1: 基础规则 (硬性阈值)  →  50-60% 拦截
  ↓ (通过)
L2: 行为规则 (统计分析)  →  30-35% 拦截
  ↓ (通过)
L3: 设备指纹 (特征识别)  →  5-10% 拦截
  ↓ (通过)
L4: 人工审核 (边缘 case)  →  1-5% 最终确认
```

---

### 3.2 L1: 基础规则 (强制规则)

#### 规则 1.0: 黑名单检查 (新增 ✨)

**实现**: Redis 集合存储黑名单

```python
def rule_blacklist_check(user_id):
    """黑名单用户直接拒绝"""
    if redis.sismember("user_blacklist", user_id):
        return RuleResult(
            pass_rule=False,
            reason="黑名单用户",
            risk_score=100,
            detail=f"user_id={user_id} in blacklist"
        )
    return RuleResult(pass_rule=True, risk_score=0)
```

**Redis 数据结构**:

```redis
user_blacklist = {12345, 67890, ...}  # Set 类型
```

**黑名单管理**:

```python
# 添加黑名单
redis.sadd("user_blacklist", user_id)

# 移除黑名单
redis.srem("user_blacklist", user_id)

# 检查是否在黑名单
redis.sismember("user_blacklist", user_id)
```

**性能**: < 1ms (内存查询)

**优先级**: 最高 (放在所有规则之前,快速拦截)

---

#### 规则 1.1: 距离检查

**实现**: 后端服务

```python
def rule_distance_check(user_lat, user_lon, poi):
    """距离必须 <= 100 米"""
    distance = calculate_distance(user_lat, user_lon, poi.lat, poi.lon)
    if distance > 100:
        return RuleResult(
            pass_rule=False,
            reason="距离过远",
            risk_score=100,  # 直接拒绝
            detail=f"distance={distance}m, threshold=100m"
        )
    return RuleResult(pass_rule=True, risk_score=0)
```

**SQL 实现** (PostGIS):

```sql
SELECT ST_Distance(
    ST_SetSRID(ST_Point(:user_lon, :user_lat), 4326)::geography,
    ST_SetSRID(ST_Point(:poi_lon, :poi_lat), 4326)::geography
) AS distance;
```

**性能**: < 10ms

---

#### 规则 1.2: 定位精度检查

**实现**: App 端上报 + 后端校验

```python
def rule_accuracy_check(gps_accuracy):
    """GPS 精度必须 < 50 米"""
    if gps_accuracy > 50:
        return RuleResult(
            pass_rule=False,
            reason="定位精度不足",
            risk_score=100,
            detail=f"accuracy={gps_accuracy}m, threshold=50m"
        )
    return RuleResult(pass_rule=True, risk_score=0)
```

**App 端数据采集**:

```kotlin
// Android 示例
val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
val location = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
val accuracy = location.accuracy  // 单位: 米
```

---

#### 规则 1.3: 重复打卡检查

**实现**: Redis 缓存

```python
def rule_duplicate_check(user_id, poi_id):
    """同地点 1 小时内不可重复打卡"""
    key = f"checkin_cooldown:{user_id}:{poi_id}"
    last_time = redis.get(key)
    
    if last_time:
        cooldown_remaining = 3600 - (now() - int(last_time))
        return RuleResult(
            pass_rule=False,
            reason="重复打卡",
            risk_score=100,
            detail=f"cooldown_remaining={cooldown_remaining}s"
        )
    
    # 通过后设置冷却
    redis.setex(key, 3600, str(now()))
    return RuleResult(pass_rule=True, risk_score=0)
```

**Redis 数据结构**:

```redis
checkin_cooldown:12345:poi123 = 1710394800
TTL: 3600 秒
```

---

### 3.3 L2: 行为规则 (统计规则)

#### 规则 2.1: 速度异常检查

**实现**: Redis 存储历史位置

```python
def rule_speed_check(user_id, current_lat, current_lon, current_time):
    """检测瞬移: 两次打卡间隔 < 5 分钟且距离 > 500 米"""
    key = f"user_last_checkin:{user_id}"
    last_checkin = redis.hgetall(key)
    
    if not last_checkin:
        # 首次打卡,记录位置
        redis.hmset(key, {
            "lat": current_lat,
            "lon": current_lon,
            "time": current_time
        })
        redis.expire(key, 86400)  # 24 小时过期
        return RuleResult(pass_rule=True, risk_score=0)
    
    # 计算距离和时间间隔
    last_lat = float(last_checkin["lat"])
    last_lon = float(last_checkin["lon"])
    last_time = int(last_checkin["time"])
    
    distance = calculate_distance(current_lat, current_lon, last_lat, last_lon)
    time_gap = current_time - last_time
    
    # 判定: 5 分钟内移动 > 500 米 (速度 > 6 km/h)
    if time_gap < 300 and distance > 500:
        speed = distance / time_gap * 3.6  # 转换为 km/h
        return RuleResult(
            pass_rule=True,  # 不直接拒绝,加风险分
            reason="速度异常",
            risk_score=50,
            detail=f"speed={speed:.1f}km/h, distance={distance}m, time_gap={time_gap}s"
        )
    
    # 更新位置
    redis.hmset(key, {
        "lat": current_lat,
        "lon": current_lon,
        "time": current_time
    })
    
    return RuleResult(pass_rule=True, risk_score=0)
```

**风险评分**: +50 (不直接拒绝,累积评分)

---

#### 规则 2.2: 单日打卡次数检查

**实现**: Redis 计数

```python
def rule_daily_count_check(user_id):
    """单日打卡 > 20 次标记异常"""
    date = datetime.now().strftime("%Y-%m-%d")
    key = f"checkin_daily_count:{user_id}:{date}"
    
    count = redis.incr(key)
    redis.expire(key, 86400)  # 当天结束过期
    
    if count > 20:
        return RuleResult(
            pass_rule=True,
            reason="单日打卡次数异常",
            risk_score=30,
            detail=f"daily_count={count}, threshold=20"
        )
    
    return RuleResult(pass_rule=True, risk_score=0)
```

**风险评分**: +30

---

#### 规则 2.3: 深夜打卡异常

**实现**: 时间 + 精度联合判断

```python
def rule_night_checkin_check(current_hour, gps_accuracy):
    """深夜 (23:00-06:00) + 精度差 (> 30m) = 疑似室内虚拟定位"""
    if (current_hour >= 23 or current_hour < 6) and gps_accuracy > 30:
        return RuleResult(
            pass_rule=True,
            reason="深夜打卡异常",
            risk_score=20,
            detail=f"hour={current_hour}, accuracy={gps_accuracy}m"
        )
    
    return RuleResult(pass_rule=True, risk_score=0)
```

**风险评分**: +20

---

### 3.4 L3: 设备指纹 (设备规则)

#### 规则 3.1: 模拟器检测

**实现**: App 端检测 + 后端校验

**Android 检测**:

```kotlin
fun isEmulator(): Boolean {
    val suspicious = listOf(
        Build.FINGERPRINT.contains("generic"),
        Build.MODEL.contains("google_sdk"),
        Build.MODEL.contains("Emulator"),
        Build.MANUFACTURER.contains("Genymotion"),
        Build.PRODUCT.contains("sdk"),
        !hasSensors()  // 检查是否有加速度计/陀螺仪
    )
    return suspicious.count { it } >= 2  // 2 个以上特征命中
}

fun hasSensors(): Boolean {
    val sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
    val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    val gyroscope = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE)
    return accelerometer != null && gyroscope != null
}
```

**iOS 检测**:

```swift
func isSimulator() -> Bool {
    #if targetEnvironment(simulator)
        return true
    #else
        return false
    #endif
}
```

**后端校验**:

```python
def rule_emulator_check(device_info):
    """检测模拟器"""
    if device_info.get("is_emulator"):
        return RuleResult(
            pass_rule=False,
            reason="检测到模拟器",
            risk_score=100,
            detail=f"device_model={device_info['model']}"
        )
    return RuleResult(pass_rule=True, risk_score=0)
```

---

#### 规则 3.2: Root/越狱设备检测

**实现**: App 端检测

**Android Root 检测**:

```kotlin
fun isRooted(): Boolean {
    // 方法 1: 检查 su 文件
    val suPaths = listOf(
        "/system/bin/su",
        "/system/xbin/su",
        "/sbin/su"
    )
    if (suPaths.any { File(it).exists() }) return true
    
    // 方法 2: 检查 Magisk/SuperSU
    val rootApps = listOf(
        "com.topjohnwu.magisk",
        "eu.chainfire.supersu"
    )
    val pm = packageManager
    return rootApps.any {
        try {
            pm.getPackageInfo(it, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}
```

**iOS 越狱检测**:

```swift
func isJailbroken() -> Bool {
    // 方法 1: 检查 Cydia
    if FileManager.default.fileExists(atPath: "/Applications/Cydia.app") {
        return true
    }
    
    // 方法 2: 检查系统文件可写性
    let testPath = "/private/test.txt"
    do {
        try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
        try FileManager.default.removeItem(atPath: testPath)
        return true  // 成功写入 = 越狱
    } catch {
        return false
    }
}
```

**后端策略**:

```python
def rule_rooted_device_check(device_info, risk_score):
    """Root/越狱设备 + 高风险 = 拒绝"""
    if device_info.get("is_rooted") and risk_score >= 60:
        return RuleResult(
            pass_rule=False,
            reason="Root/越狱设备 + 高风险",
            risk_score=40,
            detail=f"is_rooted=True, cumulative_score={risk_score}"
        )
    
    # 低风险时仅记录,不拦截
    if device_info.get("is_rooted"):
        return RuleResult(pass_rule=True, risk_score=10, reason="Root/越狱设备(观察)")
    
    return RuleResult(pass_rule=True, risk_score=0)
```

**风险评分**: +10 (观察) 或 +40 (高风险时)

---

#### 规则 3.3: 设备唯一性检查

**实现**: Redis 记录设备-账号关联

```python
def rule_device_multi_account_check(device_id, user_id):
    """单设备单日不同账号打卡 > 5 次"""
    date = datetime.now().strftime("%Y-%m-%d")
    key = f"device_accounts:{device_id}:{date}"
    
    # 记录该设备今日使用的账号
    redis.sadd(key, user_id)
    redis.expire(key, 86400)
    
    account_count = redis.scard(key)
    
    if account_count > 5:
        return RuleResult(
            pass_rule=True,
            reason="设备多账号异常",
            risk_score=40,
            detail=f"device_id={device_id}, account_count={account_count}"
        )
    
    return RuleResult(pass_rule=True, risk_score=0)
```

**风险评分**: +40

---

### 3.5 风险评分模型

#### 评分规则

```python
total_risk_score = sum([
    rule_1_score,
    rule_2_score,
    rule_3_score,
    ...
])

if total_risk_score >= 100:
    action = "REJECT"  # 拒绝打卡
elif total_risk_score >= 60:
    action = "REVIEW"  # 打卡成功,推送人工审核
else:
    action = "PASS"  # 正常通过
```

#### 评分权重表

| 规则 | 触发评分 | 决策 |
|-----|---------|------|
| 黑名单用户 | 100 | 直接拒绝 🆕 |
| 距离过远 | 100 | 直接拒绝 |
| 精度不足 | 100 | 直接拒绝 |
| 重复打卡 | 100 | 直接拒绝 |
| 模拟器 | 100 | 直接拒绝 |
| 速度异常 | +50 | 累积评分 |
| 设备多账号 | +40 | 累积评分 |
| Root 设备 (高风险) | +40 | 累积评分 |
| 单日次数异常 | +30 | 累积评分 |
| 深夜打卡 | +20 | 累积评分 |
| Root 设备 (观察) | +10 | 累积评分 |

---

## 4. 幂等性设计

### 4.1 幂等键设计

**目标**: 防止网络抖动导致重复打卡记录

**幂等键规则**:

```python
time_bucket = int(timestamp / 3600)  # 按小时分桶
idempotent_key = f"checkin_idempotent:{user_id}:{poi_id}:{time_bucket}"
```

**流程**:

```python
def checkin_with_idempotency(user_id, poi_id, lat, lon):
    # 1. 生成幂等键
    time_bucket = int(time.time() / 3600)
    idempotent_key = f"checkin_idempotent:{user_id}:{poi_id}:{time_bucket}"
    
    # 2. 检查幂等键
    if redis.exists(idempotent_key):
        return {"code": 400, "msg": "重复请求,已拦截"}
    
    # 3. 设置幂等键 (先设置,再执行业务)
    redis.setex(idempotent_key, 3600, "1")
    
    # 4. 执行风控检查
    risk_result = risk_engine.execute(user_id, poi_id, lat, lon)
    
    if risk_result.action == "REJECT":
        # 拒绝时删除幂等键,允许重试
        redis.delete(idempotent_key)
        return {"code": 403, "msg": risk_result.reason}
    
    # 5. 写入打卡记录
    checkin_id = db.insert_checkin(user_id, poi_id, lat, lon)
    
    return {"code": 0, "data": {"checkin_id": checkin_id}}
```

**关键点**:
- 幂等键在业务开始前设置 (防止并发)
- 拒绝时删除幂等键 (允许用户改善条件后重试)
- 成功后保留幂等键 1 小时 (防止重复提交)

---

## 5. 降级策略

### 5.1 降级级别

| 级别 | 触发条件 | 降级措施 |
|-----|---------|---------|
| **L1: 轻度降级** | 风控延迟 > 200ms | 跳过 L3 设备指纹检查 |
| **L2: 中度降级** | 风控延迟 > 500ms | 仅保留 L1 基础规则 |
| **L3: 重度降级** | 风控服务不可用 | 全部放行,标记"降级通过"供事后审计 |

### 5.2 实现

```python
def execute_risk_check_with_downgrade(user_id, poi_id, lat, lon):
    start_time = time.time()
    
    try:
        # L1: 基础规则 (必须执行)
        l1_result = execute_l1_rules(user_id, poi_id, lat, lon)
        if l1_result.risk_score >= 100:
            return l1_result
        
        # 检查延迟
        if time.time() - start_time > 0.5:
            # L2: 中度降级,跳过 L2/L3
            logger.warning("风控中度降级: 仅执行 L1 规则")
            return l1_result
        
        # L2: 行为规则
        l2_result = execute_l2_rules(user_id, poi_id, lat, lon)
        total_score = l1_result.risk_score + l2_result.risk_score
        
        if time.time() - start_time > 0.2:
            # L1: 轻度降级,跳过 L3
            logger.warning("风控轻度降级: 跳过设备指纹检查")
            return RuleResult(risk_score=total_score)
        
        # L3: 设备指纹
        l3_result = execute_l3_rules(user_id, device_info)
        total_score += l3_result.risk_score
        
        return RuleResult(risk_score=total_score)
    
    except Exception as e:
        # L3: 重度降级,全部放行
        logger.error(f"风控服务异常,全部放行: {e}")
        return RuleResult(
            risk_score=0,
            action="PASS",
            detail="降级通过,待事后审计"
        )
```

---

## 6. 人工审核机制

### 6.1 审核队列设计

**自动推送条件**:
- 风险评分 60-99 (疑似作弊)
- 用户申诉
- 单日打卡 > 20 次
- 连续 3 天触发速度异常

**数据结构**:

```sql
CREATE TABLE risk_review_queue (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    checkin_id BIGINT,
    poi_id BIGINT,
    risk_score INT NOT NULL,
    risk_reasons JSON COMMENT '触发的规则详情',
    priority ENUM('P0', 'P1', 'P2', 'P3') DEFAULT 'P2',
    status ENUM('PENDING', 'APPROVED', 'REJECTED') DEFAULT 'PENDING',
    reviewer_id BIGINT,
    review_time TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_status_priority (status, priority, created_at)
);
```

### 6.2 审核优先级

| 优先级 | 定义 | SLA |
|-------|------|-----|
| **P0: 紧急** | 单日打卡 > 50 次 | < 2 小时 |
| **P1: 高** | 风险评分 >= 80 | < 24 小时 |
| **P2: 中** | 风险评分 60-79 | < 72 小时 |
| **P3: 低** | 用户申诉 | < 7 天 |

### 6.3 审核工具需求

**CMS 后台功能**:
- 审核队列看板 (待审核数量、优先级分布)
- 用户打卡轨迹地图可视化
- 风险规则命中详情展示
- 一键封禁/解封
- 批量处理 (批量通过疑似误杀)

---

## 7. 性能优化

### 7.1 性能目标

| 指标 | 目标值 |
|-----|--------|
| 风控判定延迟 (P95) | < 100ms |
| 风控判定延迟 (P99) | < 200ms |
| 风控服务 QPS | >= 1000 |

### 7.2 优化策略

#### 7.2.1 规则并行执行

**优化前** (串行):

```python
l1_result = execute_l1_rules()  # 30ms
l2_result = execute_l2_rules()  # 40ms
l3_result = execute_l3_rules()  # 30ms
# 总计: 100ms
```

**优化后** (并行):

```python
import concurrent.futures

with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
    future_l1 = executor.submit(execute_l1_rules)
    future_l2 = executor.submit(execute_l2_rules)
    future_l3 = executor.submit(execute_l3_rules)
    
    l1_result = future_l1.result()
    l2_result = future_l2.result()
    l3_result = future_l3.result()

# 总计: 40ms (最慢的 L2)
```

**性能提升**: 60%

---

#### 7.2.2 Redis Pipeline

**优化前** (多次 RTT):

```python
last_checkin = redis.hgetall(f"user_last_checkin:{user_id}")  # 5ms
daily_count = redis.get(f"checkin_daily_count:{user_id}:{date}")  # 5ms
cooldown = redis.exists(f"checkin_cooldown:{user_id}:{poi_id}")  # 5ms
# 总计: 15ms
```

**优化后** (Pipeline):

```python
pipe = redis.pipeline()
pipe.hgetall(f"user_last_checkin:{user_id}")
pipe.get(f"checkin_daily_count:{user_id}:{date}")
pipe.exists(f"checkin_cooldown:{user_id}:{poi_id}")
results = pipe.execute()  # 一次 RTT
# 总计: 5ms
```

**性能提升**: 66%

---

#### 7.2.3 热数据缓存

**本地缓存黑名单用户**:

```python
class RiskEngine:
    def __init__(self):
        self.blacklist = set()  # 本地缓存
        self.load_blacklist()
    
    def load_blacklist(self):
        """每 5 分钟从 Redis 同步黑名单"""
        self.blacklist = redis.smembers("user_blacklist")
    
    def is_blacklisted(self, user_id):
        return user_id in self.blacklist
```

**性能提升**: 黑名单用户判定 < 1ms

---

## 8. 监控与告警

### 8.1 监控指标

| 指标 | 告警阈值 |
|-----|---------|
| 风控延迟 (P95) | > 100ms |
| 风控错误率 | > 1% |
| 拦截率 | < 50% (规则失效?) 或 > 95% (过严?) |
| 误杀申诉率 | > 10% |
| 人工审核积压 | > 1000 条 |

### 8.2 日志记录

```json
{
  "user_id": 12345,
  "poi_id": 456,
  "lat": 39.9186,
  "lon": 116.4074,
  "gps_accuracy": 20,
  "device_id": "abc123",
  "is_emulator": false,
  "is_rooted": false,
  "risk_rules_triggered": [
    {"rule": "speed_check", "score": 50, "detail": "speed=15km/h"},
    {"rule": "night_checkin", "score": 20, "detail": "hour=2"}
  ],
  "total_risk_score": 70,
  "action": "REVIEW",
  "latency_ms": 85,
  "timestamp": "2026-03-14T18:00:00Z"
}
```

---

## 9. ABtest 方案

### 9.1 实验设计

**对照组**: 仅 L1 基础规则  
**实验组**: L1 + L2 + L3 完整规则链

**流量分配**: 50% vs 50%  
**实验周期**: 2 周

### 9.2 评估指标

| 指标 | 目标 |
|-----|------|
| 拦截率 | >= 90% |
| 误杀率 | < 5% |
| 用户投诉率 | 无显著上升 |
| 打卡转化率 | 无显著下降 |

---

## 10. 交付物清单

- [x] 技术方案文档 (本文档)
- [ ] 风控引擎代码实现
- [ ] App 端设备指纹采集 SDK
- [ ] CMS 人工审核工作台
- [ ] 性能测试报告
- [ ] 监控面板配置

---

**文档状态**: ✅ 已交付  
**输出时间**: 2026-03-14 18:13  
**责任人**: Arch Agent  
**审核状态**: 待 Coordinator 评审
