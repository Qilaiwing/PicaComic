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
    var key = GlobalKey();
    const titleLength = 190;
    return MiuixScaffold(
      topBar: Appbar(
        title: Text("每周必看".tl),
        actions: [
          StateBuilder<JWRPLogic>(
            builder: (logic) => Container(
              key: key,
              margin: const EdgeInsets.all(5),
              padding: const EdgeInsets.all(5),
              width: MediaQuery.of(context).size.width > 250 + titleLength
                  ? 250
                  : MediaQuery.of(context).size.width - titleLength,
              height: 40,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.all(Radius.circular(16))),
              child: Row(
                children: [
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      logic.currentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  MiuixIconButton(
                    child: const Icon(Icons.arrow_drop_down_sharp, size: 16),
                    onPressed: () {
                      if (logic.rec == null) return;
                      showMiuixMenu(
                        context: context,
                        anchorBounds: miuixAnchorRectOf(key.currentContext!),
                        maxHeight: 300,
                        items: [
                          for (var item in logic.rec!.entries) item.value
                        ],
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
            ),
          )
        ],
      ),
      content: (padding) => Column(
        children: [
          SizedBox(height: padding.top),
          Expanded(
            child: StateBuilder<JWRPLogic>(
              builder: (logic) {
                if (logic.loading) {
                  logic.get();
                  return const Center(
                    child: MiuixInfiniteProgressIndicator(),
                  );
                } else if (logic.message != null) {
                  return NetworkError(
                    message: logic.message!,
                    retry: () {
                      logic.change();
                      logic.get();
                    },
                  );
                } else {
                  return WeekRecommendationList(
                    logic.currentId,
                    key: Key(logic.currentId),
                  );
                }
              },
            ),
          )
        ],
      ),
    );
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
  int _tabIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MiuixTabRow(
          tabs: ["韩漫".tl, "日漫".tl, "其它".tl],
          selectedTabIndex: _tabIndex,
          onTabSelected: (i) {
            setState(() => _tabIndex = i);
            _pageController.animateToPage(i,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut);
          },
        ).paddingHorizontal(12),
        Expanded(
            child: StateBuilder<WRLLogic>(
                init: WRLLogic(),
                tag: id,
                builder: (logic) {
                  return PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _tabIndex = i),
                    children: [
                      for (int i = 0; i <= 2; i++) buildPage(i, logic, context)
                    ],
                  );
                }))
      ],
    );
  }

  Widget buildPage(int index, WRLLogic logic, BuildContext context) {
    if (logic.loading[index]) {
      logic.get(index, id);
      return const Center(
        child: MiuixInfiniteProgressIndicator(),
      );
    } else if (logic.comics[index].isEmpty) {
      return NetworkError(
        message: logic.messages[index] ?? "未知错误".tl,
        retry: () => logic.retry(index, id),
      );
    } else {
      return CustomScrollView(
        slivers: [
          SliverGridComics(comics: logic.comics[index], sourceKey: "jm"),
        ],
      );
    }
  }
}
