import 'package:flutter/material.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/tools/time.dart';
import 'package:pica_comic/foundation/history.dart';
import '../base.dart';
import '../foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final comics = HistoryManager().getAll();
  bool searchInit = false;
  bool searchMode = false;
  String keyword = "";
  var results = <History>[];
  bool isModified = false;

  @override
  void dispose() {
    if (isModified) {
      appdata.history.saveData();
    }
    super.dispose();
  }

  Widget buildTitle() {
    if (searchMode) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Transform.translate(
        offset: const Offset(12, 6.0),
        child: Container(
          height: 38,
          margin: const EdgeInsets.only(right: 20),
          decoration: ShapeDecoration(
            shape: const MiuixSquircleBorder(cornerRadius: 19),
            color: isDark ? const Color(0x26FFFFFF) : const Color(0x10000000),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              MiuixIcon(
                vector: MiuixIcons.os4.search,
                size: 17,
                tint: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  autofocus: searchInit,
                  controller: TextEditingController(text: keyword)
                    ..selection = TextSelection.collapsed(offset: keyword.length),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: "搜索历史记录".tl,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (s) {
                    setState(() {
                      keyword = s.toLowerCase();
                      searchInit = false;
                    });
                  },
                ),
              ),
              if (keyword.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      keyword = "";
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: MiuixIcon(
                      vector: MiuixIcons.os4.close,
                      size: 16,
                      tint: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      return Text("${"历史记录".tl} (${comics.length})");
    }
  }

  void find() {
    results.clear();
    if (keyword == "") {
      results.addAll(comics);
    } else {
      for (var element in comics) {
        if (element.title.toLowerCase().contains(keyword) ||
            element.subtitle.toLowerCase().contains(keyword)) {
          results.add(element);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (searchMode) {
      find();
    }
    return Scaffold(
      body: SmoothCustomScrollView(
        slivers: [
          SliverAppbar(
            title: buildTitle(),
            largeTitle: searchMode ? null : Text("${"历史记录".tl} (${comics.length})"),
            actions: [
              if (!searchMode)
                Tooltip(
                  message: "清除".tl,
                  child: MiuixIconButton(
                    child: MiuixIcon(
                      vector: MiuixIcons.extended.byName('delete') ?? MiuixIcons.os4.close,
                      size: 20,
                    ),
                    onPressed: () => showConfirmDialog(
                      context,
                      "清除记录".tl,
                      "要清除历史记录吗?".tl,
                      () {
                        appdata.history.clearHistory();
                        setState(() => comics.clear());
                        isModified = true;
                      },
                    ),
                  ),
                ),
              Tooltip(
                message: searchMode ? "关闭搜索".tl : "搜索".tl,
                child: MiuixIconButton(
                  child: MiuixIcon(
                    vector: searchMode ? MiuixIcons.os4.close : MiuixIcons.os4.search,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      searchMode = !searchMode;
                      searchInit = true;
                      if (!searchMode) {
                        keyword = "";
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          if (!searchMode) buildComics(comics) else buildComics(results),
          SliverPadding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).padding.bottom),
          )
        ],
      ),
    );
  }

  Widget buildComics(List<History> comics_) {
    return SliverGrid(
      delegate:
          SliverChildBuilderDelegate(childCount: comics_.length, (context, i) {
        final comic = ComicItemBrief(
          comics_[i].title,
          comics_[i].subtitle,
          0,
          comics_[i].cover != ""
              ? comics_[i].cover
              : getJmCoverUrl(comics_[i].target),
          comics_[i].target,
          [],
        );
        return NormalComicTile(
          key: Key(comics_[i].target),
          sourceKey: comics_[i].type.comicSource?.key,
          onLongTap: () {
            showMiuixDialog(context: context, title: "删除".tl, summary: "要删除这条历史记录吗".tl, actionsBuilder: (context, close) => [
                      MiuixTextButton("取消".tl, onPressed: () => close()),
                      MiuixTextButton("删除".tl, onPressed: () {
                            appdata.history.remove(comics_[i].target);
                            setState(() {
                              isModified = true;
                              comics.removeWhere((element) =>
                                  element.target == comics_[i].target);
                            });
                            close();
                          }),
                    ]);
          },
          description_: timeToString(comics_[i].time),
          coverPath: comic.path,
          name: comic.title,
          subTitle_: comic.author,
          badgeName: comics_[i].type.name,
          headers: {
            if (comics_[i].type == HistoryType.ehentai)
              "cookie": EhNetwork().cookiesStr,
            if (comics_[i].type == HistoryType.ehentai ||
                comics_[i].type == HistoryType.hitomi)
              "User-Agent": webUA,
            if (comics_[i].type == HistoryType.hitomi)
              "Referer": "https://hitomi.la/"
          },
          onTap: () {
            toComicPageWithHistory(context, comics_[i]);
          },
        );
      }),
      gridDelegate: SliverGridDelegateWithComics(),
    );
  }
}

void toComicPageWithHistory(BuildContext context, History history) {
  var source = history.type.comicSource;
  if (source == null) {
    showToast(message: "Comic Source Not Found");
    return;
  }
  context.to(
    () => ComicPage(
      sourceKey: source.key,
      id: history.target,
      cover: history.cover,
    ),
  );
}
