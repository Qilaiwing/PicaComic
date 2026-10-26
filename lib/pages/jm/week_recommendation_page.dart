import 'package:flutter/material.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';

class JWRPLogic extends StateController {
  bool loading = true;
  Map<String, String>? rec;
  String? message;
  String currentName = "";
  String currentId = "";

  void change() {
    loading = !loading;
    update();
  }

  void get() async {
    rec = null;
    message = null;
    var res = await JmNetwork().getWeekRecommendation();
    if (res.error) {
      message = res.errorMessage;
    } else {
      rec = res.data;
      currentName = rec!.values.first;
      currentId = rec!.keys.first;
    }
    loading = false;
    update();
  }
}

class JmWeekRecommendationPage extends StatelessWidget {
  JmWeekRecommendationPage({Key? key}) : super(key: key);
  final logic = StateController.put(JWRPLogic());

  @override
  Widget build(BuildContext context) {
    final menuKey = GlobalKey();
    return StateBuilder<JWRPLogic>(builder: (logic) {
      return MiuixScaffold(
        topBar: MiuixSmallTopAppBar(
          title: "每周必看".tl,
          subtitle: logic.currentName,
          navigationIcon: MiuixIconButton(
            child: MiuixIcon(vector: MiuixIcons.os4.chevronBackward, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            MiuixIconButton(
              key: menuKey,
              child: const Icon(Icons.calendar_month_outlined, size: 22),
              onPressed: () {
                if (logic.rec == null) return;
                showMiuixMenu(
                  context: context,
                  anchorBounds: miuixAnchorRectOf(menuKey.currentContext!),
                  maxHeight: 300,
                  items: [for (var item in logic.rec!.entries) item.value],
                ).then((i) {
                  if (i == null) return;
                  var item = logic.rec!.entries.elementAt(i);
                  logic.currentId = item.key;
                  logic.currentName = item.value;
                  logic.update();
                });
              },
            ),
          ],
        ),
        content: (padding) => ScrollUnderBar(
          padding: EdgeInsets.only(top: padding.top),
          child: Builder(builder: (context) {
            if (logic.loading) {
              logic.get();
              return const Center(child: MiuixInfiniteProgressIndicator());
            } else if (logic.message != null) {
              return TopInsetPadding(
                child: NetworkError(
                  message: logic.message!,
                  retry: () {
                    logic.change();
                    logic.get();
                  },
                  withAppbar: false,
                ),
              );
            }
            return WeekRecommendationList(
              logic.currentId,
              key: Key(logic.currentId),
            );
          }),
        ),
      );
    });
  }
}

class WRLLogic extends StateController {
  var comics = <List<JmComicBrief>>[[], [], []];
  var messages = <String?>[null, null, null];
  var loading = <bool>[true, true, true];

  void get(int index, String id) async {
    var res = await JmNetwork()
        .getWeekRecommendationComics(id, WeekRecommendationType.values[index]);
    if (res.error) {
      messages[index] = res.errorMessage;
    } else {
      comics[index] = res.data;
    }
    loading[index] = false;
    update();
  }

  void retry(int index, String id) {
    loading[index] = true;
    messages[index] = null;
    update();
    get(index, id);
  }
}

class WeekRecommendationList extends StatefulWidget {
  const WeekRecommendationList(this.id, {Key? key}) : super(key: key);
  final String id;

  @override
  State<WeekRecommendationList> createState() => _WeekRecommendationListState();
}

class _WeekRecommendationListState extends State<WeekRecommendationList> {
  String get id => widget.id;

  static const _kTabRowHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final inset = MainTopInset.of(context);
    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          Positioned.fill(
            child: MainTopInset(
              height: inset + _kTabRowHeight,
              child: StateBuilder<WRLLogic>(
                init: WRLLogic(),
                tag: id,
                builder: (logic) => TabBarView(
                  children: [
                    for (int i = 0; i <= 2; i++) buildPage(i, logic, context)
                  ],
                ),
              ),
            ),
          ),
          // Tab 条与顶栏同一块毛玻璃，列表从两者下方穿过。
          Positioned(
            top: inset,
            left: 0,
            right: 0,
            child: FrostedBackground(
              child: SizedBox(
                height: _kTabRowHeight,
                child: Center(
                  child: FilledTabBar(tabs: [
                    Tab(text: "韩漫".tl),
                    Tab(text: "日漫".tl),
                    Tab(text: "其它".tl),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPage(int index, WRLLogic logic, BuildContext context) {
    if (logic.loading[index]) {
      logic.get(index, id);
      return const Center(child: MiuixInfiniteProgressIndicator());
    } else if (logic.comics[index].isEmpty) {
      return TopInsetPadding(
        child: NetworkError(
          message: logic.messages[index] ?? "未知错误".tl,
          retry: () => logic.retry(index, id),
          withAppbar: false,
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        const TopInsetSliver(),
        SliverGridComics(comics: logic.comics[index], sourceKey: "jm"),
        SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).bottom + 16)),
      ],
    );
  }
}
