import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';
import '../../foundation/app.dart';
import '../../foundation/local_favorites.dart';
import 'local_favorites.dart';
import 'main_favorites_page.dart';

class LocalSearchPage extends StatefulWidget {
  /// Search page for local favorites
  const LocalSearchPage({super.key});

  @override
  State<LocalSearchPage> createState() => _LocalSearchPageState();
}

class _LocalSearchPageState extends StateWithController<LocalSearchPage> {
  var comics = <FavoriteItemWithFolderInfo>[];

  String keyword = "";

  final controller = TextEditingController();

  final _focusNode = FocusNode();

  void search() {
    if (keyword.isEmpty) {
      comics = [];
    } else {
      comics = LocalFavoritesManager().search(keyword);
    }
  }

  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 200), _focusNode.requestFocus);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    search();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final topPad = UiMode.m1(context) ? MediaQuery.of(context).padding.top : 0.0;

    return MiuixScaffold(
      content: (_) => Column(
        children: [
          SizedBox(height: topPad),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                MiuixTooltipBox(
                  tooltip: (_, scope) =>
                      MiuixPlainTooltip(scope: scope, child: Text("返回".tl)),
                  child: MiuixPressable(
                    onPressed: () => App.back(context),
                    feedbackType: MiuixPressFeedbackType.sink,
                    shape: const MiuixSquircleBorder(cornerRadius: 12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: ShapeDecoration(
                        shape: const MiuixSquircleBorder(cornerRadius: 12),
                        color: isDark
                            ? const Color(0x18FFFFFF)
                            : const Color(0x0A000000),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: isDark
                            ? Colors.white.withOpacity(0.9)
                            : const Color(0xFF222222),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: ShapeDecoration(
                      shape: MiuixSquircleBorder(
                        cornerRadius: 14,
                        side: BorderSide(
                          color: isDark
                              ? const Color(0x18FFFFFF)
                              : const Color(0x0A000000),
                          width: 0.6,
                        ),
                      ),
                      color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                      shadows: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: primary.withOpacity(0.85),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: MiuixTextField(
                            focusNode: _focusNode,
                            controller: controller,
                            label: "Search",
                            useLabelAsPlaceholder: true,
                            singleLine: true,
                            insideMargin: EdgeInsets.zero,
                            colors: MiuixTextFieldColors(
                              backgroundColor: Colors.transparent,
                              labelColor: Theme.of(context).hintColor,
                              borderColor: Colors.transparent,
                            ),
                            onSubmitted: (s) => search(),
                            onChanged: (s) => setState(() {
                              keyword = s;
                            }),
                          ),
                        ),
                        if (keyword.isNotEmpty)
                          MiuixTooltipBox(
                            tooltip: (_, scope) => MiuixPlainTooltip(
                                scope: scope, child: const Text("clear")),
                            child: MiuixIconButton(
                              onPressed: () {
                                controller.clear();
                                setState(() {
                                  keyword = "";
                                });
                              },
                              child: const Icon(Icons.clear_rounded, size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (comics.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  MiuixTooltipBox(
                    tooltip: (_, scope) => MiuixPlainTooltip(
                        scope: scope, child: const Text("create folder")),
                    child: MiuixPressable(
                      onPressed: () {
                        showConfirmDialog(
                          App.globalContext!,
                          "创建收藏夹".tl,
                          "从当前的搜索结果创建新的收藏夹".tl,
                          () {
                            var name = LocalFavoritesManager()
                                .createFolder("search result", true);
                            for (var comic in comics) {
                              LocalFavoritesManager()
                                  .addComic(name, comic.comic);
                            }
                            StateController.findOrNull<
                                    FavoritesPageController>()
                                ?.update();
                          },
                        );
                      },
                      feedbackType: MiuixPressFeedbackType.sink,
                      shape: const MiuixSquircleBorder(cornerRadius: 12),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: ShapeDecoration(
                          shape: const MiuixSquircleBorder(cornerRadius: 12),
                          color: primary.withOpacity(isDark ? 0.22 : 0.12),
                        ),
                        child: Icon(
                          Icons.create_new_folder_outlined,
                          size: 20,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: comics.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        keyword.isEmpty
                            ? "输入关键词搜索本地收藏".tl
                            : "没有匹配的收藏".tl,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).hintColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : GridView.builder(
                    primary: false,
                    gridDelegate: SliverGridDelegateWithComics(),
                    itemCount: comics.length,
                    padding: EdgeInsets.zero,
                    itemBuilder: (BuildContext context, int index) {
                      return LocalFavoriteTile(
                        comics[index].comic,
                        comics[index].folder,
                        () => setState(() {}),
                        true,
                        showFolderInfo: true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Object? get tag => "local_search_page";
}
