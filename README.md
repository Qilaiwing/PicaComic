# Pica Comic · MIUIX

[![flutter](https://img.shields.io/badge/flutter-3.41.6-blue)](https://flutter.dev/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Release](https://img.shields.io/github/v/release/Qilaiwing/PicaComic)](https://github.com/Qilaiwing/PicaComic/releases)

基于 [Pacalini/PicaComic](https://github.com/Pacalini/PicaComic) 的 Android 分支，将整套界面迁移到 **HyperOS / MIUIX 设计风格**（使用 [flutter_miuix](https://github.com/ChuxinNeko/flutter_miuix)）。漫画源与核心功能沿用上游。

> ⚠️ 本版本的 UI 迁移与代码修改在 AI 辅助下完成，可能存在未发现的问题，欢迎反馈。

> 本仓库只包含 Android 源码，iOS / macOS / Windows / Linux / Web 平台请使用上游项目。

## 下载

在 [Releases](https://github.com/Qilaiwing/PicaComic/releases) 下载 `app-arm64-v8a-release.apk`（目前只提供 arm64-v8a）。

## 本分支的改动

- **全面 MIUIX 化**：按钮、开关、列表项、对话框、底部弹窗、菜单、Tooltip、Tab、Scaffold 等全部替换为 Miuix 组件，统一背景色与圆角。
- **HyperOS 风格顶栏**：大标题、小标题栏，全局毛玻璃顶栏，内容可滚动到顶栏下方；Tab 与吸顶标题融入顶栏。
- **悬浮底部导航栏**：更高的悬浮胶囊导航栏，切换 Tab 无过渡闪烁。
- **页面转场**：更顺滑的转场动画、支持预测性返回，修复设置页抖动、弹窗视差黑边、页面回弹等问题。
- **漫画详情页**：操作按钮（从头开始 / 分享 / 收藏 / 删除等）统一为 Miuix 按钮，与「下载 / 开始阅读」尺寸一致。
- **分类 · 每周必看**：Miuix 顶栏 + 胶囊 Tab + Miuix 菜单选择期数。
- **我的页面**：个人信息卡片带按压倾斜效果，未登录提示「请登录您的PicACG」。
- 修复探索页布局崩溃、搜索页 build 阶段 setState 等若干问题；新启动图标。

## 内置漫画源

picacg、e-hentai/exhentai、jmcomic、hitomi、htcomic、nhentai

## 构建

```shell
git clone --recursive -b miuix https://github.com/Qilaiwing/PicaComic
cd PicaComic
flutter pub get
flutter build apk --release --split-per-abi --target-platform android-arm64
```

需要 Flutter 3.41.x、JDK 17、Android SDK。release 签名读取 `android/key.properties`（自行创建，不随仓库提供）：

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/path/to/your.keystore
```

## 致谢

- 上游项目：[Pacalini/PicaComic](https://github.com/Pacalini/PicaComic)，原作者 [nyne](https://github.com/wgh136)
- UI 组件：[flutter_miuix](https://github.com/ChuxinNeko/flutter_miuix)
- JM 图片重排算法：[tonquer/JMComic-qt](https://github.com/tonquer/JMComic-qt)
- 标签翻译：[EhTagTranslation/Database](https://github.com/EhTagTranslation/Database)

## 许可证

MIT，见 [LICENSE](LICENSE)。
