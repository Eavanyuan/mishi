# 觅诗 App UI 规范与设计 Token（v1）

## 1. 设计原则
- 简洁：界面元素少而准，优先突出诗句与场景
- 沉浸：通过留白、层次、声音营造“慢阅读”体验
- 一致：地图、详情、播放三大核心场景风格统一

## 2. 色彩系统
- `color.primary`: `#1F4D4F`（黛青）
- `color.background`: `#F7F2E8`（米白）
- `color.accent`: `#B23A2B`（朱砂）
- `color.text.primary`: `#1E1E1E`
- `color.text.secondary`: `#5B5B5B`
- `color.success`: `#2E7D32`
- `color.warning`: `#D9822B`
- `color.error`: `#C62828`

## 3. 字体系统
- 标题字体：Source Han Serif SC（思源宋体）
- 正文字体：Source Han Sans SC（思源黑体）
- 字号建议：
  - `display`: 32/40
  - `h1`: 24/32
  - `h2`: 20/28
  - `body`: 16/24
  - `caption`: 12/18

## 4. 间距与圆角
- 间距基准：4px 网格
- 常用间距：8/12/16/24/32
- 圆角：
  - 卡片：16
  - 按钮：12
  - 小标签：8

## 5. 组件规范
### 卡片（Poem Card）
- 高度：128
- 内容：题名、作者、一句导语、距离
- 状态：默认/已读/推荐

### 主按钮（Primary Button）
- 高度：48
- 字重：Semibold
- 背景：黛青，文字：米白

### 标签（Tag）
- 用于“古称/今称/低置信度”等状态
- 支持语义色（信息/警示）

### 播放浮层（Mini Player）
- 固定底部，显示当前诗词与播放状态
- 点击展开全屏播放页

## 6. 动效规范
- 页面切换：200ms ease-out
- 卡片浮现：160ms + 20ms stagger
- 诗句高亮：按音频时间轴平滑过渡
- 禁止过度动画，避免干扰阅读

## 7. 无障碍规范
- 正文最小字号不低于 16px
- 对比度满足 WCAG AA
- 所有图标提供可访问名称
- 关键操作支持系统读屏

## 8. 设计交付物清单
- Figma 页面：
  - `00_Foundation`
  - `01_Components`
  - `02_Flows`
  - `03_High_Fidelity`
- 导出：切图规范、标注规范、交互说明
