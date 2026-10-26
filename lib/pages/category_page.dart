import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/pages/ranking_page.dart';
import 'package:pica_comic/pages/search_result_page.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/pages/category_comics_page.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/translations.dart';

class CategoryPageController extends StateController {
  List<String> categories = [];
  late TabController tabController;

  void init(TickerProvider vsync) {
    categories = appdata.appSettings.categoryPages;
    var allCategories = ComicSource.sources
        .map((e) => e.categoryData?.key)
        .where((element) => element != null)
        .map((e) => e!)
        .toList();
    categories =
        categories.where((element) => allCategories.contains(element)).toList();
    tabController = TabController(length: categories.length, vsync: vsync);
  }
}

class AllCategoryPage extends StatelessWidget {
  const AllCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logic = StateController.find<CategoryPageController>();
    return Material(
      color: Colors.transparent,
      child: TabBarView(
        controller: logic.tabController,
        children: logic.categories.map((e) => CategoryPage(e)).toList(),
      ),
    );
  }
}

typedef ClickTagCallback = void Function(String, String?);

class CategoryPage extends StatelessWidget {
  const CategoryPage(this.category, {super.key});

  final String category;

  CategoryData get data => getCategoryDataWithKey(category);

  String findComicSourceKey() {
    for (var source in ComicSource.sources) {
      if (source.categoryData?.key == category) {
        return source.key;
      }
    }
    return "";
  }

  void handleClick(
    String tag,
    String? param,
    String type,
    String namespace,
    String categoryKey,
  ) {
    if (type == 'search') {
      App.mainNavigatorKey?.currentContext?.to(
        () => SearchResultPage(
          keyword: tag,
          options: const [],
          sourceKey: findComicSourceKey(),
        ),
      );
    } else if (type == "search_with_namespace") {
      if (tag.contains(" ")) {
        tag = '"$tag"';
      }
      App.mainNavigatorKey?.currentContext?.to(
        () => SearchResultPage(
          keyword: "$namespace:$tag",
          options: const [],
          sourceKey: findComicSourceKey(),
        ),
      );
    } else if (type == "category") {
      App.mainNavigatorKey!.currentContext!.to(
        () => CategoryComicsPage(
          category: tag,
          categoryKey: categoryKey,
          param: param,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    if (data.enableRankingPage || data.buttons.isNotEmpty) {
      children.add(
        _CategoryGroupCard(
          title: "热门推荐".tl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
            child: Wrap(
              children: [
                if (data.enableRankingPage)
                  buildTag("排行榜".tl, (p0, p1) {
                    context
                        .to(() => RankingPage(sourceKey: findComicSourceKey()));
                  }),
                for (var buttonData in data.buttons)
                  buildTag(buttonData.label.tl, (p0, p1) => buttonData.onTap())
              ],
            ),
          ),
        ),
      );
    }

    for (var part in data.categories) {
      if (part.enableRandom) {
        children.add(StatefulBuilder(builder: (context, updater) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTitleWithRefresh(part.title, () => updater(() {})),
              buildTagsWithParams(
                part.categories,
                part.categoryParams,
                part.title,
                (key, param) => handleClick(
                  key,
                  param,
                  part.categoryType,
                  part.title,
                  category,
                ),
              )
            ],
          );
        }));
      } else {
        children.add(
          _CategoryGroupCard(
            title: part.title,
            child: buildTagsWithParams(
              part.categories,
              part.categoryParams,
              part.title,
              (tag, param) => handleClick(
                tag,
                param,
                part.categoryType,
                part.title,
                data.key,
              ),
            ),
          ),
        );
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Text(
        title.tl,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget buildTitleWithRefresh(String title, void Function() onRefresh) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 6),
      child: Row(
        children: [
          Text(
            title.tl,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          MiuixIconButton(
            onPressed: onRefresh,
            child: const Icon(Icons.refresh, size: 20),
          )
        ],
      ),
    );
  }

  Widget buildTagsWithParams(
    List<String> tags,
    List<String>? params,
    String? namespace,
    ClickTagCallback onClick,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      child: Wrap(
        children: List<Widget>.generate(
          tags.length,
          (index) => buildTag(
            tags[index],
            onClick,
            namespace,
            params?.elementAtOrNull(index),
          ),
        ),
      ),
    );
  }

  Widget buildTag(String tag, ClickTagCallback onClick,
      [String? namespace, String? param]) {
    String translateTag(String tag) {
      if (enableTranslation) {
        if (namespace != null) {
          tag = TagsTranslation.translationTagWithNamespace(tag, namespace);
        } else {
          tag = tag.translateTagsToCN;
        }
      }
      return tag;
    }

    final isDark = Theme.of(App.globalContext!).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 4, 5, 4),
      child: MiuixPressable(
          shape: const MiuixSquircleBorder(cornerRadius: 12),
          onPressed: () => onClick(tag, param),
          child: Container(
            decoration: ShapeDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F4),
              shape: MiuixSquircleBorder(
                cornerRadius: 12,
                side: BorderSide(
                  color: isDark
                      ? const Color(0x18FFFFFF)
                      : const Color(0x0C000000),
                  width: 0.6,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              translateTag(tag),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          )),
    );
  }

  bool get enableTranslation => App.locale.languageCode == 'zh';
}

class _CategoryGroupCard extends StatelessWidget {
  const _CategoryGroupCard({
    required this.title,
    required this.child,
    this.onRefresh,
  });

  final String title;
  final Widget child;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(
        shape: MiuixSquircleBorder(
          cornerRadius: 18,
          side: BorderSide(
            color: isDark ? const Color(0x18FFFFFF) : const Color(0x0A000000),
            width: 0.6,
          ),
        ),
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
            child: Row(
              children: [
                Text(
                  title.tl,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                if (onRefresh != null)
                  MiuixIconButton(
                    onPressed: onRefresh,
                    minWidth: 32,
                    minHeight: 32,
                    child: const Icon(Icons.refresh, size: 18),
                  ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}
