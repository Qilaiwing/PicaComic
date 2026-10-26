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
    return MiuixScaffold(
      content: (_) => SmoothCustomScrollView(
        slivers: [
          SliverAppbar(
            title: const Text("Logs"),
            actions: [
              Builder(builder: (buttonContext) => MiuixIconButton(
                onPressed: () async {
                  // 菜单锚定在按钮本身，不再用 padding.top + kToolbarHeight 估算顶栏位置。
                  final index = await showMiuixMenu(
                    context: context,
                    anchorBounds: miuixAnchorRectOf(buttonContext),
                    alignment: MiuixPopupAlign.end,
                    items: ["清空".tl, "禁用长度限制".tl, "导出".tl],
                  );
                  switch (index) {
                    case 0:
                      setState(()=>LogManager.clear());
                    case 1:
                      
                      LogManager.ignoreLimitation = true;
                      showToast(message: "仅在本次运行时有效".tl);
                    
                    case 2:
                      saveLog(LogManager().toString());
                  }
                },
                child: const Icon(Icons.more_horiz)))
            ],
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                index = LogManager.logs.length - index - 1;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: SelectionArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(5, 0, 5, 1),
                                child: Text(LogManager.logs[index].title),
                              ),
                            ),
                            const SizedBox(width: 3,),
                            Container(
                              decoration: BoxDecoration(
                                color: [
                                  Theme.of(context).colorScheme.error,
                                  Theme.of(context).colorScheme.errorContainer,
                                  Theme.of(context).colorScheme.primaryContainer
                                ][LogManager.logs[index].level.index],
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(5, 0, 5, 1),
                                child: Text(
                                  LogManager.logs[index].level.name,
                                  style: TextStyle(color: LogManager.logs[index].level.index==0?Colors.white:Colors.black),),
                              ),
                            ),
                          ],
                        ),
                        Text(LogManager.logs[index].content),
                        Text(LogManager.logs[index].time.toString().replaceAll(RegExp(r"\.\w+"), "")),
                        MiuixTextButton("复制".tl, onPressed: (){
                          Clipboard.setData(ClipboardData(text: LogManager.logs[index].content));
                        }),
                        const MiuixHorizontalDivider(),
                      ],
                    ),
                  ),
                );
              },
              childCount: LogManager.logs.length,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
          )
        ],
      ),
    );
  }
}
