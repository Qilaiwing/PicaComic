import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/ehentai/accounts.dart';
import 'package:pica_comic/pages/ehentai/eh_gallery_page.dart';
import 'package:pica_comic/pages/ehentai/eh_login_page.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/tools/translations.dart';

import '../../base.dart';
import '../comic_source.dart';

final ehentai = ComicSource.named(
  name: 'ehentai',
  key: 'ehentai',
  filePath: 'built-in',
  favoriteData: FavoriteData(
    key: "ehentai",
    title: "ehentai",
    multiFolder: true,
    loadComic: (i, [folderId]) {
      if (i == 1) {
        _EhentaiGalleriesLoader.instances['favorite'] =
            _EhentaiGalleriesLoader(firstPageLoader: () async {
          Res<Galleries> res;
          if (folderId == '-1') {
            res = await EhNetwork().getGalleries(
                "${EhNetwork().ehBaseUrl}/favorites.php",
                favoritePage: true);
          } else {
            res = await EhNetwork().getGalleries(
                "${EhNetwork().ehBaseUrl}/favorites.php?favcat=$folderId",
                favoritePage: true);
          }
          return res;
        });
      }
      return _EhentaiGalleriesLoader.instances['favorite']!(i);
    },
    loadFolders: ([cid]) async {
      var e = await EhNetwork().getGalleries(
          "${EhNetwork().ehBaseUrl}/favorites.php",
          favoritePage: true);
      if (e.error) {
        return Res.fromErrorRes(e);
      }
      var res = <String, String>{};
      var folders = <String>["全部".tl];
      folders.addAll(EhNetwork().folderNames);
      for (int i = -1; i < EhNetwork().folderNames.length; i++) {
        res[i.toString()] = folders[i + 1];
      }
      return Res(res);
    },
  ),
  categoryData: CategoryData(
    title: "ehentai",
    key: "ehentai",
    categories: [
      RandomCategoryPartWithRuntimeData(
        "male",
        () => TagsTranslation.maleTags.keys,
        20,
        "search_with_namespace",
      ),
      RandomCategoryPartWithRuntimeData(
        "female",
        () => TagsTranslation.femaleTags.keys,
        20,
        "search_with_namespace",
      ),
      RandomCategoryPartWithRuntimeData(
        "parody",
        () => TagsTranslation.parodyTags.keys,
        20,
        "search_with_namespace",
      ),
      RandomCategoryPartWithRuntimeData(
        "character",
        () => TagsTranslation.characterTranslations.keys,
        20,
        "search",
      ),
      RandomCategoryPartWithRuntimeData(
        "mixed",
        () => TagsTranslation.mixedTags.keys,
        20,
        "search_with_namespace",
      ),
      RandomCategoryPartWithRuntimeData(
        "artist",
        () => TagsTranslation.artistTags.keys,
        20,
        "search_with_namespace",
      ),
      RandomCategoryPartWithRuntimeData(
        "group",
        () => TagsTranslation.groupTags.keys,
        20,
        "search_with_namespace",
      ),
      RandomCategoryPartWithRuntimeData(
        "cosplayer",
        () => TagsTranslation.cosplayerTags.keys,
        20,
        "search_with_namespace",
      ),
      RandomCategoryPartWithRuntimeData(
        "other",
        () => TagsTranslation.otherTags.keys,
        20,
        "search_with_namespace",
      ),
    ],
    enableRankingPage: true,
  ),
  categoryComicsData: CategoryComicsData.named(
    load: (p0, p1, p3, p4) => throw UnimplementedError(),
    rankingData: RankingData.named(
      options: {
        '15': "昨天",
        '13': "本月",
        '12': "今年",
        '11': "全部",
      },
      load: (options, page) {
        var type = int.tryParse(options) ?? 15;
        return EhNetwork().getLeaderBoardByPage(type, page);
      },
    ),
  ),
  account: AccountConfig.named(
    allowReLogin: false,
    onLogin: (BuildContext context) async {
      await context.to(() => const EhLoginPage());
      var cookies = EhNetwork().cookieJar.loadForRequest(Uri.parse("https://e-hentai.org"));
      if(!cookies.any((e) => e.name == 'ipb_member_id')) {
        return;
      }
      var ehentai = ComicSource.find('ehentai')!;
      if (ehentai.data['name'] != null) {
        ehentai.data['account'] = 'ok';
      }
      ehentai.saveData();
    },
    logout: () {
      var ehentai = ComicSource.find('ehentai')!;
      EhNetwork().cookieJar.deleteUri(Uri.parse("https://e-hentai.org"));
      EhNetwork().cookieJar.deleteUri(Uri.parse("https://exhentai.org"));
      ehentai.data['name'] = '';
    },
    infoItems: [
      AccountInfoItem(
        title: "已登录",
        // title: "用户名",
        // data: () => ComicSource.find('ehentai')!.data['name'] ?? '',
      ),
      AccountInfoItem(
        title: "",
        builder: (context) => const CookieManagementView(),
      ),
    ],
  ),
  comicTileBuilderOverride: (context, gallery, menuOptions) {
    return _EhGalleryTile(
      gallery: gallery as EhGalleryBrief,
      addonMenuOptions: menuOptions,
    );
  },
  explorePages: [
    ExplorePageData.named(
      title: "Eh主页",
      type: ExplorePageType.multiPageComicList,
      loadPage: _EhentaiGalleriesLoader(
        firstPageLoader: () => EhNetwork().getGalleries(EhNetwork().ehBaseUrl),
      ),
    ),
    ExplorePageData.named(
      title: "Eh热门",
      type: ExplorePageType.multiPageComicList,
      loadPage: _EhentaiGalleriesLoader(
        firstPageLoader: () =>
            EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/popular"),
      ),
    ),
  ],
  searchPageData: SearchPageData.named(
    loadPage: (keyword, page, options) {
      if (page == 1) {
        _EhentaiGalleriesLoader.clean();
        _EhentaiGalleriesLoader.instances['search:$keyword'] =
            _EhentaiGalleriesLoader(
          firstPageLoader: () => EhNetwork().search(
            keyword,
            fCats: int.tryParse(options.elementAtOrNull(0) ?? ''),
            startPages: int.tryParse(options.elementAtOrNull(1) ?? ''),
            endPages: int.tryParse(options.elementAtOrNull(2) ?? ''),
            minStars: int.tryParse(options.elementAtOrNull(3) ?? ''),
            expunged: int.tryParse(options.elementAtOrNull(4) ?? ''),
          ),
        );
      }
      return _EhentaiGalleriesLoader.instances['search:$keyword']!(page);
    },
    customOptionsBuilder: (context, initialValues, updater) {
      return _SearchOptions(initialValues, updater);
    },
    enableLanguageFilter: true,
    enableTagsSuggestions: true,
  ),
  comicPageBuilder: (context, id, cover) {
    return EhGalleryPage.fromLink(id, comicCover: cover);
  },
);

class _EhGalleryTile extends ComicTile {
  final EhGalleryBrief gallery;

  const _EhGalleryTile({required this.gallery, this.addonMenuOptions});

  List<String> _generateTags(List<String> tags) {
    List<String> res = [];
    List<String> res2 = [];
    for (var tag in tags) {
      if (tag.contains(":")) {
        var splits = tag.split(":");
        if (splits[0] == "language") {
          continue;
        }
        if (App.locale.languageCode != "zh") {
          res.add(
              splits[1].length > 32
                  ? "${splits[1].substring(0,20)}..."
                  : splits[1]
          );
          continue;
        }
        var lowLevelKey = ["character", "artist", "cosplayer", "group"];
        if (lowLevelKey.contains(splits[0])) {
          res2.add(TagsTranslation.translationTagWithNamespace(
              splits[1], splits[0]));
        } else {
          res.add(TagsTranslation.translationTagWithNamespace(
              splits[1], splits[0]));
        }
      } else {
        res.add(tag.translateTagsToCN);
      }
    }
    return res + res2;
  }

  @override
  int get maxLines => 2;
      // MediaQuery.of(App.globalContext!).size.width < 430 ? 1 : 2;

  @override
  ActionFunc? get read => () async {
        bool cancel = false;
        var dialog = showLoadingDialog(
          App.globalContext!,
          onCancel: () => cancel = true,
        );
        var res = await EhNetwork().getGalleryInfo(gallery.link);
        if (cancel) {
          return;
        }
        dialog.close();
        if (res.error) {
          showToast(message: res.errorMessage ?? "Error");
        } else {
          var history = await History.findOrCreate(res.data);
          App.globalTo(
                () => ComicReadingPage.ehentai(
              res.data,
              initialPage: history.page,
            ),
          );
        }
      };

  @override
  List<String>? get tags => _generateTags(gallery.tags);

  @override
  String get description => "${gallery.time}  ${gallery.type}";

  @override
  String? get badge => () {
        String? lang;
        if (gallery.tags.isNotEmpty &&
            gallery.tags[0].substring(0, 4) == "lang") {
          lang = gallery.tags[0].substring(9);
        } else if (gallery.tags.length > 1 &&
            gallery.tags.isNotEmpty &&
            gallery.tags[1].substring(0, 4) == "lang") {
          lang = gallery.tags[1].substring(9);
        }
        if (lang != null) {
          if (App.locale.languageCode == "zh") {
            lang = lang.translateTagsToCN;
          } else {
            lang = lang[0].toUpperCase() + lang.substring(1);
          }
        }
        return lang;
      }.call();

  @override
  Widget get image => AnimatedImage(
        image: CachedImageProvider(
          gallery.coverPath,
          headers: {
            "Cookie": EhNetwork().cookiesStr,
            "User-Agent": webUA,
            "Referer": EhNetwork().ehBaseUrl,
          },
        ),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
      );

  @override
  void onTap_() {
    App.mainNavigatorKey!.currentContext!.to(
      () => ComicPage(
        sourceKey: 'ehentai',
        id: gallery.link,
        cover: gallery.cover,
      ),
    );
  }

  @override
  Widget? buildSubDescription(context) {
    final s = gallery.stars ~/ 0.5;
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          for (int i = 0; i < s ~/ 2; i++)
            Icon(
              Icons.star,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
          if (s % 2 == 1)
            Icon(
              Icons.star_half,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
          for (int i = 0; i < (5 - s ~/ 2 - s % 2); i++)
            const Icon(
              Icons.star_border,
              size: 20,
            )
        ],
      ),
    );
  }

  @override
  String get subTitle => gallery.uploader;

  @override
  String get title => gallery.title;

  @override
  int? get pages => gallery.pages;

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.fromEhentai(gallery);

  @override
  final List<ComicTileMenuOption>? addonMenuOptions;

  @override
  String get comicID => gallery.link;
}

class _SearchOptions extends StatefulWidget {
  const _SearchOptions(this.initialValues, this.updater);

  final List<String> initialValues;

  final void Function(List<String> updater) updater;

  @override
  State<_SearchOptions> createState() => _SearchOptionsState();
}

class _SearchOptionsState extends State<_SearchOptions> {
  int ehFCats = 0;
  int? ehStartPage;
  int? ehEndPage;
  int? ehMinStars;
  int? ehExpunged;

  @override
  void initState() {
    ehFCats = int.tryParse(widget.initialValues.elementAtOrNull(0) ?? '') ?? 0;
    ehStartPage = int.tryParse(widget.initialValues.elementAtOrNull(1) ?? '');
    ehEndPage = int.tryParse(widget.initialValues.elementAtOrNull(2) ?? '');
    ehMinStars = int.tryParse(widget.initialValues.elementAtOrNull(3) ?? '');
    ehExpunged = int.tryParse(widget.initialValues.elementAtOrNull(4) ?? '');
    super.initState();
  }

  void update() {
    widget.updater([
      ehFCats.toString(),
      ehStartPage.toString(),
      ehEndPage.toString(),
      ehMinStars.toString(),
      ehExpunged.toString(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var isInDialog = context.findAncestorWidgetOfExactType<Dialog>() != null;
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
      height: 1.1,
    );
    var width = context.width - 16;
    if (width > 500) {
      width = 500;
    }

    Widget categoryWrap({required double maxWidth}) {
      const minWidth = 72.0;
      final items = (maxWidth ~/ minWidth).clamp(2, 5);
      const gap = 6.0;
      final chipW = (maxWidth - gap * (items - 1)) / items;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: List.generate(
          categories.length,
          (index) => buildCategoryItem(categories[index], index, chipW),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isInDialog ? 4 : 0, 0, 4, 6),
          child: Text(
            "高级选项".tl,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (!isInDialog)
          LayoutBuilder(
            builder: (context, constrains) =>
                categoryWrap(maxWidth: constrains.maxWidth),
          )
        else
          SizedBox(
            width: width,
            child: categoryWrap(maxWidth: width),
          ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                child: Text("浏览已删除的画廊".tl, style: labelStyle),
              ),
              MiuixSwitch(
                value: ehExpunged == 1,
                onChanged: (v) {
                  setState(() {
                    ehExpunged = v ? 1 : 0;
                  });
                  update();
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text("Pages", style: labelStyle),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: MiuixTextField(
                    label: "From",
                    useLabelAsPlaceholder: true,
                    singleLine: true,
                    keyboardType: TextInputType.number,
                    cornerRadius: 12,
                    insideMargin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: theme.textTheme.bodyMedium,
                    onChanged: (s) {
                      ehStartPage =
                          int.tryParse(s.replaceAll(RegExp("[^0-9]"), ""));
                      update();
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text("–", style: labelStyle),
              ),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: MiuixTextField(
                    label: "To",
                    useLabelAsPlaceholder: true,
                    singleLine: true,
                    keyboardType: TextInputType.number,
                    cornerRadius: 12,
                    insideMargin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: theme.textTheme.bodyMedium,
                    onChanged: (s) {
                      ehEndPage =
                          int.tryParse(s.replaceAll(RegExp("[^0-9]"), ""));
                      update();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Row(
            children: [
              Text("最少星星".tl, style: labelStyle),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Select(
                    initialValue: ehMinStars,
                    width: 132,
                    onChange: (i) {
                      ehMinStars = i;
                      update();
                    },
                    values: const ["0", "1", "2", "3", "4", "5"],
                    outline: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }

  static const categories = [
    "Misc",
    "Doujinshi",
    "Manga",
    "Artist CG",
    "Game CG",
    "Image Set",
    "Cosplay",
    "Asian Porn",
    "Non-H",
    "Western"
  ];

  Widget buildCategoryItem(String title, int value, double width) {
    bool disabled = ehFCats & (1 << value) == 1 << value;
    final scheme = Theme.of(context).colorScheme;
    final active = !disabled;
    return SizedBox(
      width: width,
      height: 32,
      child: MiuixPressable(
        feedbackType: MiuixPressFeedbackType.sink,
        shape: const MiuixSquircleBorder(cornerRadius: 10),
        onPressed: () {
          setState(() {
            disabled ? ehFCats -= (1 << value) : ehFCats += (1 << value);
          });
          update();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: active
                ? scheme.tertiaryContainer
                : scheme.tertiaryContainer.withOpacity(0.18),
            shape: const MiuixSquircleBorder(cornerRadius: 10),
          ),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              height: 1.0,
              color: active
                  ? scheme.onTertiaryContainer
                  : scheme.onSurface.withOpacity(0.45),
            ),
          ),
        ),
      ),
    );
  }

}

class _EhentaiGalleriesLoader {
  static final instances = <String, _EhentaiGalleriesLoader>{};

  static void clean() {
    var shouldRemove = <String>[];
    for (var i in instances.entries) {
      if (i.key.startsWith("search:")) {
        var keyword = i.key.replaceFirst("search:", "");
        if (StateController.findOrNull(
                tag: "ehentai search page with $keyword") ==
            null) {
          shouldRemove.add(i.key);
        }
      }
    }
    for (var i in shouldRemove) {
      instances.remove(i);
    }
  }

  _EhentaiGalleriesLoader({required this.firstPageLoader});

  final Future<Res<Galleries>> Function() firstPageLoader;

  String? nextPage;

  List<List<BaseComic>> cache = [];

  Future<Res<List<BaseComic>>> call(int page) async {
    if (page == 1 || cache.isEmpty) {
      var res = await firstRequest();
      if (res.error) {
        return Res.fromErrorRes(res);
      }
    }
    page--;
    while (page >= cache.length) {
      var res = await loadNext();
      if(res.error) {
        return Res.fromErrorRes(res);
      }
    }
    if (nextPage == null) {
      return Res(cache[page], subData: cache.length);
    }
    return Res(cache[page]);
  }

  Future<Res<void>> firstRequest() async {
    cache.clear();
    var res = await firstPageLoader();
    if (res.error) {
      return Res.fromErrorRes(res);
    }
    cache.add(res.data.galleries);
    nextPage = res.data.next;
    return const Res(null);
  }

  Future<Res<void>> loadNext() async {
    var res = await EhNetwork().getGalleries(nextPage!);
    if (res.error) {
      return Res.fromErrorRes(res);
    }
    cache.add(res.data.galleries);
    nextPage = res.data.next;
    return const Res(null);
  }
}
