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
          return MiuixPressable(
            onPressed: () {
              final q = widget.controller is SearchChipController
                  ? (widget.controller as SearchChipController).commitPending()
                  : widget.controller.text;
              widget.onFinish(q);
            },
            feedbackType: MiuixPressFeedbackType.sink,
            sinkAmount: 0.96,
            shape: const StadiumBorder(),
            child: Container(
              height: 36,
              constraints: const BoxConstraints(minWidth: 52),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: scheme.primary,
                shape: const StadiumBorder(),
              ),
              child: Text(
                "搜索".tl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                  leadingDistribution: TextLeadingDistribution.even,
                  color: scheme.onPrimary,
                ),
              ),
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
    if (searchSource.isNotEmpty &&
        !searchSource.contains(appdata.appSettings.initialSearchTarget)) {
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
    // When no explicit keyword, flush leftover typing into a chip first.
    var keyword = (s ?? controller.commitPending()).trim();

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

  /// Long-press a favorite tag: append its keyword as plain text (stay on page).
  void insertFavoriteChip(String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return;
    // Only mutate chips — AppSearchField listens via ListenableBuilder.
    // Avoid findSuggestions/update/requestFocus which rebuild the page and flash.
    controller.addChip(k);
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
              return _buildMiuixSuggestTile(
                context: context,
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
              return _buildMiuixSuggestTile(
                context: context,
                title: "${"打开漫画".tl}: ${comicSource.name.tl}",
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

          widget = Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            decoration: ShapeDecoration(
              shape: MiuixSquircleBorder(
                cornerRadius: 18,
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0x18FFFFFF)
                      : const Color(0x0A000000),
                  width: 0.6,
                ),
              ),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF222226)
                  : Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(14, 10, 8, 4),
                  child: Row(
                    children: [
                      MiuixIcon(
                        vector: MiuixIcons.os4.info,
                        size: 16,
                        tint: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
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
                        shape: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: MiuixIcon(
                            vector: MiuixIcons.os4.close,
                            size: 16,
                            tint: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                    itemCount: searchController.suggestions.length,
                    itemBuilder: (context, index) =>
                        buildItem(searchController.suggestions[index]),
                  ),
                )
              ],
            ),
          );
        }
        return widget;
      },
      id: 1,
    );
  }


  Widget _buildMiuixSuggestTile({
    required BuildContext context,
    required String title,
    required String summary,
    required VoidCallback onClick,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: MiuixPressable(
        onPressed: onClick,
        feedbackType: MiuixPressFeedbackType.sink,
        sinkAmount: 1.02,
        shape: const MiuixSquircleBorder(cornerRadius: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: ShapeDecoration(
            shape: const MiuixSquircleBorder(cornerRadius: 14),
            color: isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF0F1F5),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  shape: const StadiumBorder(),
                  color: scheme.primary.withValues(alpha: 0.14),
                ),
                child: MiuixIcon(
                  vector: MiuixIcons.os4.link,
                  size: 18,
                  tint: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.1,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              MiuixIcon(
                vector: MiuixIcons.os4.forward,
                size: 16,
                tint: scheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
      final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            height: 1.1,
          );
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Text("语言".tl, style: labelStyle),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Select(
                  initialValue: (() {
                    final i = languages.indexOf(searchController.language ?? "");
                    return i < 0 ? 0 : i;
                  })(),
                  width: 148,
                  onChange: (i) => searchController.language = languages[i],
                  values: languages,
                  outline: false,
                ),
              ),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
          final histories = List<String>.from(appdata.searchHistory.reversed);
          return _SwipePagedChipsCard(
            title: "历史搜索".tl,
            leading: MiuixIcon(
              vector: MiuixIcons.extended.byName('recent') ??
                  MiuixIcons.os4.settings,
              size: 16,
              tint: primaryColor,
            ),
            trailing: histories.isEmpty ? null : buildClearHistoryButton(logic),
            emptyText: "暂无搜索历史".tl,
            isDark: isDark,
            primaryColor: primaryColor,
            pageSize: 10,
            itemCount: histories.length,
            itemBuilder: (context, i) {
              final history = histories[i];
              return MiuixPressable(
                onPressed: () => search(history),
                feedbackType: MiuixPressFeedbackType.sink,
                sinkAmount: 1.05,
                shape: const StadiumBorder(),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(13, 6, 8, 6),
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: isDark
                        ? const Color(0xFF2A2A2E)
                        : const Color(0xFFF0F1F5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.62,
                        ),
                        child: Text(
                          history,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xDDFFFFFF)
                                : const Color(0xDD000000),
                          ),
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
          );
        },
      ),
    );

    yield SliverToBoxAdapter(
      child: StateBuilder<PreSearchController>(
        builder: (logic) {
          final tags = appdata.favoriteTags.toList();
          return _SwipePagedChipsCard(
            title: "收藏标签".tl,
            leading: MiuixIcon(
              vector: MiuixIcons.os4.favorites,
              size: 16,
              tint: primaryColor,
            ),
            trailing: tags.isEmpty ? null : buildClearFavoriteButton(logic),
            emptyText: "暂无收藏标签".tl,
            isDark: isDark,
            primaryColor: primaryColor,
            pageSize: 10,
            itemCount: tags.length,
            itemBuilder: (context, i) {
              final tag = tags[i];
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
                  padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
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
          );
        },
      ),
    );
  }
}

/// Fixed-height card: chips paginated, swipe left/right between pages.
class _SwipePagedChipsCard extends StatefulWidget {
  const _SwipePagedChipsCard({
    required this.title,
    required this.leading,
    required this.emptyText,
    required this.isDark,
    required this.primaryColor,
    required this.pageSize,
    required this.itemCount,
    required this.itemBuilder,
    this.trailing,
  });

  final String title;
  final Widget leading;
  final Widget? trailing;
  final String emptyText;
  final bool isDark;
  final Color primaryColor;
  final int pageSize;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<_SwipePagedChipsCard> createState() => _SwipePagedChipsCardState();
}

class _SwipePagedChipsCardState extends State<_SwipePagedChipsCard> {
  late final PageController _pageController;
  int _page = 0;

  int get _pageCount {
    if (widget.itemCount <= 0) return 1;
    return (widget.itemCount + widget.pageSize - 1) ~/ widget.pageSize;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _SwipePagedChipsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= _pageCount) {
      _page = _pageCount - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_page);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.itemCount == 0;
    // ~3 rows of stadium chips + gaps
    const pageHeight = 118.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: ShapeDecoration(
        shape: MiuixSquircleBorder(
          cornerRadius: 18,
          side: BorderSide(
            color: widget.isDark
                ? const Color(0x18FFFFFF)
                : const Color(0x0A000000),
            width: 0.6,
          ),
        ),
        color: widget.isDark ? const Color(0xFF222226) : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              widget.leading,
              const SizedBox(width: 6),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: widget.primaryColor,
                ),
              ),
              const Spacer(),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
          const SizedBox(height: 10),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                widget.emptyText,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.isDark
                      ? const Color(0x66FFFFFF)
                      : const Color(0x66000000),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: pageHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, page) {
                  final start = page * widget.pageSize;
                  final end = (start + widget.pageSize).clamp(0, widget.itemCount);
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = start; i < end; i++)
                          widget.itemBuilder(context, i),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_pageCount > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pageCount; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 14 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: i == _page
                            ? widget.primaryColor
                            : (widget.isDark
                                ? const Color(0x44FFFFFF)
                                : const Color(0x33000000)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
