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
  Widget build(BuildContext context) {
    search();
    return Material(
      child: Column(
        children: [
          SizedBox(
            height:
            UiMode.m1(context) ? MediaQuery.of(context).padding.top : null,
          ),
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 0.8))),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Tooltip(
                    message: "返回".tl,
                    child: Material(
                      color: Colors.transparent,
                      shape: const MiuixSquircleBorder(cornerRadius: 12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => App.back(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: ShapeDecoration(
                            shape: const MiuixSquircleBorder(cornerRadius: 12),
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? const Color(0x18FFFFFF)
                                : const Color(0x0A000000),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Theme.of(context).brightness ==
                                    Brightness.dark
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFF222222),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
                  Tooltip(
                    message: "clear",
                    child: IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        controller.clear();
                        setState(() {
                          keyword = "";
                        });
                      },
                    ),
                  ),
                if (comics.isNotEmpty)
                  Tooltip(
                    message: "create folder",
                    child: IconButton(
                      icon: const Icon(Icons.create_new_folder_outlined),
                      onPressed: () {
                        showConfirmDialog(
                          App.globalContext!,
                          "创建收藏夹".tl,
                          "从当前的搜索结果创建新的收藏夹".tl,
                              () {
                            var name = LocalFavoritesManager()
                                .createFolder("search result", true);
                            for (var comic in comics) {
                              LocalFavoritesManager().addComic(name, comic.comic);
                            }
                            StateController.findOrNull<FavoritesPageController>()
                                ?.update();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
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
          )
        ],
      ),
    );
  }

  @override
  Object? get tag => "local_search_page";
}
