# 觅诗 App Figma-Ready 设计说明稿（现代文艺版 v1）

适用范围：基于 [high_fidelity_prototype.html](/Users/yuanyuan/Documents/design/high_fidelity_prototype.html) 的现代文艺方案（已含季节推荐 + 旅行地打卡）。
目标：设计师可直接按本文在 Figma 搭建高保真页面并交付开发。

## 1. Figma 文件结构
在 Figma 中创建以下页面（Page）：
- `00_Cover`
- `01_Foundation`
- `02_Components`
- `03_Screens_Modern`
- `04_Prototype_Notes`
- `05_Export`

## 2. 画板与基础设置
- 设备画板：`iPhone 14 Pro`（393 x 852）
- 安全区参考：
  - 顶部状态区：47
  - 底部 Home Indicator 区：34
  - 内容区左右边距：16
- 栅格：4px 基线网格
- 画板命名规范：`M01_启动页`、`M02_权限引导` ...

## 3. Foundation（设计 Token）
### 3.1 色彩
- `Primary/600`: `#0E7A7D`
- `Primary/050`: `#EAF8F8`
- `Background/Base`: `#FFF9EE`
- `Accent/600`: `#E14B34`
- `Text/Primary`: `#172222`
- `Text/Secondary`: `#5B5B5B`
- `Success/600`: `#2E7D32`
- `Warning/600`: `#D9822B`
- `White`: `#FFFFFF`

### 3.2 字体
- 标题字体：`Source Han Serif SC`（无则用 `Noto Serif SC`）
- 正文字体：`Source Han Sans SC`（无则用 `Noto Sans SC`）
- 字号层级：
  - `Display`: 32/40
  - `H1`: 24/32
  - `H2`: 20/28
  - `Body`: 16/24
  - `Caption`: 12/18

### 3.3 圆角、阴影、边距
- Radius：`8 / 12 / 16 / 22`
- 卡片阴影：`0 10 26 0`，颜色 `rgba(14,122,125,0.12)`
- 页面对外边距：16
- 模块间距：12 或 16

## 4. 组件库（Components）
### 4.1 Button
建立组件集：`Button / Size=44 / Type=Primary|Ghost / State=Default|Pressed|Disabled`
- Primary
  - 背景：`#0E7A7D`
  - 文本：`#FFFFFF`
- Ghost
  - 背景：`#FFFFFF`
  - 文本：`#0E7A7D`
  - 边框：`1px rgba(14,122,125,0.24)`
- Disabled
  - 背景：`#D9E7E7`
  - 文本：`#9AAFB0`

### 4.2 Chip（季节/地名标签）
建立组件集：`Chip / Type=Default|Accent|Season / State=Default|Selected`
- Default：背景 `rgba(14,122,125,0.14)`，文字 `#0E7A7D`
- Accent：背景 `rgba(225,75,52,0.16)`，文字 `#E14B34`
- Season：背景 `#EAF8F8`，文字 `#0E7A7D`

### 4.3 Card
建立组件集：`Card / Type=Content|Recommendation|Status / State=Default|Highlighted`
- 背景：`rgba(255,255,255,0.78)`
- 边框：`1px rgba(255,255,255,0.65)`
- 圆角：16

### 4.4 Bottom Navigation
建立组件：`BottomNav / Item=4 / Active=Home|Nearby|Play|Mine`
- 高度：56
- 背景：`rgba(255,255,255,0.8)`
- Active 文本：`#0E7A7D` + Semibold

### 4.5 Mini Player
建立组件：`MiniPlayer / State=Playing|Paused`
- 背景：`rgba(14,122,125,0.95)`
- 高度：52
- 左侧显示当前诗句片段，右侧播放状态

### 4.6 Map Pin
建立组件：`MapPin / Type=Default|Current`
- Default：`#E14B34`
- Current：`#0E7A7D`
- 外扩光圈：8，20% 透明度

## 5. 逐屏视觉规格（03_Screens_Modern）
说明：以下为逐屏搭建顺序与关键标注，按 `Mxx_页面名` 创建。

### M01 启动页
- 顶部：状态栏（9:41 / 5G / 电量）
- 主标题：`觅诗`，Display
- 副文案：Body，居中
- 中部插画占位卡：高 300
- 底部主按钮：`开启诗意旅程`

标注：
- 标题距顶部内容区 48
- 标题与副文案间距 12
- 插画卡与按钮间距 20

### M02 权限引导
- 标题：`授权后体验更完整`
- 三张权限卡：定位、通知、媒体
- 底部主按钮：`同意并继续`

标注：
- 卡片垂直间距 12
- 按钮距最后卡片 16

### M03 地图首页（季节+打卡）
- 搜索卡（高度 40）
- 地图区（高度 320）+ 3 个 Pin
- 推荐卡内容：
  - 标题：`此地推荐 · 《登鹳雀楼》`
  - 导语：作者/距离/场景
  - 标签：`季节：秋`、`节气：白露`
  - CTA：`去感受`、`立即打卡`、`稍后提醒`
- 底部导航（Home Active）

标注：
- 地图区与推荐卡间距 12
- 推荐卡内标签与按钮间距 8

### M04 到地弹层
- 底部弹层卡（贴近底部）
- 信息：题名 + 核心诗句 + 季节提示
- CTA：`去感受`、`立即打卡`、`稍后提醒`

标注：
- 弹层内边距 18
- 三按钮横向均分

### M05 诗词详情
- 顶部标签：今称、古称、最佳季节
- 标题：诗名 + 作者朝代
- 正文诗句大字号
- 权威解读卡
- CTA：`朗读`、`生成动画`
- 底部 Mini Player

标注：
- 诗句段落行高 1.9
- Mini Player 固定底部，浮于内容上方

### M06 解读切换
- Tab：教材版/学术版/通俗版
- 三块内容卡：核心解释、来源、更新时间

标注：
- 激活 Tab 使用 Primary 样式

### M07 朗读播放
- 顶部封面卡（高 220）
- 诗句同步高亮（高亮字色 Accent）
- 进度条 + 0.8x/播放/1.2x 控件
- 氛围音状态卡

### M08 动画生成
- 参数卡：风格、时长
- 主按钮：`开始生成`
- 状态卡：队列与预计等待

### M09 动画结果
- 预览卡（高 290）
- 成功状态卡（Success 色）
- 按钮：保存本地 / 分享 / 再次生成

### M10 打卡弹层（新增）
- 标题：`琉璃厂 · 诗词打卡`
- 标签：`打卡点已到达`、`秋·白露`
- 内容：诗句 + 时间戳
- CTA：`确认打卡`、`生成打卡卡片`

### M11 旅行路线（新增）
- 标题：`北京 · 诗词旅行线`
- 路线副标题：半日路线串联
- 三张信息卡：进度、推荐季节、下一站
- CTA：`继续打卡`、`查看一日路线`

### M12 个人中心
- 模块卡：收藏、足迹、旅行打卡、路线成就、动画记录、设置
- 底部导航（Mine Active）

## 6. 标注规范（可直接交付开发）
在 `04_Prototype_Notes` 页面使用编号标注：`A01`、`A02`...
每条标注包含：
- 元素名（如 `A01 推荐卡-标题`）
- 尺寸（W/H）
- 间距（Top/Left/Gap）
- 样式（颜色、字号、字重、圆角、阴影）
- 状态（Default/Pressed/Disabled）

推荐标注格式：
- `A01`: `Card/Recommendation`，W=361, Radius=16, Shadow=`0 10 26 rgba(14,122,125,.12)`
- `A02`: `Button/Primary`，H=44, BG=`#0E7A7D`, Text=`#FFF`

## 7. 原型交互连接（Prototype）
- M01 按钮 -> M02
- M02 按钮 -> M03
- M03 `去感受` -> M05
- M03 `立即打卡` -> M10
- M05 `朗读` -> M07
- M05 `生成动画` -> M08
- M08 成功态 -> M09
- M10 `确认打卡` -> Toast（打卡成功）
- M11 `继续打卡` -> M03

动效参数：
- 页面切换：`Smart Animate 200ms Ease Out`
- 卡片出现：`160ms`（可做 20ms stagger）

## 8. 导出规范（05_Export）
- 图标与插图：`@1x/@2x/@3x` PNG
- 透明素材：PNG
- 矢量图形：SVG
- 命名：`mishi_[module]_[name]_[state]`
  - 示例：`mishi_button_primary_default`

## 9. 交付检查清单
- 所有页面使用统一组件实例（不是散件）
- 所有颜色来自 Token，不手填临时色
- 关键按钮具备 3 状态（Default/Pressed/Disabled）
- 所有新增页面（M10/M11）已接入原型流
- 标注层可隐藏，且不影响展示层

## 10. 版本记录
- v1.0（2026-03-02）：首版 Figma-ready 说明，覆盖现代文艺版全流程，已含季节推荐与旅行地打卡。
