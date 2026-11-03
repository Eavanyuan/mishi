# AI 成本控制架构方案

**文档版本**: v1.0  
**输出时间**: 2026-03-14 18:14  
**责任人**: Arch Agent  
**依赖方**: Backend Agent (AI Orchestrator Service)  
**前置依赖**: D002 AI 成本控制需求 ✅  
**状态**: 待 Coordinator 评审

---

## 1. 问题定义

### 1.1 需求来源

基于 **D002 AI 成本控制需求文档**:

> AI 场景动画生成单次成本约 ¥2.70,月度预算上限 ¥100,000,需要通过限额、熔断、缓存三层策略控制成本。

**核心挑战**:
- 如何在用户体验与成本之间平衡?
- 如何应对突发流量导致的成本激增?
- 如何提升缓存命中率降低 API 调用?

### 1.2 技术目标

| 目标 | 指标 | 目标值 |
|-----|------|--------|
| 成本控制 | 月度 AI 成本 | < ¥100,000 |
| 用户体验 | 生成成功率 | >= 95% |
| 效率 | 缓存命中率 | >= 60% |
| 性能 | 任务提交响应时间 | < 500ms |

---

## 2. 整体架构

### 2.1 架构图

```
App/Frontend                 AI Orchestrator                 外部服务
     ↓                            ↓                              ↓
用户点击"生成动画"      配额检查 (Redis)                  LLM Prompt 生成
     ↓                            ↓                         (GPT-4 API)
提交任务请求    →     缓存检查 (Redis/CDN)                    ↓
     ↓                            ↓                      视频生成 API
返回 job_id            任务队列 (RabbitMQ)              (Runway/Pika)
     ↓                            ↓                              ↓
轮询任务状态   ←     异步执行 (Celery Worker)    ←    调用外部 API
     ↓                            ↓                              ↓
返回视频 URL           写入缓存 + CDN                      返回视频
```

### 2.2 技术栈

| 组件 | 技术选型 | 用途 |
|-----|---------|------|
| **任务队列** | RabbitMQ / Redis Queue | 异步任务调度 |
| **任务执行器** | Celery (Python) | 分布式任务执行 |
| **配额存储** | Redis | 用户每日配额计数 |
| **缓存** | Redis + CDN (OSS) | 缓存已生成视频 |
| **监控** | Prometheus + Grafana | 成本、成功率监控 |
| **熔断** | 自研熔断器 | 系统级保护 |

---

## 3. 配额控制设计

### 3.1 配额规则

| 用户类型 | 每日限额 | 说明 |
|---------|---------|------|
| 普通用户 | 3 次/天 | MVP 默认 |
| VIP 用户 | 10 次/天 | V2 扩展 |
| 测试用户 | 100 次/天 | 内部测试 |

### 3.2 实现

**Redis 数据结构**:

```redis
# Key: video_quota:{user_id}:{date}
# Value: 已使用次数
# TTL: 86400 秒 (自动过期)

video_quota:12345:2026-03-14 = 2
```

**配额检查逻辑**:

```python
def check_quota(user_id, user_type="normal"):
    """检查用户配额"""
    date = datetime.now().strftime("%Y-%m-%d")
    key = f"video_quota:{user_id}:{date}"
    
    # 获取配额上限
    quota_limit = {
        "normal": 3,
        "vip": 10,
        "test": 100
    }.get(user_type, 3)
    
    # 获取已使用次数
    used_count = int(redis.get(key) or 0)
    
    if used_count >= quota_limit:
        return QuotaResult(
            allowed=False,
            reason=f"今日生成次数已用完 ({used_count}/{quota_limit})",
            remaining=0
        )
    
    return QuotaResult(
        allowed=True,
        remaining=quota_limit - used_count
    )

def consume_quota(user_id):
    """消耗配额"""
    date = datetime.now().strftime("%Y-%m-%d")
    key = f"video_quota:{user_id}:{date}"
    
    redis.incr(key)
    redis.expire(key, 86400)  # 设置过期时间
```

**配额恢复机制** (生成失败):

```python
def refund_quota(user_id):
    """生成失败时退还配额"""
    date = datetime.now().strftime("%Y-%m-%d")
    key = f"video_quota:{user_id}:{date}"
    
    current = int(redis.get(key) or 0)
    if current > 0:
        redis.decr(key)
        logger.info(f"退还配额: user={user_id}, remaining={current-1}")
```

---

## 4. 缓存策略设计

### 4.1 缓存层次

```
用户请求
  ↓
L1: Redis 元数据缓存 (检查是否已生成)  ← 缓存键、视频 URL
  ↓ (未命中)
L2: 对象存储 + CDN (OSS/S3)  ← 视频文件
  ↓ (未命中)
L3: 调用 AI API 生成  ← 新生成
```

### 4.2 缓存键设计

**缓存键规则**:

```python
cache_key = f"video:{poem_id}:{style}:{duration}"

# 示例:
# video:123:watercolor:15  → 诗词 123, 水墨风格, 15 秒
```

**说明**: 相同诗词 + 相同参数 → 复用缓存

### 4.3 实现

#### 4.3.1 Redis 元数据缓存

```python
def check_cache(poem_id, style, duration):
    """检查缓存是否存在"""
    cache_key = f"video:{poem_id}:{style}:{duration}"
    video_url = redis.get(cache_key)
    
    if video_url:
        # 缓存命中
        logger.info(f"缓存命中: {cache_key}")
        return CacheResult(
            hit=True,
            video_url=video_url,
            cache_age_hours=(now() - redis.ttl(cache_key)) / 3600
        )
    
    return CacheResult(hit=False)

def write_cache(poem_id, style, duration, video_url):
    """写入缓存"""
    cache_key = f"video:{poem_id}:{style}:{duration}"
    redis.setex(cache_key, 7 * 86400, video_url)  # 7 天过期
    logger.info(f"写入缓存: {cache_key} → {video_url}")
```

**TTL 设计**: 7 天 (平衡存储成本与命中率)

---

#### 4.3.2 预生成策略

**目标**: 热门诗词提前生成,减少用户等待

**预生成任务**:

```python
def pregenerate_hot_poems():
    """每周预生成 Top 100 热门诗词"""
    # 1. 查询热门诗词
    hot_poems = db.query("""
        SELECT id, title FROM poems
        ORDER BY view_count DESC
        LIMIT 100
    """)
    
    # 2. 提交预生成任务
    for poem in hot_poems:
        # 默认参数: 水墨风格, 15 秒
        cache_key = f"video:{poem.id}:watercolor:15"
        
        # 检查缓存
        if redis.exists(cache_key):
            logger.info(f"跳过已缓存: {cache_key}")
            continue
        
        # 提交任务
        task_id = submit_video_job(
            poem_id=poem.id,
            style="watercolor",
            duration=15,
            priority="low",  # 低优先级,不影响用户请求
            is_pregenerated=True
        )
        logger.info(f"预生成任务已提交: {cache_key}, task_id={task_id}")

# Cron 任务: 每周日凌晨 2:00 执行
schedule.every().sunday.at("02:00").do(pregenerate_hot_poems)
```

**成本评估**:
- 100 首 × ¥2.70/次 = ¥270/周 = ¥1,080/月
- 预期缓存命中率: 60-70%
- 节省成本: 假设每月 10,000 次请求 × 60% × ¥2.70 = ¥16,200

**ROI**: 投入 ¥1,080, 节省 ¥16,200, **净收益 ¥15,120**

---

## 5. 任务队列设计

### 5.1 任务状态机

```
PENDING (待执行)
  ↓
RUNNING (执行中)
  ↓
┌─ SUCCESS (成功)
├─ FAILED (失败)  → RETRY (重试, 最多 2 次)
└─ TIMEOUT (超时)  → RETRY 或 CANCELLED
```

### 5.2 数据库表设计

```sql
CREATE TABLE video_jobs (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    job_id VARCHAR(64) UNIQUE NOT NULL COMMENT '任务 ID (UUID)',
    user_id BIGINT NOT NULL,
    poem_id BIGINT NOT NULL,
    style VARCHAR(50) DEFAULT 'watercolor' COMMENT '风格',
    duration INT DEFAULT 15 COMMENT '时长 (秒)',
    status ENUM('PENDING', 'RUNNING', 'SUCCESS', 'FAILED', 'TIMEOUT', 'CANCELLED') DEFAULT 'PENDING',
    video_url VARCHAR(512) COMMENT '生成的视频 URL',
    error_msg TEXT COMMENT '错误信息',
    retry_count INT DEFAULT 0 COMMENT '重试次数',
    cost DECIMAL(10, 2) COMMENT '成本 (元)',
    queue_time TIMESTAMP COMMENT '入队时间',
    start_time TIMESTAMP COMMENT '开始执行时间',
    finish_time TIMESTAMP COMMENT '完成时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_status (status, created_at),
    INDEX idx_job_id (job_id)
);
```

### 5.3 任务提交流程

```python
def submit_video_job(user_id, poem_id, style, duration):
    """提交视频生成任务"""
    # 1. 检查配额
    quota_result = check_quota(user_id)
    if not quota_result.allowed:
        return JobResult(code=403, msg=quota_result.reason)
    
    # 2. 检查缓存
    cache_result = check_cache(poem_id, style, duration)
    if cache_result.hit:
        # 缓存命中,不消耗配额
        return JobResult(
            code=0,
            job_id=None,
            video_url=cache_result.video_url,
            cache_hit=True
        )
    
    # 3. 消耗配额
    consume_quota(user_id)
    
    # 4. 生成任务 ID
    job_id = str(uuid.uuid4())
    
    # 5. 写入数据库
    db.insert("""
        INSERT INTO video_jobs (job_id, user_id, poem_id, style, duration, status, queue_time)
        VALUES (%s, %s, %s, %s, %s, 'PENDING', NOW())
    """, (job_id, user_id, poem_id, style, duration))
    
    # 6. 推入任务队列
    queue.enqueue(
        "video_generation_worker",
        job_id=job_id,
        poem_id=poem_id,
        style=style,
        duration=duration
    )
    
    return JobResult(
        code=0,
        job_id=job_id,
        msg="任务已提交,预计 2 分钟内完成"
    )
```

---

### 5.4 任务执行器 (Celery Worker)

```python
@celery.task(bind=True, max_retries=2)
def video_generation_worker(self, job_id, poem_id, style, duration):
    """异步执行视频生成"""
    try:
        # 1. 更新状态为 RUNNING
        db.update("""
            UPDATE video_jobs
            SET status = 'RUNNING', start_time = NOW()
            WHERE job_id = %s
        """, (job_id,))
        
        # 2. 调用 LLM 生成 Prompt
        prompt = generate_prompt_via_llm(poem_id, style)
        
        # 3. 调用视频生成 API
        video_url = call_video_generation_api(prompt, duration)
        
        # 4. 上传到对象存储
        final_url = upload_to_oss(video_url, job_id)
        
        # 5. 写入缓存
        cache_key = f"video:{poem_id}:{style}:{duration}"
        redis.setex(cache_key, 7 * 86400, final_url)
        
        # 6. 更新任务状态
        db.update("""
            UPDATE video_jobs
            SET status = 'SUCCESS', video_url = %s, finish_time = NOW(), cost = 2.70
            WHERE job_id = %s
        """, (final_url, job_id))
        
        # 7. 推送通知给用户
        push_notification(job_id, "视频生成成功")
        
        return {"status": "SUCCESS", "video_url": final_url}
    
    except TimeoutError as e:
        # 超时处理
        logger.error(f"任务超时: {job_id}, error={e}")
        db.update("""
            UPDATE video_jobs
            SET status = 'TIMEOUT', error_msg = %s, finish_time = NOW()
            WHERE job_id = %s
        """, (str(e), job_id))
        
        # 重试
        if self.request.retries < self.max_retries:
            raise self.retry(exc=e, countdown=30)  # 30 秒后重试
        else:
            refund_quota(user_id)  # 退还配额
    
    except Exception as e:
        # 其他错误
        logger.error(f"任务失败: {job_id}, error={e}")
        db.update("""
            UPDATE video_jobs
            SET status = 'FAILED', error_msg = %s, finish_time = NOW()
            WHERE job_id = %s
        """, (str(e), job_id))
        
        # 重试
        if self.request.retries < self.max_retries:
            raise self.retry(exc=e, countdown=30)
        else:
            refund_quota(user_id)
```

---

## 6. 熔断机制设计

### 6.1 熔断触发条件

| 级别 | 触发条件 | 熔断动作 |
|-----|---------|---------|
| **L1: 轻度熔断** | 1 分钟内失败率 > 30% | 暂停新任务提交 5 分钟 |
| **L2: 中度熔断** | 队列积压 > 1000 个任务 | 拒绝新任务,提示"系统繁忙" |
| **L3: 重度熔断** | AI API 返回 429 (限流) | 立即暂停 10 分钟 |
| **L4: 成本熔断** | 日度成本 > ¥10,000 | 全面暂停,人工介入 |

### 6.2 实现

#### 6.2.1 失败率熔断

```python
class CircuitBreaker:
    def __init__(self):
        self.failure_count = 0
        self.total_count = 0
        self.last_reset = time.time()
        self.is_open = False
        self.open_until = 0
    
    def record_success(self):
        self.total_count += 1
        self._check_reset()
    
    def record_failure(self):
        self.failure_count += 1
        self.total_count += 1
        self._check_reset()
        self._check_threshold()
    
    def _check_reset(self):
        """每 1 分钟重置统计"""
        if time.time() - self.last_reset > 60:
            self.failure_count = 0
            self.total_count = 0
            self.last_reset = time.time()
    
    def _check_threshold(self):
        """检查是否触发熔断"""
        if self.total_count >= 10:  # 最少 10 次请求
            failure_rate = self.failure_count / self.total_count
            if failure_rate > 0.3:  # 失败率 > 30%
                self.is_open = True
                self.open_until = time.time() + 300  # 熔断 5 分钟
                logger.warning(f"熔断触发: 失败率={failure_rate:.1%}")
    
    def allow_request(self):
        """判断是否允许新请求"""
        if self.is_open:
            if time.time() > self.open_until:
                # 熔断恢复
                self.is_open = False
                logger.info("熔断恢复")
                return True
            return False
        return True

# 全局熔断器
circuit_breaker = CircuitBreaker()
```

**使用**:

```python
def submit_video_job(user_id, poem_id, style, duration):
    # 检查熔断器
    if not circuit_breaker.allow_request():
        return JobResult(code=503, msg="系统繁忙,请稍后再试")
    
    # 执行任务...
```

---

#### 6.2.2 成本熔断

```python
def check_daily_cost_limit():
    """检查日度成本是否超限"""
    date = datetime.now().strftime("%Y-%m-%d")
    key = f"ai_cost:daily:{date}"
    
    daily_cost = float(redis.get(key) or 0)
    
    if daily_cost > 10000:  # ¥10,000
        logger.critical(f"日度成本超限: {daily_cost}, 触发成本熔断")
        # 设置熔断标志
        redis.setex("ai_cost:circuit_breaker", 3600, "1")
        # 发送告警
        alert("成本熔断", f"日度成本已达 ¥{daily_cost}, 已暂停服务")
        return False
    
    return True

def record_cost(job_id, cost):
    """记录成本"""
    date = datetime.now().strftime("%Y-%m-%d")
    key = f"ai_cost:daily:{date}"
    
    redis.incrbyfloat(key, cost)
    redis.expire(key, 86400)
    
    logger.info(f"记录成本: job_id={job_id}, cost=¥{cost}")
```

---

## 7. 监控与告警

### 7.1 监控指标

| 指标 | 告警阈值 |
|-----|---------|
| 日度成本 | > ¥8,000 (黄色) / > ¥10,000 (红色) |
| 月度累计成本 | > ¥80,000 (黄色) / > ¥100,000 (红色) |
| 生成成功率 | < 95% |
| 缓存命中率 | < 60% |
| 队列积压 | > 500 (黄色) / > 1000 (红色) |
| 平均生成时长 | > 2 分钟 |

### 7.2 成本监控面板

**Grafana Dashboard**:

```yaml
- 日度成本曲线图
- 月度累计成本
- 成本占比 (LLM vs 视频生成)
- 缓存命中率
- 生成成功率
- 队列深度
```

### 7.3 日志记录

```json
{
  "job_id": "abc-123",
  "user_id": 12345,
  "poem_id": 456,
  "style": "watercolor",
  "duration": 15,
  "status": "SUCCESS",
  "cache_hit": false,
  "cost": 2.70,
  "queue_time_ms": 500,
  "execute_time_ms": 85000,
  "retry_count": 0,
  "timestamp": "2026-03-14T18:00:00Z"
}
```

---

## 8. 性能优化

### 8.1 性能目标

| 指标 | 目标值 |
|-----|--------|
| 任务提交响应时间 | < 500ms |
| 缓存检查延迟 | < 50ms |
| 队列吞吐量 | >= 100 任务/秒 |

### 8.2 优化策略

#### 8.2.1 异步化

**优化前** (同步):

```python
def submit_video_job(...):
    check_quota()  # 50ms
    check_cache()  # 30ms
    db.insert()  # 20ms
    queue.enqueue()  # 10ms
    # 总计: 110ms
```

**优化后** (异步):

```python
async def submit_video_job(...):
    quota_task = asyncio.create_task(check_quota())
    cache_task = asyncio.create_task(check_cache())
    
    quota_result = await quota_task
    cache_result = await cache_task
    
    # 总计: 50ms (最慢的 check_quota)
```

---

#### 8.2.2 批量操作

**优化前** (逐个插入):

```python
for job in jobs:
    db.insert("INSERT INTO video_jobs ...", job)
    queue.enqueue(job)
# 100 个任务 × 30ms = 3000ms
```

**优化后** (批量):

```python
db.insert_batch("INSERT INTO video_jobs ...", jobs)
queue.enqueue_batch(jobs)
# 100 个任务 → 200ms
```

---

## 9. 交付物清单

- [x] 技术方案文档 (本文档)
- [ ] AI Orchestrator 服务代码
- [ ] 任务队列实现 (Celery + RabbitMQ)
- [ ] 熔断器实现
- [ ] 监控面板配置 (Grafana)
- [ ] 预生成脚本
- [ ] 成本报表工具

---

**文档状态**: ✅ 已交付  
**输出时间**: 2026-03-14 18:14  
**责任人**: Arch Agent  
**审核状态**: 待 Coordinator 评审
