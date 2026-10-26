import "package:flutter/material.dart";
import "package:pica_comic/comic_source/comic_source.dart";
import 'package:pica_comic/components/components.dart';
import "package:pica_comic/foundation/app.dart";
import 'package:pica_comic/network/base_comic.dart';
import "package:pica_comic/network/res.dart";
import "package:pica_comic/tools/translations.dart";

class CategoryComicsPage extends StatefulWidget {
  const CategoryComicsPage({
    required this.category,
    this.param,
    required this.categoryKey,
    super.key,
  });

  final String category;

  final String? param;

  final String categoryKey;

  @override
  State<CategoryComicsPage> createState() => _CategoryComicsPageState();
}

class _CategoryComicsPageState extends State<CategoryComicsPage> {
  late final CategoryComicsData data;
  late final List<CategoryComicsOptions> options;
  late List<String> optionsValue;

  void findData() {
    for (final source in ComicSource.sources) {
      if (source.categoryData?.key == widget.categoryKey) {
        data = source.categoryComicsData!;
        options = data.options.where((element) {
          if (element.notShowWhen.contains(widget.category)) {
            return false;
          } else if (element.showWhen != null) {
            return element.showWhen!.contains(widget.category);
          }
          return true;
        }).toList();
        optionsValue = options.map((e) => e.options.keys.first).toList();
        return;
      }
    }
    throw "${widget.categoryKey} Not found";
  }

  @override
  void initState() {
    findData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(
      content: (_) => _CategoryComicsList(
        key: ValueKey(
            "${widget.category} with ${widget.param} and $optionsValue"),
        loader: data.load,
        category: widget.category,
        options: optionsValue,
        param: widget.param,
        pinnedHeader: buildOptions(),
        pinnedHeaderHeight: kOptionRowHeight * options.length,
        sourceKey: ComicSource.sources
            .firstWhere((e) => e.categoryData?.key == widget.categoryKey)
            .key,
      ),
    );
  }

  Widget buildOptionItem(
      String text, String value, int group, BuildContext context) {
    return OptionChip(
      text: text,
      isSelected: value == optionsValue[group],
      onTap: () {
        if (value == optionsValue[group]) return;
        setState(() {
          optionsValue[group] = value;
        });
      },
    );
  }

  /// 筛选选项：每组一行横向滚动 Chip，作为顶栏的一部分固定显示。
  Widget buildOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var optionList in options)
          SizedBox(
            height: kOptionRowHeight,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (var option in optionList.options.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: buildOptionItem(
                        option.value.tl,
                        option.key,
                        options.indexOf(optionList),
                        context,
                      ),
                    ),
                  )
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryComicsList extends ComicsPage<BaseComic> {
  const _CategoryComicsList({
    super.key,
    required this.loader,
    required this.category,
    required this.options,
    this.param,
    required this.pinnedHeader,
    required this.pinnedHeaderHeight,
    required this.sourceKey,
  });

  final CategoryComicsLoader loader;

  final String category;

  final List<String> options;

  final String? param;

  @override
  final String sourceKey;

  @override
  final Widget pinnedHeader;

  @override
  final double pinnedHeaderHeight;

  @override
  Future<Res<List<BaseComic>>> getComics(int i) async {
    return await loader(category, param, options, i);
  }

  @override
  String? get tag => "$category with $param and $options";

  @override
  String? get title => category;
}
