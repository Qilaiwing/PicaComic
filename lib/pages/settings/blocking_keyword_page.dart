part of pica_settings;

class BlockingKeywordPageLogic extends StateController {
  var keywords = appdata.blockingKeyword;
  bool down = true;
  final controller = TextEditingController();
}

class BlockingKeywordPage extends StatelessWidget {
  BlockingKeywordPage({this.popUp = false, Key? key}) : super(key: key) {
    StateController.put(BlockingKeywordPageLogic());
  }

  final bool popUp;

  @override
  Widget build(BuildContext context) {
    var addButton = MiuixTooltipBox(
 tooltip: (_, scope) => MiuixPlainTooltip(scope: scope, child: Text("添加".tl)),
 child: MiuixIconButton(onPressed: () {
          showMiuixDialog(
            context: context,
            title: "添加屏蔽关键词".tl,
            contentBuilder: (dialogContext, close) =>
                StateBuilder<BlockingKeywordPageLogic>(
              builder: (logic) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MiuixTextField(
                    controller: logic.controller,
                    label: "添加关键词".tl,
                    useLabelAsPlaceholder: true,
                    singleLine: true,
                    onSubmitted: (_) {
                      if (logic.controller.text == "") return;
                      appdata.blockingKeyword.add(logic.controller.text);
                      logic.update();
                      close();
                      logic.controller.text = "";
                      appdata.writeData();
                    },
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  MiuixButton(
                    colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                    child: Text("提交".tl,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () {
                      if (logic.controller.text == "") return;
                      appdata.blockingKeyword.add(logic.controller.text);
                      logic.update();
                      close();
                      logic.controller.text = "";
                      appdata.writeData();
                    },
                  )
                ],
              ),
            ),
          );
        }, child: const Icon(Icons.add)),
);

    var orderButton = StateBuilder<BlockingKeywordPageLogic>(
      builder: (logic) {
        return MiuixTooltipBox(
 tooltip: (_, scope) => MiuixPlainTooltip(scope: scope, child: Text("显示顺序")),
 child: MiuixIconButton(onPressed: () {
              logic.down = !logic.down;
              logic.update();
            }, child: logic.down
                ? const Icon(Icons.arrow_downward)
                : const Icon(Icons.arrow_upward)),
);
      },
    );

    var widget = StateBuilder<BlockingKeywordPageLogic>(builder: (logic) {
      var keywords = logic.down
          ? appdata.blockingKeyword
          : appdata.blockingKeyword.reversed.toList();
      return ListView.builder(
        itemCount: keywords.length + 1,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          if (index == 0) {
            return appdata.firstUse[0] == "1"
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Container(
                      decoration: ShapeDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        shape: const MiuixSquircleBorder(cornerRadius: 16),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "关键词屏蔽不会生效于收藏夹和历史记录, 屏蔽依据仅限漫画列表信息".tl,
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          MiuixIconButton(onPressed: () {
                              appdata.firstUse[0] = "0";
                              appdata.writeData();
                              logic.update();
                            }, child: const Icon(Icons.close, size: 18)),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(height: 8);
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: ShapeDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1C1C1E)
                      : Colors.white,
                  shape: const MiuixSquircleBorder(cornerRadius: 14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        keywords[index - 1],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    MiuixIconButton(onPressed: () {
                        logic.keywords.remove(keywords[index - 1]);
                        logic.update();
                        appdata.writeData();
                      }, child: Icon(
                        Icons.close,
                        size: 20,
                        color: Theme.of(context).colorScheme.outline,
                      )),
                  ],
                ),
              ),
            );
          }
        },
      );
    });

    return PopUpWidgetScaffold(
      title: "关键词屏蔽".tl,
      body: widget,
      tailing: [addButton, orderButton],
    );
  }
}
