import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/pair.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/tools/translations.dart';

class _SearchPageComicList extends ComicsPage<BaseComic> {
  const _SearchPageComicList({
    super.key,
    required this.keyword,
    required this.options,
    required this.header,
    required this.sourceKey,
  });

  final String keyword;

  final List<String> options;

  @override
  final String sourceKey;

  @override
  final Widget header;

  @override
  Future<Res<List<BaseComic>>> getComics(int i) async {
    var loader = ComicSource.find(sourceKey)!.searchPageData!.loadPage!;
    return await loader(keyword, i, options);
  }

  @override
  String? get tag => "$sourceKey search page with $keyword";

  @override
  String? get title => null;
}

class SearchResultPage extends StatelessWidget {
  const SearchResultPage({
    super.key,
    required this.keyword,
    this.options = const [],
    required this.sourceKey,
  });

  final String keyword;

  final List<String> options;

  final String sourceKey;

  @override
  Widget build(BuildContext context) {
    var comicSource =
        ComicSource.find(sourceKey) ?? (throw "source $sourceKey not found");
    var options = this.options;
    if (comicSource.searchPageData?.searchOptions != null) {
      var searchOptions = comicSource.searchPageData!.searchOptions!;
      if (searchOptions.length != options.length) {
        options = searchOptions.map((e) => e.defaultValue).toList();
      }
    }
    if (comicSource.searchPageData?.overrideSearchResultBuilder != null) {
      return comicSource.searchPageData!.overrideSearchResultBuilder!(
        keyword,
        options,
      );
    } else {
      return _SearchResultPage(
        keyword: keyword,
        options: options,
        sourceKey: sourceKey,
      );
    }
  }
}

class _SearchResultPage extends StatefulWidget {
  const _SearchResultPage({
    required this.keyword,
    required this.options,
    required this.sourceKey,
  });

  final String keyword;

  final List<String> options;

  final String sourceKey;

  @override
  State<_SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<_SearchResultPage> {
  var controller = SearchChipController();
  bool _showFab = true;
  late String keyword = widget.keyword;

  OverlayEntry? get suggestionOverlay => suggestionsController.entry;
  late _SuggestionsController suggestionsController;
  late var sourceKey = widget.sourceKey;
  late var options = widget.options;

  @override
  void initState() {
    controller.applyQuery(keyword);
    if (!keyword.contains('language') &&
        ComicSource.find(sourceKey)?.searchPageData?.enableLanguageFilter ==
            true) {
      var lang = int.tryParse(appdata.settings[69]) ?? 0;
      if (lang != 0) {
        keyword += " language:${["chinese", "english", "japanese"][lang - 1]}";
      }
    }
    suggestionsController = _SuggestionsController(controller);
    super.initState();
  }

  @override
  void dispose() {
    if (suggestionOverlay != null) {
      suggestionsController.remove();
    }
    super.dispose();
  }

  void onChanged(String s) {
    suggestionsController.sourceKey = sourceKey;
    suggestionsController.findSuggestions();
    if (suggestionOverlay != null) {
      if (suggestionsController.suggestions.isEmpty) {
        suggestionsController.remove();
      } else {
        suggestionsController.updateWidget();
      }
    } else if (suggestionsController.suggestions.isNotEmpty) {
      suggestionsController.entry = OverlayEntry(
        builder: (context) {
          return Positioned(
            top: context.padding.top + 56 + 16,
            left: 0,
            right: 0,
            bottom: 0,
            child: MiuixScaffold(
              content: (_) => _Suggestions(
                controller: suggestionsController,
              ),
            ),
          );
        },
      );
      Overlay.of(context).insert(suggestionOverlay!);
    }
  }

  void update() {
    if (controller.query != keyword) {
      setState(() {
        keyword = controller.query;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget trailing;
    if (context.width < 400) {
      trailing = MiuixIconButton(
        minWidth: 36,
        minHeight: 36,
        onPressed: more,
        child: MiuixIcon(vector: MiuixIcons.os4.more, size: 20),
      );
    } else {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiuixIconButton(
            minWidth: 36,
            minHeight: 36,
            onPressed: changeSource,
            child: MiuixIcon(
              vector: MiuixIcons.extended.byName('all') ??
                  MiuixIcons.os4.settings,
              size: 20,
            ),
          ),
          MiuixIconButton(
            minWidth: 36,
            minHeight: 36,
            onPressed: showSearchOptions,
            child: MiuixIcon(vector: MiuixIcons.os4.filter, size: 20),
          ),
        ],
      );
    }

    return MiuixScaffold(
 floatingActionButton: _showFab
          ? Container(
              width: 54,
              height: 54,
              decoration: ShapeDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: const MiuixSquircleBorder(cornerRadius: 18),
                shadows: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.38),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MiuixPressable(
                onPressed: () {
                  // Short-tap: search immediately (do not open 切换源 menu).
                  final s = controller.commitPending();
                  setState(() {
                    keyword = s;
                  });
                },
                onLongPress: more,
                feedbackType: MiuixPressFeedbackType.sink,
                child: Center(
                  child: MiuixIcon(
                    vector: MiuixIcons.basic.search,
                    size: 24,
                    tint: Colors.white,
                  ),
                ),
              ),
            )
          : null,
 content: (_) => NotificationListener<ScrollUpdateNotification>(
        onNotification: (notification) {
          if (suggestionsController.entry != null) {
            suggestionsController.remove();
          }
          final ScrollDirection direction = notification.scrollDelta! < 0
              ? ScrollDirection.forward
              : ScrollDirection.reverse;
          var showFab = _showFab;
          if (direction == ScrollDirection.reverse) {
            _showFab = false;
          } else if (direction == ScrollDirection.forward) {
            _showFab = true;
          }
          if (_showFab == showFab) return true;
          setState(() {});
          return false;
        },
        child: _SearchPageComicList(
          keyword: keyword,
          sourceKey: sourceKey,
          key: Key(keyword + options.toString() + sourceKey),
          header: SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 56,
              maxHeight: 56,
              child: FrostedBackground(child: FloatingSearchBar(
                onSearch: (s) {
                  suggestionsController.suggestions.clear();
                  suggestionsController.remove();
                  if (s == keyword) return;
                  setState(() {
                    keyword = s;
                  });
                },
                controller: controller,
                onChanged: onChanged,
                trailing: trailing,
              )),
            ),
          ),
          options: options,
        ),
      ),
);
  }

  void more() async {
    final value = await showMiuixMenu(
      context: context,
      anchorBounds: Rect.fromLTWH(MediaQuery.of(context).size.width - 48, 56, 0, 0),
      alignment: MiuixPopupAlign.end,
      items: ["切换源".tl, "搜索选项".tl],
    );
    if (value == 0) {
      changeSource();
    } else if (value == 1) {
      showSearchOptions();
    }
  }

  void changeSource() async {
    var sources = ComicSource.sources.where((e) => e.searchPageData != null);
    String? sourceKey = this.sourceKey;
    final confirmed = await showMiuixDialog<bool>(
      context: context,
      title: "切换源".tl,
      contentBuilder: (context, close) {
        return StatefulBuilder(builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var source in sources)
                MiuixRadioButtonPreference(
                  title: source.name,
                  selected: sourceKey == source.key,
                  onClick: () {
                    setState(() {
                      sourceKey = source.key;
                    });
                  },
                )
            ],
          );
        });
      },
      actionsBuilder: (context, close) => [
        MiuixButton(
          colors: MiuixButtonDefaults.buttonColorsPrimary(context),
          child: Text("确认".tl),
          onPressed: () {
            if (sourceKey != null) {
              close(true);
            }
          },
        )
      ],
    );
    // 导航在弹窗关闭后执行
    if (confirmed != true || sourceKey == null || !mounted) return;
    var searchData = ComicSource.find(sourceKey!)!.searchPageData!;
    options =
        (searchData.searchOptions ?? []).map((e) => e.defaultValue).toList();
    if (searchData.overrideSearchResultBuilder != null) {
      context.off(() {
        return SearchResultPage(
          keyword: keyword,
          options: options,
          sourceKey: sourceKey!,
        );
      });
    } else {
      setState(() {
        this.sourceKey = sourceKey!;
      });
    }
  }

  void showSearchOptions() {
    showMiuixDialog(
      context: context,
      title: "搜索选项".tl,
      contentBuilder: (context, close) => _SearchOptions(
        current: options,
        sourceKey: sourceKey,
        close: () => close(),
        onChanged: (options) {
          setState(() {
            this.options = options;
          });
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(
      {required this.child, required this.maxHeight, required this.minHeight});

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: child,
    );
  }

  @override
  double get maxExtent => minHeight;

  @override
  double get minExtent => max(maxHeight, minHeight);

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent ||
        minHeight != oldDelegate.minExtent;
  }
}

class _SuggestionsController {
  _SuggestionsState? _state;

  final TextEditingController controller;

  OverlayEntry? entry;

  void updateWidget() {
    _state?.update();
  }

  void remove() {
    entry?.remove();
    entry = null;
  }

  var suggestions = <Pair<String, TranslationType>>[];

  String sourceKey = '';

  void findSuggestions() {
    var text = controller.text.split(" ").last;
    var suggestions = this.suggestions;

    suggestions.clear();
    if (ComicSource.find(sourceKey)?.searchPageData?.enableTagsSuggestions !=
        true) {
      return;
    }

    bool check(String text, String key, String value) {
      if (text.removeAllBlank == "") {
        return false;
      }
      if (key.length >= text.length && key.substring(0, text.length) == text ||
          (key.contains(" ") &&
              key.split(" ").last.length >= text.length &&
              key.split(" ").last.substring(0, text.length) == text)) {
        return true;
      } else if (value.length >= text.length && value.contains(text)) {
        return true;
      }
      return false;
    }

    void find(Map<String, String> map, TranslationType type) {
      for (var element in map.entries) {
        if (suggestions.length > 200) {
          break;
        }
        if (check(text, element.key, element.value)) {
          suggestions.add(Pair(element.key, type));
        }
      }
    }

    find(TagsTranslation.femaleTags, TranslationType.female);
    find(TagsTranslation.maleTags, TranslationType.male);
    find(TagsTranslation.parodyTags, TranslationType.parody);
    find(TagsTranslation.characterTranslations, TranslationType.character);
    find(TagsTranslation.otherTags, TranslationType.other);
    find(TagsTranslation.mixedTags, TranslationType.mixed);
    find(TagsTranslation.languageTranslations, TranslationType.language);
    find(TagsTranslation.artistTags, TranslationType.artist);
    find(TagsTranslation.groupTags, TranslationType.group);
    find(TagsTranslation.cosplayerTags, TranslationType.cosplayer);
  }

  _SuggestionsController(this.controller);
}

class _Suggestions extends StatefulWidget {
  const _Suggestions({required this.controller});

  final _SuggestionsController controller;

  @override
  State<_Suggestions> createState() => _SuggestionsState();
}

class _SuggestionsState extends State<_Suggestions> {
  void update() {
    setState(() {});
  }

  @override
  void initState() {
    widget.controller._state = this;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _Suggestions oldWidget) {
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._state = null;
      widget.controller._state = this;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return buildSuggestions(context);
  }

  Widget buildSuggestions(BuildContext context) {
    bool showMethod = MediaQuery.of(context).size.width < 600;
    bool showTranslation = App.locale.languageCode == "zh";

    Widget buildItem(Pair<String, TranslationType> value) {
      var subTitle = TagsTranslation.translationTagWithNamespace(
          value.left, value.right.name);
      return MiuixBasicComponent(
        content: [
          Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                value.left,
                maxLines: 2,
              ),
            ),
            if (!showMethod)
              const SizedBox(
                width: 12,
              ),
            if (!showMethod && showTranslation)
              Text(
                subTitle,
                style: TextStyle(
                    fontSize: 14, color: Theme.of(context).colorScheme.outline),
              )
          ],
        ),
          if (showMethod && showTranslation) Text(subTitle),
        ],
        endActions: [
          Text(
            value.right.name,
            style: const TextStyle(fontSize: 13),
          ),
        ],
        onClick: () => onSelected(value.left, value.right),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: [
              const SizedBox(
                width: 32,
              ),
              Text("建议".tl),
              const Spacer(),
              MiuixPressable(
 onPressed: () {
                  widget.controller.suggestions.clear();
                  widget.controller.remove();
                },
 feedbackType: MiuixPressFeedbackType.sink, borderRadius: BorderRadius.circular(14),
 child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: MiuixIcon(
                    vector: MiuixIcons.basic.close,
                    size: 18,
                  ),
                ),
),
              const SizedBox(
                width: 36,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.controller.suggestions.length,
            itemBuilder: (context, index) =>
                buildItem(widget.controller.suggestions[index]),
          ),
        )
      ],
    );
  }

  bool check(String text, String key, String value) {
    if (text.removeAllBlank == "") {
      return false;
    }
    if (key.length >= text.length && key.substring(0, text.length) == text ||
        (key.contains(" ") &&
            key.split(" ").last.length >= text.length &&
            key.split(" ").last.substring(0, text.length) == text)) {
      return true;
    } else if (value.length >= text.length && value.contains(text)) {
      return true;
    }
    return false;
  }

  void onSelected(String text, TranslationType? type) {
    var controller = widget.controller.controller;
    var words = controller.text.split(" ");
    if (words.length >= 2 &&
        check("${words[words.length - 2]} ${words[words.length - 1]}", text,
            text.translateTagsToCN)) {
      controller.text = controller.text.replaceLast(
          "${words[words.length - 2]} ${words[words.length - 1]}", "");
    } else {
      controller.text =
          controller.text.replaceLast(words[words.length - 1], "");
    }
    final source = widget.controller.sourceKey;
    if (text.contains(" ")) {
      if (source == 'nhentai' &&
          ["male", "female", "language"].contains(type?.name)) {
        text = "${type?.name}:${text.replaceAll(" ", '_')}";
        type = null;
      } else {
        text = "\"$text\"";
      }
    }
    if (source == 'ehentai' && type != null) {
      controller.text += "${type.name}:$text ";
    } else {
      controller.text += "$text ";
    }
    widget.controller.suggestions.clear();
    widget.controller.remove();
  }
}

class _SearchOptions extends StatefulWidget {
  const _SearchOptions({
    required this.current,
    required this.sourceKey,
    required this.onChanged,
    required this.close,
  });

  final List<String> current;

  final String sourceKey;

  final void Function(List<String>) onChanged;

  /// 关闭外层 showMiuixDialog
  final void Function() close;

  @override
  State<_SearchOptions> createState() => _SearchOptionsState();
}

class _SearchOptionsState extends State<_SearchOptions> {
  late SearchPageData data;

  var options = <String>[];

  @override
  void initState() {
    data = ComicSource.find(widget.sourceKey)!.searchPageData!;
    options = widget.current;
    if (data.searchOptions != null &&
        options.length != data.searchOptions!.length) {
      options = data.searchOptions!.map((e) => e.defaultValue).toList();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildSearchOptions(context),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: MiuixButton(
            colors: MiuixButtonDefaults.buttonColorsPrimary(context),
            child: Text("确认".tl),
            onPressed: () {
              widget.close();
              widget.onChanged(options);
            },
          ),
        )
      ],
    );
  }

  Widget buildSearchOptions(BuildContext context) {
    var children = <Widget>[];
    if (data.customOptionsBuilder != null) {
      children.add(
        data.customOptionsBuilder!(context, options, (options) {
          this.options = options;
        }),
      );
    } else {
      final searchOptions = data.searchOptions ?? <SearchOptions>[];
      for (int i = 0; i < searchOptions.length; i++) {
        final option = searchOptions[i];
        children.add(MiuixBasicComponent(
                       title: option.label,
                     ));
        children.add(Wrap(
          runSpacing: 8,
          spacing: 8,
          children: option.options.entries.map((e) {
            return MiuixPressable(
 onPressed: () {
                setState(() {
                  options[i] = e.key;
                });
              },
 feedbackType: MiuixPressFeedbackType.sink, borderRadius: BorderRadius.circular(8),
 child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: options[i] == e.key
                      ? context.colorScheme.primaryContainer
                      : context.colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(e.value.tl),
                ),
              ),
);
          }).toList(),
        ).paddingHorizontal(16));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ).paddingBottom(12);
  }
}
