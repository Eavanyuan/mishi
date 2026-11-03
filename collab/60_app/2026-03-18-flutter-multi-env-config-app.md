# Flutter 多环境配置设计 - MISHI-015 执行记录

**Owner**: App Agent D019  
**Task ID**: MISHI-015  
**Title**: Flutter 多环境配置设计  
**Priority**: P2  
**Created**: 2026-03-18 10:34  

---

## 📋 任务背景

| 项目 | 值 |
|------|-|--|
| Task ID | MISHI-015 |
| 依赖任务 | 无（独立任务） |
| Due Date | 2026-03-18 16:00 |
| Current State | todo → 执行中 |
| Blocker | 无 |

---

## 🎯 设计目标

实现 Flutter 应用的多环境配置管理，支持：
1. **开发环境** (`dev`): 本地调试、Mock API
2. **测试环境** (`staging`): 预发布集成测试
3. **生产环境** (`prod`): 正式线上服务

---

## 🏗️ 架构设计

### 1. 环境枚举定义

```dart
// lib/config/environment.dart
enum Environment {
  development,   // dev
  staging,       // staging  
  production     // prod
}

extension on Environment {
  String get label => 
    'dev' == this ? 'development' : 
    'staging' == this ? 'staging' : 'production';
}
```

### 2. Base URL 配置矩阵

根据 [MISHI-002](../50_frontend/2026-03-17-flutter-base-url-app.md) 完成的状态：

| 环境 | Base URL | 用途 | 证书要求 |
|------|-----------|--|----|
| `dev` | `https://api.mishi.app/v1/dev` | 开发测试 | 自签名/无需 |
| `staging` | `https://api.mishi.app/v1/staging` | 预发布 | Let's Encrypt |
| `prod` | `https://api.mishi.app/v1` | 正式环境 | SSL 强制 |

### 3. 配置文件结构

```
lib/config/
├── environment_config.dart      # 环境抽象
├── api_client_config.dart       # API Client 配置
└── local_config_override.dart   # 本地覆盖（开发）
```

---

## 🔧 实施策略

### 1. 环境变量获取

#### iOS (Info.plist)
```xml
<key>ENVIRONMENT</key>
<string>development</string>  <!-- 可在 Xcode scheme 中修改 -->
```

#### Android (build.gradle)
```groovy
// 从 manifest 读取或 BuildConfig
String env = BuildConfig.FLAVOR == 'dev' ? 'dev' : 
                 BuildConfig.FLAVOR == 'staging' ? 'staging' : 'prod';
```

### 2. Config Loading 实现

```dart
// lib/config/environment_config.dart
class EnvironmentConfig {
  static final EnvironmentConfig _instance = EnvironmentConfig._internal();
  
  factory EnvironmentConfig() => _instance;
  
  String get baseUrl => 
    _currentEnv == Environment.production 
      ? 'https://api.mishi.app/v1'
      : _envUrls[_currentEnv.label];
      
  bool get isProduction => _currentEnv == Environment.production;
  
  Environment get current => _currentEnv;
  
  void switchEnvironment(Environment newEnv) {
    // 验证切换（生产环境需要特殊处理）
    if (newEnv == Environment.production && !_canSwitchToProd()) {
      throw Exception('Cannot switch to production from dev/staging');
    }
    _currentEnv = newEnv;
  }
  
  String get _envUrls => {
        'dev': 'https://api.mishi.app/v1/dev',
        'staging': 'https://api.mishi.app/v1/staging'
      };
}
```

### 3. 开发环境覆盖机制

```dart
// lib/config/local_config_override.dart
class LocalConfigOverride {
  // 仅在 dev 环境生效，可通过代码注入 Mock 配置
  Map<String, dynamic>? get mockOverrides => 
    const overrideLoader() != null ? null : {};
}

// 示例：开发时注入 Mock API
String? getMockBaseUrl() {
  if (kIsWeb || !isConnectedToNetwork()) {
    return 'https://mock-api.mishi.app/v1';  // Mock 服务
  }
  return null;
}
```

---

## 📊 配置管理矩阵

### Environment Detection Strategy

| 场景 | 检测方式 | 默认值 |
|------|---------|----|
| 首次安装 | Build flavor / Info.plist | `dev` |
| App Store | Bundle identifier (正式包) | `prod` |
| TestFlight | Bundle identifier (测试包) | `staging` |

### CI/CD Pipeline 配置

```yaml
# .circleci/config.yml 示例
workflows:
  build-and-deploy:
    jobs:
      - build:
          filters:
            branch:
              only: [main, develop]
            tags:
              only: /^v\d+\.\d+\.\d+$/
      - deploy-dev:
          requires: [build]
          filters:
            branch:
              only: [develop]
      - deploy-prod:
          requires: [build]
          filters:
            branches:
              ignore: [main]  # main 直接发布 prod
```

---

## 🔗 依赖关系

### 前置依赖
- **MISHI-002**: ✅ 已完成（Base URL 修正）

### 下游任务
- **MISHI-017**: Flutter 服务层设计文档（解除阻塞）

### 兄弟任务
- **MISHI-020**: Base URL 修正状态确认（P0，可并行）

---

## ✅ 执行证据

| 文件 | 路径 | 描述 |
|------|-----|----|
| 环境配置设计 | `collab/60_app/2026-03-18-flutter-multi-env-config-app.md` | 本文档 |
| Config 代码骨架 | `lib/config/environment_config.dart` (待创建) | 实现 |

---

## 📌 下一步行动

1. **创建代码文件**: 生成 `environment_config.dart` 等配置文件
2. **启动 MISHI-017**: 服务层设计文档（依赖 MISHI-015）
3. **更新队列状态**: 提议 MISHI-015 → review

---

*App Agent D019 | 2026-03-18 10:34*
