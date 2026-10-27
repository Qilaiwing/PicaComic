<p align="center">
  <img src="images/app_icon.png" width="120" height="120" alt="PicaComic MIUIX">
</p>

<h1 align="center">PicaComic · MIUIX</h1>

<p align="center">
  HyperOS / MIUIX 风格的 Android 漫画客户端<br>
  基于 <a href="https://github.com/Pacalini/PicaComic">Pacalini/PicaComic</a>，界面全面迁移至 <a href="https://github.com/ChuxinNeko/flutter_miuix">flutter_miuix</a>
</p>

<p align="center">
  <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.41.x-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-green" alt="License"></a>
  <a href="https://github.com/Qilaiwing/PicaComic_miuix/releases"><img src="https://img.shields.io/github/v/release/Qilaiwing/PicaComic_miuix" alt="Release"></a>
  <a href="https://github.com/Qilaiwing/PicaComic_miuix/releases"><img src="https://img.shields.io/github/downloads/Qilaiwing/PicaComic_miuix/total" alt="Downloads"></a>
</p>

---

> **AI 辅助声明**  
> 本仓库的界面迁移与相关代码修改在 AI 辅助下完成，可能存在未发现的问题。欢迎在 [Issues](https://github.com/Qilaiwing/PicaComic_miuix/issues) 反馈。

> **平台说明**  
> 本仓库仅包含 **Android** 源码。iOS / macOS / Windows / Linux / Web 请使用 [上游项目](https://github.com/Pacalini/PicaComic)。

## 下载

前往 [Releases](https://github.com/Qilaiwing/PicaComic_miuix/releases) 获取正式版 APK。

| 项目 | 说明 |
| --- | --- |
| 包名 | `com.picacomic_miuix` |
| 架构 | 目前仅提供 **arm64-v8a** |
| 签名 | 独立正式密钥；与调试包不同，升级前请先卸载旧版 |

## 最新更新 · 4.2.12-miuix1

- **搜索**：去掉自动空格转 chip；短多关键词按 AND；长标题原样发送；禁漫 `()` URL 编码；对齐上游 Pacalini 搜索线；历史 / 收藏标签改为左右滑分页
- **长按漫画选单**：圆角遮罩；每个选项独立主题色胶囊
- **EH 高级选项**：分类 chip 与筛选行排版收紧
- **搜索结果顶栏**：搜索胶囊与高度优化
- **收藏**：文件夹按压 squircle；本地收藏搜索顶栏 Miuix 化；本地长按胶囊；相关子页 Miuix 补齐

## 本分支改动

| | |
| :---: | --- |
| **MIUIX** | 按钮、开关、列表、对话框、弹窗、菜单、Tooltip、Tab、Scaffold 等统一为 Miuix 组件 |
| **顶栏** | 全局毛玻璃顶栏；内容可滚至栏下；大标题与分区标题同一视觉层 |
| **底栏** | 加高的悬浮胶囊导航；主 Tab 切换无闪烁 |
| **动效** | HyperOS 风格转场与预测性返回；收敛遮罩闪烁、弹窗黑边与切页回弹 |
| **页面** | 漫画详情操作区、分类「每周必看」等完成 Miuix 化；新启动图标 |

漫画源与阅读、下载等核心能力沿用上游。

## 内置漫画源

`picacg` · `e-hentai` / `exhentai` · `jmcomic` · `hitomi` · `htcomic` · `nhentai`

## 构建

**环境**：Flutter 3.41.x · JDK 17 · Android SDK

```shell
git clone --recursive -b miuix https://github.com/Qilaiwing/PicaComic_miuix.git
cd PicaComic_miuix
flutter pub get
flutter build apk --release --split-per-abi --target-platform android-arm64
```

正式签名请自行创建 `android/key.properties`（不随仓库提供）：

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/path/to/your.keystore
```

## 致谢

| 项目 | 说明 |
| --- | --- |
| [Pacalini/PicaComic](https://github.com/Pacalini/PicaComic) | 上游分支 |
| [nyne / wgh136](https://github.com/wgh136) | 原作者 |
| [flutter_miuix](https://github.com/ChuxinNeko/flutter_miuix) | MIUIX 组件 |
| [JMComic-qt](https://github.com/tonquer/JMComic-qt) | JM 图片重排 |
| [EhTagTranslation](https://github.com/EhTagTranslation/Database) | 标签翻译 |

## 许可证

[MIT](LICENSE)