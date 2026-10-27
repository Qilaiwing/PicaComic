import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MiuixScaffold(
      content: (_) => SmoothCustomScrollView(
        slivers: [
          SliverAppbar(
            title: Text("Logs".tl),
            actions: [
              Builder(
                builder: (buttonContext) => MiuixIconButton(
                  onPressed: () async {
                    final index = await showMiuixMenu(
                      context: context,
                      anchorBounds: miuixAnchorRectOf(buttonContext),
                      alignment: MiuixPopupAlign.end,
                      items: ["清空".tl, "禁用长度限制".tl, "导出".tl],
                    );
                    switch (index) {
                      case 0:
                        setState(() => LogManager.clear());
                      case 1:
                        LogManager.ignoreLimitation = true;
                        showToast(message: "仅在本次运行时有效".tl);
                      case 2:
                        saveLog(LogManager().toString());
                    }
                  },
                  child: const Icon(Icons.more_horiz),
                ),
              ),
            ],
          ),
          if (LogManager.logs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  "暂无日志".tl,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final logIndex = LogManager.logs.length - index - 1;
                    final log = LogManager.logs[logIndex];
                    final levelColor = [
                      scheme.error,
                      scheme.tertiary,
                      scheme.primary,
                    ][log.level.index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MiuixCard(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                          child: SelectionArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: ShapeDecoration(
                                        shape: const StadiumBorder(),
                                        color: isDark
                                            ? const Color(0xFF2A2A2E)
                                            : const Color(0xFFF0F1F5),
                                      ),
                                      child: Text(
                                        log.title,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: ShapeDecoration(
                                        shape: const StadiumBorder(),
                                        color: levelColor.withValues(alpha: 0.18),
                                      ),
                                      child: Text(
                                        log.level.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: levelColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      log.time.toString().replaceAll(RegExp(r"\.\w+"), ""),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  log.content,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: MiuixTextButton(
                                    "复制".tl,
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: log.content),
                                      );
                                      showToast(message: "已复制".tl);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: LogManager.logs.length,
                ),
              ),
            ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
          ),
        ],
      ),
    );
  }
}
