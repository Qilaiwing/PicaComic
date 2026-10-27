import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/pair.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/search_result_page.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:sliver_tools/sliver_tools.dart';

typedef FilterChip = FilterChipFixedWidth;

class _FloatingSearchBar extends StatefulWidget {
  const _FloatingSearchBar(
      {Key? key,
      required this.supportingText,
      required this.onFinish,
      required this.controller,
      this.onChanged,
      this.focusNode})
      : super(key: key);

  final void Function(String) onFinish;
  final String supportingText;
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  @override
  State<_FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<_FloatingSearchBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14) +
          const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        MiuixTooltipBox(
          tooltip: (_, scope) =>
              MiuixPlainTooltip(scope: scope, child: Text("返回".tl)),
          child: MiuixIconButton(
            minWidth: 36,
            minHeight: 36,
            onPressed: () => context.pop(),
            child: MiuixIcon(
              vector: MiuixIcons.extended.byName('chevronBackward') ??
                  MiuixIcons.os4.back,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          // 直接把外部 controller 交给 TextField（唯一数据源），不再在 build 中
          // 把文本同步进 MiuixInputField 的内部 controller——那会在构建期间触发
          // EditableText/选区 Overlay 的 markNeedsBuild。
          child: AppSearchField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            hint: widget.supportingText,
            onChanged: widget.onChanged,
            onSubmitted: widget.onFinish,
          ),
        ),
        const SizedBox(width: 6),
        Builder(builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return MiuixButton(
            colors: MiuixButtonColors(
              color: scheme.primary,
              disabledColor: scheme.primary.withValues(alpha: 0.4),
              contentColor: scheme.onPrimary,
              disabledContentColor: scheme.onPrimary.withValues(alpha: 0.5),
            ),
            minWidth: 52,
            minHeight: 36,
            cornerRadius: 18,
            insideMargin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            onPressed: () {
              final q = widget.controller is SearchChipController
                  ? (widget.controller as SearchChipController).query
                  : widget.controller.text;
              widget.onFinish(q);
            },
            child: Text(
              "搜索".tl,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          );
        }),
      ]),
    );
  }
}

class PreSearchController extends StateController {
  String target = '';

  SearchPageData get searchPageData =>
      ComicSource.find(target)!.searchPageData!;

  var options = <String>[];

  var suggestions = <Pair<String, TranslationType>>[];

  String? language;

  bool limitHistory = true;

  void updateOptions() {
    for (var source in ComicSource.sources) {
      if (source.key == target &&
          source.searchPageData?.searchOptions != null) {
        options = List.generate(
          source.searchPageData!.searchOptions!.length,
          (index) => source.searchPageData!.searchOptions![index].defaultValue,
        );
      }
    }
  }

  void updateTarget(String i) {
    target = i;
    updateOptions();
    update();
  }

  PreSearchController() {
    var searchSource = <String>[];
    for (var source in ComicSource.sources) {
      searchSource.add(source.key);
    }
    if (!searchSource.contains(appdata.appSettings.initialSearchTarget)) {
      appdata.appSettings.initialSearchTarget = searchSource.first;
      appdata.updateSettings();
    }
    target = appdata.appSettings.initialSearchTarget;
    updateOptions();
  }
}

class PreSearchPage extends StatelessWidget {
  PreSearchPage({String initialValue = "", super.key})
      : controller = SearchChipController(text: initialValue);

  final SearchChipController controller;

  final searchController = StateController.put(PreSearchController());

  final comicSources =
      ComicSource.sources.where((element) => element.searchPageData != null);

  final FocusNode _focusNode = FocusNode();

  void search([String? s, String? type]) {
    var keyword = (s ?? controller.query).trim();

    if (searchController.language != null &&
        searchController.searchPageData.enableLanguageFilter) {
      // 在添加语言筛选前，先移除掉可能存在的 language: 部分
      // 主要是为了解决强迫症
      final languagePattern = RegExp(r'\s*language:\w+');
      keyword = keyword.replaceAll(languagePattern, '').trim();
      keyword += " language:${searchController.language}";
    }

    var context = App.mainNavigatorKey!.currentContext!;
    context.to(
      () => SearchResultPage(
        keyword: keyword,
        sourceKey: type ?? searchController.target,
        options: searchController.options,
      ),
    );
  }

  /// Long-press a favorite tag: append its keyword as a chip (stay on page).
  void insertFavoriteChip(String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return;
    controller.addChip(k);
    findSuggestions();
    searchController.update([1, 100]);
    _focusNode.requestFocus();
  }

  void findSuggestions() {
    var text = controller.text.split(" ").last;
    var suggestions = searchController.suggestions;

    suggestions.clear();

    if (canHandle(controller.text)) {
      suggestions.add(Pair("**URL**", TranslationType.other));
    } else {
      var text = controller.text;

      for (var comicSource in ComicSource.sources) {
        if (comicSource.idMatcher?.hasMatch(text) ?? false) {
          suggestions
              .add(Pair("**${comicSource.key}**", TranslationType.other));
        }
      }
    }

    if (!searchController.searchPageData.enableTagsSuggestions) return;

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

  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(
 content: (_) => Column(
        children: [
          if (UiMode.m1(context))
            SizedBox(
              height: MediaQuery.of(context).padding.top,
            ),
          Builder(
            builder: (context) => _FloatingSearchBar(
              supportingText: '${'搜索'.tl} / ${'链接'.tl} / ID',
              onFinish: (s) {
                search(s);
              },
              controller: controller,
              onChanged: (s) {
                findSuggestions();
                searchController.update([1, 100]);
              },
              focusNode: _focusNode,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          buildBody(context)
        ],
      ),
);
  }

  Widget buildBody(BuildContext context) {
    var widget = StateBuilder<PreSearchController>(
      id: 100,
      builder: (logic) {
        if (controller.text.removeAllBlank.isEmpty ||
            controller.text.endsWith(" ") ||
            searchController.suggestions.isEmpty) {
          return buildMainView(context, logic);
        } else {
          return buildSuggestions(context);
        }
      },
    );
    return Expanded(
      child: widget,
    );
  }

  Widget buildMainView(BuildContext context, PreSearchController logic) {
    final showSideBar = MediaQuery.of(context).size.width > 950;
    var addWidth = (MediaQuery.of(context).size.width - 950) * 0.25;
    addWidth = addWidth.clamp(0, 50);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSideBar)
          SizedBox(
            width: 250 + addWidth,
            height: double.infinity,
            child: buildHistorySideBar(),
          ),
        if (showSideBar)
          const VerticalDivider(
            width: 1,
          ),
        Expanded(
            child: CustomScrollView(
          slivers: [
            if (showSideBar)
              MiuixBasicComponent(
                startAction: const Icon(Icons.select_all),
                title: "搜索选项".tl,
              ).toSliver(),
            buildTargetSelector(context).toSliver(),
            SliverAnimatedPaintExtent(
              duration: const Duration(milliseconds: 180),
              child: buildSearchOptions(context).toSliver(),
            ),
            if (!showSideBar) ...buildHistoryAndFavoritesForMobile(logic),
            SliverPadding(
              padding: EdgeInsets.only(bottom: context.padding.bottom),
            )
          ],
        )),
        if (showSideBar)
          const VerticalDivider(
            width: 1,
          ),
        if (showSideBar)
          SizedBox(
            width: 250 + addWidth,
            height: double.infinity,
            child: buildFavoriteSideBar(),
          ),
      ],
    );
  }

  Widget buildSuggestions(BuildContext context) {
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

    return StateBuilder<PreSearchController>(
      builder: (logic) {
        void onSelected(String text, TranslationType? type) {
          var words = controller.text.split(" ");
          if (words.length >= 2 &&
              check("${words[words.length - 2]} ${words[words.length - 1]}",
                  text, text.translateTagsToCN)) {
            controller.text = controller.text.replaceLast(
                "${words[words.length - 2]} ${words[words.length - 1]}", "");
          } else {
            controller.text =
                controller.text.replaceLast(words[words.length - 1], "");
          }
          if (text.contains(" ")) {
            if (logic.target == 'nhentai' &&
                ["male", "female", "language"].contains(type?.name)) {
              text = text.replaceAll(" ", '_');
              text = "${type?.name}:$text";
            } else {
              text = "\"$text\"";
            }
          }
          if (logic.target == 'ehentai') {
            if (type != null) {
              controller.text += "${type.name}:$text ";
            } else {
              controller.text += "$text ";
            }
          } else {
            controller.text += "$text ";
          }
          logic.update([1, 100]);
          _focusNode.requestFocus();
        }

        Widget widget;

        if (controller.text.removeAllBlank.isEmpty) {
          widget = buildMainView(context, logic);
        } else {
          bool showMethod = MediaQuery.of(context).size.width < 600;
          bool showTranslation = App.locale.languageCode == "zh";
          Widget buildItem(Pair<String, TranslationType> value) {
            if (value.left == "**URL**") {
              return MiuixArrowPreference(
                startAction: const Icon(Icons.link),
                title: "打开链接".tl,
                summary: controller.text,
                onClick: () {
                  handleAppLinks(Uri.parse(controller.text));
                },
              );
            }

            if (RegExp(r"^\*\*.*\*\*$").hasMatch(value.left)) {
              var key = value.left.substring(2, value.left.length - 2);
              var comicSource = ComicSource.find(key);
              if (comicSource == null) {
                return const SizedBox();
              }
              return MiuixArrowPreference(
                startAction: const Icon(Icons.link),
                title: "${"打开漫画".tl}: ${comicSource.name}",
                summary: controller.text,
                onClick: () {
                  context.to(
                    () => ComicPage(
                      sourceKey: key,
                      id: controller.text,
                    ),
                  );
                },
              );
            }

            var subTitle = TagsTranslation.translationTagWithNamespace(
                value.left, value.right.name);
            return MiuixBasicComponent(
              content: [
                Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value.left),
                  if (!showMethod)
                    const SizedBox(
                      width: 12,
                    ),
                  if (!showMethod && showTranslation)
                    Text(
                      subTitle,
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.outline),
                    )
                ],
              ),
                if (showMethod && showTranslation) Text(subTitle),
              ],
              endActions: [
                Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: ShapeDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  value.right.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              ],
              onClick: () => onSelected(value.left, value.right),
            );
          }

          widget = Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      "建议".tl,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    MiuixPressable(
 onPressed: () {
                          searchController.suggestions.clear();
                          logic.update([100]);
                        },
 feedbackType: MiuixPressFeedbackType.sink,
 child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                          ),
                        ),
),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: searchController.suggestions.length,
                  itemBuilder: (context, index) =>
                      buildItem(searchController.suggestions[index]),
                ),
              )
            ],
          );
        }
        return widget;
      },
      id: 1,
    );
  }

  Widget buildTargetSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    Widget buildItem(PreSearchController logic, String id, String text) {
      final isSelected = logic.target == id;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: MiuixPressable(
            onPressed: () => logic.updateTarget(id),
            feedbackType: MiuixPressFeedbackType.sink,
            sinkAmount: 1.05,
            shape: const StadiumBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
              decoration: ShapeDecoration(
                shape: const StadiumBorder(),
                color: isSelected
                    ? primaryColor
                    : (isDark
                        ? const Color(0xFF2A2A2E)
                        : const Color(0xFFF0F1F5)),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? const Color(0xDDFFFFFF)
                          : const Color(0xDD000000)),
                ),
              ),
            ),
),
      );
    }

    return StateBuilder<PreSearchController>(
      builder: (logic) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: ShapeDecoration(
            shape: MiuixSquircleBorder(
              cornerRadius: 18,
              side: BorderSide(
                color:
                    isDark ? const Color(0x18FFFFFF) : const Color(0x0A000000),
                width: 0.6,
              ),
            ),
            color: isDark ? const Color(0xFF222226) : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  MiuixIcon(
                    vector: MiuixIcons.os4.more,
                    size: 16,
                    tint: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "漫画源".tl,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                children: [
                  for (var source in comicSources)
                    buildItem(logic, source.key, source.name.tl)
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildSearchOptions(BuildContext context) {
    Widget buildLangSelector() {
      const languages = ["chinese", "japanese", "english"];
      return Padding(
        padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
        child: Row(
          children: [
            const SizedBox(
              width: 8,
            ),
            Text("语言".tl),
            const SizedBox(
              width: 16,
            ),
            Select(
              initialValue: languages.indexOf(searchController.language ?? ""),
              onChange: (i) => searchController.language = languages[i],
              values: languages,
              outline: true,
            ),
          ],
        ),
      );
    }

    return StateBuilder<PreSearchController>(
      id: "mode",
      builder: (logic) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        var children = <Widget>[];
        if (logic.searchPageData.customOptionsBuilder != null) {
          children.add(
            logic.searchPageData.customOptionsBuilder!(context, [], (options) {
              logic.options = options;
            }),
          );
        } else {
          final searchOptions =
              logic.searchPageData.searchOptions ?? <SearchOptions>[];
          for (int i = 0; i < searchOptions.length; i++) {
            final option = searchOptions[i];
            children.add(Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              child: Text(
                option.label.tl,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ));
            children.add(Wrap(
              runSpacing: 8,
              spacing: 8,
              children: option.options.entries.map((e) {
                return OptionChip(
                  text: e.value.tl,
                  isSelected: logic.options[i] == e.key,
                  onTap: () {
                    logic.options[i] = e.key;
                    logic.update();
                  },
                );
              }).toList(),
            ));
            if (i < searchOptions.length - 1) {
              children.add(const SizedBox(height: 10));
            }
          }
        }
        if (logic.searchPageData.enableLanguageFilter) {
          children.add(buildLangSelector());
        }
        if (children.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: ShapeDecoration(
            shape: MiuixSquircleBorder(
              cornerRadius: 18,
              side: BorderSide(
                color:
                    isDark ? const Color(0x18FFFFFF) : const Color(0x0A000000),
                width: 0.6,
              ),
            ),
            color: isDark ? const Color(0xFF222226) : Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      },
    );
  }

  Widget buildHistoryItem(String history, PreSearchController logic) {
    return Flyout(
      enableLongPress: true,
      enableSecondaryTap: true,
      navigator: App.navigatorKey.currentState,
      flyoutBuilder: (context) {
        return FlyoutContent(
          title: "要删除此项目吗?".tl,
          actions: [
            MiuixButton(
              colors: MiuixButtonColors(
                  color: Theme.of(context).colorScheme.error,
                  disabledColor: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.5),
                  contentColor: Theme.of(context).colorScheme.onError,
                  disabledContentColor: Theme.of(context)
                      .colorScheme
                      .onError
                      .withValues(alpha: 0.5)),
              onPressed: () {
                appdata.searchHistory.remove(history);
                logic.update(["history"]);
                appdata.writeHistory();
                App.globalBack();
              },
              child: Text("确认".tl),
            )
          ],
        );
      },
      child: MiuixPressable(
 onPressed: () => search(history),
 feedbackType: MiuixPressFeedbackType.sink,
 child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                history,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
),
    );
  }

  Widget buildFavoriteItem(String tag, PreSearchController logic) {
    final keyword = tag.substring(tag.indexOf(':') + 1);
    return Flyout(
      enableLongPress: false,
      enableSecondaryTap: true,
      navigator: App.navigatorKey.currentState,
      flyoutBuilder: (context) {
        return FlyoutContent(
          title: "要删除此项目吗?".tl,
          actions: [
            MiuixButton(
              colors: MiuixButtonColors(
                  color: Theme.of(context).colorScheme.error,
                  disabledColor: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.5),
                  contentColor: Theme.of(context).colorScheme.onError,
                  disabledContentColor: Theme.of(context)
                      .colorScheme
                      .onError
                      .withValues(alpha: 0.5)),
              onPressed: () {
                appdata.favoriteTags.remove(tag);
                searchController.update();
                appdata.writeHistory();
                App.globalBack();
              },
              child: Text("确认".tl),
            )
          ],
        );
      },
      child: GestureDetector(
        onLongPress: () => insertFavoriteChip(keyword),
        child: MiuixBasicComponent(
          title: keyword,
          summary: tag.split(':').first,
          onClick: () {
            String type = switch (tag.split(':').first) {
              "Picacg" => 'picacg',
              "EHentai" => 'ehentai',
              "JMComic" => 'jm',
              "hitomi" => 'hitomi',
              "HtComic" => 'htmanga',
              "Nhentai" => 'nhentai',
              _ => tag.split(':').first
            };
            search(keyword, type);
          },
        ),
      ),
    );
  }

  Widget buildClearHistoryButton(PreSearchController logic) {
    return MiuixTooltipBox(
 tooltip: (_, scope) => MiuixPlainTooltip(scope: scope, child: Text("清空历史记录".tl)),
 child: MiuixIconButton(
        minWidth: 32,
        minHeight: 32,
        onPressed: () {
          showConfirmDialog(
            App.globalContext!,
            "清空历史记录".tl,
            "要清空历史记录吗?".tl,
            () {
              appdata.searchHistory.clear();
              appdata.writeHistory();
              logic.update(["history"]);
            },
          );
        },
        child: MiuixIcon(
          vector: MiuixIcons.extended.byName('delete') ?? MiuixIcons.os4.close,
          size: 17,
          tint:
              Theme.of(App.globalContext!).colorScheme.primary.withOpacity(0.8),
        ),
      ),
);
  }

  Widget buildClearFavoriteButton(PreSearchController logic) {
    return MiuixTooltipBox(
 tooltip: (_, scope) => MiuixPlainTooltip(scope: scope, child: Text("清空收藏".tl)),
 child: MiuixIconButton(
        minWidth: 32,
        minHeight: 32,
        onPressed: () {
          showConfirmDialog(
            App.globalContext!,
            "清空收藏".tl,
            "要清空收藏标签吗?".tl,
            () {
              appdata.favoriteTags.clear();
              appdata.writeHistory();
              logic.update();
            },
          );
        },
        child: MiuixIcon(
          vector: MiuixIcons.extended.byName('delete') ?? MiuixIcons.os4.close,
          size: 17,
          tint:
              Theme.of(App.globalContext!).colorScheme.primary.withOpacity(0.8),
        ),
      ),
);
  }

  Widget buildHistorySideBar() {
    return StateBuilder<PreSearchController>(
      id: "history",
      builder: (logic) {
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: appdata.searchHistory.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return MiuixBasicComponent(
                startAction: const Icon(Icons.history_rounded),
                title: "历史搜索".tl,
                endActions: [buildClearHistoryButton(logic)],
              );
            } else {
              var history =
                  appdata.searchHistory[appdata.searchHistory.length - index];
              return buildHistoryItem(history, logic);
            }
          },
        );
      },
    );
  }

  Widget buildFavoriteSideBar() {
    return StateBuilder<PreSearchController>(
      builder: (logic) => ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: appdata.favoriteTags.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return MiuixBasicComponent(
              startAction: const Icon(Icons.favorite_rounded),
              title: "收藏".tl,
              endActions: [buildClearFavoriteButton(logic)],
            );
          } else {
            final s = appdata.favoriteTags.elementAt(index - 1);
            return buildFavoriteItem(s, logic);
          }
        },
      ),
    );
  }

  Iterable<Widget> buildHistoryAndFavoritesForMobile(
      PreSearchController logic) sync* {
    final isDark = Theme.of(App.globalContext!).brightness == Brightness.dark;
    final primaryColor = Theme.of(App.globalContext!).colorScheme.primary;

    yield SliverToBoxAdapter(
      child: StateBuilder<PreSearchController>(
        id: "history",
        builder: (logic) {
          final isEmpty = appdata.searchHistory.isEmpty;
          var length = appdata.searchHistory.length;
          if (length < 12) {
            logic.limitHistory = false;
          }
          final showCount = logic.limitHistory ? length.clamp(0, 12) : length;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: ShapeDecoration(
              shape: MiuixSquircleBorder(
                cornerRadius: 18,
                side: BorderSide(
                  color: isDark
                      ? const Color(0x18FFFFFF)
                      : const Color(0x0A000000),
                  width: 0.6,
                ),
              ),
              color: isDark ? const Color(0xFF222226) : Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MiuixIcon(
                      vector: MiuixIcons.extended.byName('recent') ??
                          MiuixIcons.os4.settings,
                      size: 16,
                      tint: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "历史搜索".tl,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (!isEmpty) buildClearHistoryButton(logic),
                  ],
                ),
                const SizedBox(height: 10),
                if (isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "暂无搜索历史".tl,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0x66FFFFFF)
                            : const Color(0x66000000),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < showCount; i++) ...[
                        Builder(
                          builder: (context) {
                            final history = appdata.searchHistory[
                                appdata.searchHistory.length - i - 1];
                            return MiuixPressable(
 onPressed: () => search(history),
 feedbackType: MiuixPressFeedbackType.sink,
 child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(13, 6, 8, 6),
                                  decoration: ShapeDecoration(
                                    shape: const StadiumBorder(),
                                    color: isDark
                                        ? const Color(0xFF2A2A2E)
                                        : const Color(0xFFF0F1F5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        history,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0xDDFFFFFF)
                                              : const Color(0xDD000000),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          appdata.searchHistory.remove(history);
                                          logic.update(["history"]);
                                          appdata.writeHistory();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: MiuixIcon(
                                            vector: MiuixIcons.basic.close,
                                            size: 12,
                                            tint: isDark
                                                ? const Color(0x88FFFFFF)
                                                : const Color(0x77000000),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
);
                          },
                        ),
                      ],
                      if (length > 12)
                        MiuixPressable(
 onPressed: () {
                              logic.limitHistory = !logic.limitHistory;
                              logic.update(["history"]);
                            },
 feedbackType: MiuixPressFeedbackType.sink,
 child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: ShapeDecoration(
                                shape: const StadiumBorder(),
                                color: primaryColor.withOpacity(0.12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    logic.limitHistory ? "展开更多".tl : "收起".tl,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                  Icon(
                                    logic.limitHistory
                                        ? Icons.keyboard_arrow_down_rounded
                                        : Icons.keyboard_arrow_up_rounded,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            ),
),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );

    yield SliverToBoxAdapter(
      child: StateBuilder<PreSearchController>(
        builder: (logic) {
          final isEmpty = appdata.favoriteTags.isEmpty;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: ShapeDecoration(
              shape: MiuixSquircleBorder(
                cornerRadius: 18,
                side: BorderSide(
                  color: isDark
                      ? const Color(0x18FFFFFF)
                      : const Color(0x0A000000),
                  width: 0.6,
                ),
              ),
              color: isDark ? const Color(0xFF222226) : Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MiuixIcon(
                      vector: MiuixIcons.os4.favorites,
                      size: 16,
                      tint: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "收藏标签".tl,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (!isEmpty) buildClearFavoriteButton(logic),
                  ],
                ),
                const SizedBox(height: 10),
                if (isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "暂无收藏标签".tl,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? const Color(0x66FFFFFF)
                            : const Color(0x66000000),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var tag in appdata.favoriteTags) ...[
                        Builder(
                          builder: (context) {
                            final source = tag.split(':').first;
                            final keyword = tag.substring(tag.indexOf(':') + 1);
                            return MiuixPressable(
                              onPressed: () {
                                  String type = switch (source) {
                                    "Picacg" => 'picacg',
                                    "EHentai" => 'ehentai',
                                    "JMComic" => 'jm',
                                    "hitomi" => 'hitomi',
                                    "HtComic" => 'htmanga',
                                    "Nhentai" => 'nhentai',
                                    _ => source
                                  };
                                  search(keyword, type);
                                },
                              onLongPress: () => insertFavoriteChip(keyword),
                              feedbackType: MiuixPressFeedbackType.sink,
                              sinkAmount: 1.05,
                              shape: const StadiumBorder(),
                              child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(6, 4, 8, 4),
                                  decoration: ShapeDecoration(
                                    shape: const StadiumBorder(),
                                    color: isDark
                                        ? const Color(0xFF2A2A2E)
                                        : const Color(0xFFF0F1F5),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: ShapeDecoration(
                                          shape: const StadiumBorder(),
                                          color: primaryColor.withOpacity(0.12),
                                        ),
                                        child: Text(
                                          source,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        keyword,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? const Color(0xDDFFFFFF)
                                              : const Color(0xDD000000),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () {
                                          appdata.favoriteTags.remove(tag);
                                          logic.update();
                                          appdata.writeHistory();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: MiuixIcon(
                                            vector: MiuixIcons.basic.close,
                                            size: 12,
                                            tint: isDark
                                                ? const Color(0x88FFFFFF)
                                                : const Color(0x77000000),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
);
                          },
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
