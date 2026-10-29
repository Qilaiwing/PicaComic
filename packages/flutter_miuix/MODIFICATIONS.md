# MODIFICATIONS / 修改说明

本目录源自 [ChuxinNeko/flutter_miuix](https://github.com/ChuxinNeko/flutter_miuix)（Apache License 2.0），基于上游提交 `3c6f64d7f49753ce58d16ea6f9149459962fe916`（v1.3.0），以普通文件形式内置于 PicaComic_MIUIX，并做了以下修改。

This directory is derived from [ChuxinNeko/flutter_miuix](https://github.com/ChuxinNeko/flutter_miuix) (Apache License 2.0), based on upstream commit `3c6f64d7f49753ce58d16ea6f9149459962fe916` (v1.3.0), vendored into PicaComic_MIUIX as plain files with the following modifications.

## 本地修改 / Local changes

- **卡片按压效果 / Card press effect**：整卡倾斜（变换移到裁剪外层），MiuixCard 使用超椭圆（squircle）形状并裁剪子组件，按压水波与圆角一致；按压遮罩使用抗锯齿裁剪。
  Whole-card tilt (transform outside the clip); MiuixCard uses a squircle shape and clips its children so the press splash matches the corners; the press overlay is clipped with anti-aliasing.
- **模糊与玻璃 / Blur & glass**：调整高光、背景层模糊与纹理模糊实现，降低开销，适配 PicaComic 的毛玻璃开关。
  Tuned highlight, layer-backdrop and texture blur for lower cost and to support the app's frosted-glass toggle.
- **组件 / Components**：底部弹窗、下拉菜单、弹出列表、Scaffold、顶栏、滑条设置项、小标题、Snackbar、输入框、取色器等的样式与行为修正。
  Style and behaviour fixes for bottom sheet, dropdown, list popup, scaffold, top app bar, slider preference, small title, snackbar, text field and color picker.
- **图标与内容色 / Icons & content color**：图标集与内容颜色调整。
  Icon set and content-color adjustments.
- **精简 / Trimmed**：移除 example/、test/、doc/、skill/、tool/ 等与运行无关的内容。
  Removed example/, test/, doc/, skill/, tool/ and other non-runtime content.

原始许可证见本目录 `LICENSE`。 / The original license is in `LICENSE` in this directory.