import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/translations.dart';

/// Debug helpers shown from Settings → APP when running a debug build.
void debug() async {
  final ctx = App.globalContext;
  if (ctx == null) return;

  Future<void> run(int index) async {
    switch (index) {
      case 0:
        final info = StringBuffer()
          ..writeln("version: $appVersion")
          ..writeln(
              "platform: ${App.isAndroid ? "android" : App.isIOS ? "ios" : "desktop"}")
          ..writeln(
              "sources: ${ComicSource.sources.map((e) => e.key).join(", ")}");
        await Clipboard.setData(ClipboardData(text: info.toString()));
        showToast(message: "已复制".tl);
        break;
      case 1:
        final list = ComicSource.sources.map((e) => e.key).join(", ");
        LogManager.addLog(LogLevel.info, "Debug", list);
        showToast(message: list.isEmpty ? "无漫画源".tl : list);
        break;
      case 2:
        LogManager.addLog(LogLevel.info, "Debug", "test log @ ${DateTime.now()}");
        showToast(message: "已写入".tl);
        break;
      case 3:
        showToast(
          message: kDebugMode
              ? "当前为 Debug 构建".tl
              : "当前为 Profile/Release 构建".tl,
        );
        break;
    }
  }

  showMiuixDialog(
    context: ctx,
    title: "Debug",
    contentBuilder: (context, close) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in [
          (0, "复制设备信息".tl),
          (1, "打印漫画源列表".tl),
          (2, "写入一条测试日志".tl),
          (3, "显示调试横幅状态".tl),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MiuixButton(
              cornerRadius: 14,
              minHeight: 44,
              minWidth: double.infinity,
              onPressed: () async {
                close();
                await run(entry.$1);
              },
              child: Text(entry.$2),
            ),
          ),
      ],
    ),
  );
}
