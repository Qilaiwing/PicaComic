# Changelog

## 1.3.0

### 新增

- **`MiuixGlassNavigationItem.isAction`**：导航栏可放置「动作项」（如搜索、新建），点击只触发 `onSelect`，不移动选中指示器、不改变选中态。
- **`MiuixGlassTopAppBar.bandHeightFactor` / `bandBlurRadius`**：可调节顶栏模糊带的高度比例（默认 1）与实时高斯模糊半径（默认 24，0 关闭模糊）。
- **`MiuixLayerBackdropCapture.pixelRatio`**：可覆盖背景快照的像素比，降低快照分辨率以换取性能。
- **`MiuixGlassRendering.loadError` / `loadedPrograms` / `has()`**：暴露 OS4 shader 加载状态，便于排查「玻璃不够通透」类降级问题。

### 改进

- **OS4 玻璃 shader 逐个降级**：单个 shader 加载失败不再拖垮全部玻璃效果；blend shader 缺席时改用原生 `BlendMode` 混色（`MiuixGlassColorBlendMode.fallback`），无 runtime shader 的设备也能得到「模糊背景 + 混色层」的真玻璃，而非一块实色。
- **玻璃模糊改走 `saveLayer`**：修复部分后端（尤其 Impeller）上 `drawImageRect` 的 image filter 静默失效、玻璃里能看清背后文字的问题。
- **玻璃淡入更柔和**：不做仿生着色的表面（栏、菜单、栏内按钮）改为整层 alpha 淡入，消除「硬边模糊圆片先冒出、颜色再补上」的延迟感。
- **顶栏模糊带**：默认色调渐变改为半透明，下方叠加真实高斯模糊并在下缘平滑淡出，更贴近原生 HyperOS 4。
- **导航栏拖拽**：滑块按手指位置直接跟随；松手在栏内才提交选择；按下态仅重建必要子树。
- **性能**：玻璃材质按值比较并缓存栏内材质实例，避免滚动时逐帧丢纹理缓存；背景快照只在内容真正变化时重新截取；多处 `MediaQuery.of` 改为细粒度 `sizeOf` / `paddingOf` 等，减少无关重建。
- **无障碍**：颜色调色板补充 `increasedValue` / `decreasedValue` 语义。

### 测试

- 新增 OS4 玻璃交互与渲染回归测试（shader 降级、快照复用、导航拖拽等）。

## 1.2.0

### 新增

- **HyperOS 4 玻璃材质与组件（可选，不改动既有组件默认表现）**：移植上游 `feat/miuix-glass` 分支 `3f7debbf`（2026-09-06），新增一整套 `MiuixGlass*` 组件与玻璃材质基础设施，与旧组件并存。导入 `package:flutter_miuix/miuix.dart` 后按需使用，无需更换主题，原有界面样式零变化。
  - 组件：`MiuixBlurTopAppBar`、`MiuixGlassTopAppBar`、`MiuixGlassIconButton`、`MiuixGlassNavigationBar`、`MiuixGlassTabRow`、`MiuixGlassSegmentedTabRow`、`MiuixGlassPopup` / `MiuixGlassPopupItem`、`MiuixGlassTransformPopup`、`MiuixGlassSecondaryPopup`、`MiuixGlassDropdownPopup`、`MiuixGlassDialog`，以及 `MiuixGlass` / `MiuixGlassPanel` / `miuixGlassSurface` 三种材质包装方式。
  - 材质与动效：35 组玻璃样式预设（`MiuixGlassStyles`）、材质混合层、6 个运行时片元着色器（`miuix_os4_glass/mask/stroke/shadow/rim/blend.frag`）、可逆弹窗变形动效、导航栏拖拽切换。
  - 图标：`MiuixIcons.os4` 新增 176 枚 OS4 符号，覆盖 5 档字重，含 RTL 镜像处理。
- **旧版级联菜单支持玻璃表面**：`MiuixCascadingDropdownMenu` / `MiuixCascadingListPopup` 等新增可选的玻璃表面构建器，老接口可渐进接入 OS4 观感。
- **OS4 示例页**：example 新增独立 OS4 展示页，内置图标搜索。
- **文档**：新增中英双语 API 参考章节 `110_os4.{zh,en}.md`（同步至 AI Skill 包 references）。

### 测试

- 新增交互、生命周期、几何、兼容性与像素级渲染测试（`test/os4_glass*.dart`）。

### 其他

- README 中英文版新增免责声明章节（本项目与小米公司无从属关系）。



## 1.1.1

### 修复

- **下拉刷新回弹被中断时内部锁泄漏**：松手触发刷新后的弹簧回弹（`_animateSpringTo`）未完成时再次下拉会取消回弹，此时 `_isRefreshingInternally` 内部锁未释放，导致此后所有松手都被提前拦截、指示器永远卡在拉长状态不再回弹也不再刷新。现于回弹被取消（`!settled`）时显式释放锁。新增回归测试 `test/pull_to_refresh_interrupt_test.dart`。
- **pubspec.yaml 中文注释在中文 Windows 下导致 YAML 解析失败**：`pub` 在中文 Windows（系统代码页 936）把 `git show` 输出按 GBK 解码，中文注释字节被破坏、全角标点吞掉其后换行，把 `shaders:` 并进注释行，YAML 解析器报 "Expected a key while parsing a block mapping"。现将 `pubspec.yaml` 内注释统一改为 ASCII。

### 依赖

- `dynamic_color` ^1.8.1 → ^1.9.0。

## 1.1.0

### 新增

- **文字字重跟随系统（fontWeightAdjustment）**：此前未指定字重的文本一律按 Flutter 默认 `w400` 渲染，不随系统字体粗细度变化；而 MiuiX Compose 依托 Android 平台自动施加的 `Configuration.fontWeightAdjustment`，会把一个偏移量整体加到每段文字最终解析出的字重上（正文 400→500、半粗标题 600→700、粗体标题 700→800）。移植版现复刻该机制：`MiuixThemeData` 新增 `fontWeightAdjustment`（权重数值，100 为一档），组件在渲染时把偏移应用到最终字重（未指定按 `w400` 处理）。`MiuixSystemTheme` / `MiuixThemeController` 默认读 `MediaQuery.boldTextOf` 自动跟随系统「粗体文字」（开启 +100，可由 `boldTextFontWeightAdjustment` 调整），也可用 `fontWeightAdjustment` 显式指定任意值关闭自动跟随。新增底层辅助 `adjustFontWeight()` 与 `TextStyle.withMiuixWeight()`。`fontWeightAdjustment == 0`（默认）时行为与旧版完全一致，无回归。



## 1.0.9

### 修复

- **大标题折叠后稍微下滑立即弹回大标题（1.0.8 门控仍未根治）**：`ExitUntilCollapsedScrollBehavior` 此前把 `heightOffset` 当成独立累加量（逐 delta 门控增减），并在松手时用弹簧 `snap` 吸到端点。`snap` 会把 `heightOffset` 拉到完全折叠/展开，而真实滚动位置 `pixels` 仍停在顶部过渡区中段——两者就此**解耦**：折叠到居中小标题后轻微下滑，门控发现 `pixels` 尚在过渡区，按增量把标题又展开，视觉上"稍微一动就弹回大标题"。现改为**按位置直接映射**：`heightOffset = -(pixels - minScrollExtent)`，再由 setter 钳到 `[heightOffsetLimit, 0]`。折叠量恒为滚动位置的纯函数，只有内容滚回顶部对应位置才逐像素恢复，中途上/下滑绝不跳变（对齐 iOS/标准大标题语义）。随之移除累加门控、松手 `snap`（弹簧动画）、`AnimationController`/`TickerProvider` 依赖，`MiuixScrollBehaviorListener` 降为无状态组件。回归测试同步更新 `test/top_app_bar_scroll_gate_test.dart`。

## 1.0.8

### 修复

- **大标题在列表中部下滑时被弹回展开**：`ExitUntilCollapsedScrollBehavior` 此前对上滑/下滑对称累加 `heightOffset`，在列表任意位置轻微下滑都会立即展开顶栏（松手后还被 snap 完整弹回大标题），偏离 Kotlin 原版"下滑仅在内容到顶后才展开"的语义。现改为按内容位置门控：只统计发生在顶部过渡区间 `[minScrollExtent, minScrollExtent + 展开量]` 内的滚动行程——中部下滑门控量恒为 0 保持折叠，滚回顶部区间才逐像素展开（含 iOS 弹性下拉过顶段）；上滑折叠只忽略回弹归位段（min 以下），其余不变。Android `ClampingScrollPhysics` 到顶后 `scrollDelta` 被钳成 0 的场景（当年对称累加的动机），改用顶部 `OverscrollNotification`（overscroll < 0）驱动展开，对应 Kotlin `onPostScroll` 的"剩余下滑量"。回归测试 `test/top_app_bar_scroll_gate_test.dart`。
- **内嵌子列表误驱动顶栏折叠**：`handleScroll` 未过滤通知来源，页面内嵌套的横向/内层滚动视图（如卡片里的横向列表）滚动时也会牵动大标题。现仅响应 `depth == 0` 且竖向轴的通知。

## 1.0.7

### 修复

- **PullToRefresh 下拉中段触发 RenderFlex 溢出断言**：刷新头内容（指示圈 + 文案）在 `SizedBox(height: 动画高度)` 的受限约束内用 `Column` 布局，头部尚未展开到内容自然高度时（进度约 < 0.7）每帧抛出 "overflowed by N pixels on the bottom"（视觉上本就被 `ClipRect` 裁剪，仅调试期噪音）。现在 `ClipRect` 内垫一层顶部锚定、纵向无界的 `OverflowBox`，内容始终按自然高度布局、由裁剪负责渐显，视觉行为不变、断言消除。

## 1.0.6

### 修复

- **TopAppBar 超长标题溢出屏幕**：主/副标题的 `Text` 位于 `Positioned(left, top)` 下，宽度无界，`maxLines: 1 + ellipsis` 永远不触发，长标题直接画出屏幕。现按当前折叠进度计算可用宽度（大端点右留 `titlePadding` 对称边距、小端点避开 actions）并用 `ConstrainedBox` 显式限宽，超长时正确显示省略号；折叠端点的居中定位同步改用钳制后的文字宽度，避免超长标题的目标位置压到导航图标上。

## 1.0.5

### 修复

- **对话框被输入法遮挡**：`MiuixOverlayDialog` 在手机上底部锚定，但底边距只计算了安全区，未计入键盘高度（`viewInsets.bottom`）。现在面板随键盘上移（`AnimatedPadding` 平滑跟随，取键盘高度与底部安全区较大值），对应 Compose 版 `imePadding` 语义。
- **弹层宿主拆卸期断言**：整棵树销毁时 `MiuixDialogLayout.dispose` 的 `dismiss()` 会同步触发宿主可见性回调，在已 deactivate 的 element 上读 `MediaQuery` 抛 "deactivated ancestor" 断言。回调入口现已短路。

## 1.0.4

### 修复

- **TopAppBar 折叠标题飞出屏幕**：`MiuixIconButton` / `MiuixButton` / `MiuixFloatingActionButton` 内部 `Center` 未设 `widthFactor/heightFactor`，在有界宽松约束下被撑满可用空间（Compose `defaultMinSize` 语义应贴内容尺寸）。TopAppBar 测量层因此把导航图标测成整屏宽，折叠标题的避让目标被推到屏幕外——滚动时标题向右飞出。现已改为贴内容尺寸；注意这同时意味着按钮在 Column/ListView 等有界宽松上下文中不再自动撑满宽度（需要全宽时请自行包 `SizedBox(width: double.infinity)`）。
- **折叠标题目标位置防御性钳制**：无论 nav/actions 测量结果如何，折叠目标绝不超出可视范围。
- **吸附动画与手势争抢**：松手后的吸附动画不会被新滚动手势取消，与手势输入争抢 `heightOffset`（症状：折叠到底后被残留动画拉回展开、滚动中标题抖动）。现在新手势开始时停止残留吸附动画。

## 1.0.3

### 修复

- **MiuixTextField 点击无法聚焦**：占位/浮动标签的 `Text` 叠在内部 `TextField` 之上且参与命中测试（`RenderParagraph` 命中即止），点在占位文字上事件被吞掉，无法唤起键盘。标签现包裹 `IgnorePointer`。
- **MiuixTextField 整块可点击**：背景、内边距与非交互图标区域此前不可点击（有效点击区仅剩文本行本身）。现在整个输入框区域点击均聚焦唤起键盘（与 Compose 原版一致）；内部 trailing 按钮等更深层手势优先级不受影响。

### 新增

- **MiuixTextField.autofocus**：挂载后自动聚焦并唤起键盘（常用于对话框内输入框），默认 `false`。

## 1.0.2

### 修复

- **MiuixTextField**：`textInputAction` / `textCapitalization` / `onSubmitted` 此前未转发给内部 `TextField`，导致键盘 action 键（搜索/完成）与提交回调不生效。现已正确转发。
- **弹层 entry 双重 dispose**：承载弹层的路由整体 pop 时，`MiuixDialogLayout`/`MiuixPopupLayout` 的 State 与 popup host 的 HostedEntry 会在同一帧卸载，双方的 orphaned 判断同时成立并各自调用 `entry.dispose()`，抛 use-after-dispose 断言。`MiuixPopupEntry.dispose` 现已幂等（新增 `isDisposed`），二次调用为无害 no-op。

### 变更

- **包结构调整**：实现文件移入 `lib/src/`，仅保留 `lib/miuix.dart` 作为唯一公开入口。pub.dev 安装页现在只显示一行 `import 'package:flutter_miuix/miuix.dart';`，不再逐个列出内部文件。公开 API 与导入方式不变。

## 1.0.0

首个发布版本。miuix（Kotlin Multiplatform）组件库到 Flutter 的 1:1 移植。

### 新增

- **完整组件覆盖**：45+ 个组件，覆盖 Button / TextField / Switch / Slider / Checkbox / RadioButton / NavigationBar / FloatingNavigationBar / NavigationRail / Scaffold / TopAppBar / SmallTopAppBar / TabRow / BreadcrumbBar / Card / Badge / Divider / SmallTitle / BasicComponent / 各类 Preference / Dropdown / Spinner / CascadingMenu / NumberPicker / ColorPicker / ColorPalette / DatePicker / BottomSheet / FloatingToolbar / Dialog / Snackbar / Tooltip / ProgressIndicator / SearchBar / ScrollBar / PullToRefresh / Surface 等。
- **Squircle 超椭圆圆角**：`MiuixSquircleBorder` 复刻 iOS/HyperOS 圆角。
- **Folme 弹簧动效**：`MiuixSpringEngine` + `folmeSpring(damping, response)`。
- **液态玻璃**：`MiuixTextureBlur`（`ImageFilter.blur` 高斯模糊 + 颜色控制）、`MiuixHighlight`（着色器 bloom 高光描边）、`MiuixLayerBackdrop` / `MiuixLayerBackdropCapture` 背景捕获；另有一行开启的毛玻璃顶栏 `MiuixTopAppBar(blurred: true)`。
- **Monet 动态取色**：基于 `material_color_utilities` + `dynamic_color`，从壁纸或种子色生成整套 miuix 配色（27 个语义角色）。
- **OkLab / OkLCH / OkHSV 色彩空间**：完整移植原版感知均匀色彩数学。
- **矢量图标系统**：`MiuixVectorIcon` + `MiuixBasicIcons`（7 个基础图标）/ `MiuixExtendedIcons`（156 个扩展图标 × 5 字重）。
- **主题体系**：`MiuixTheme` / `MiuixThemeData` / `MiuixThemeController`，支持明暗模式与动态取色。
