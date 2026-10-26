import 'package:flutter/material.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/net_fav_to_local.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';

import '../../base.dart';
import '../../network/base_comic.dart';
import '../../network/res.dart';

class _ChooseNetworkFolderWidget extends StatefulWidget {
  const _ChooseNetworkFolderWidget();

  @override
  State<_ChooseNetworkFolderWidget> createState() =>
      _ChooseNetworkFolderWidgetState();
}

class LoadComicClass {
  NetToLocalEhPageData data = NetToLocalEhPageData();

  Future<Res<List<BaseComic>>> loadComic(
      FavoriteData fData, int i, String folder) async {
    if (fData.key == "ehentai") {
      if (data.galleries == null) {
        Res<Galleries> res = await EhNetwork().getGalleries(
            "${EhNetwork().ehBaseUrl}/favorites.php?favcat=$folder",
            favoritePage: true);
        if (res.error) {
          return Res(null, errorMessage: res.errorMessage);
        } else {
          data.galleries = res.data;
          data.comics[1] = [];
          data.comics[1]!.addAll(data.galleries!.galleries);
          data.galleries!.galleries.clear();
        }
      }
      if (data.comics[i] != null) {
        return Res(data.comics[i]!);
      } else {
        while (data.comics[i] == null) {
          data.page++;
          if (!await EhNetwork().getNextPageGalleries(data.galleries!)) {
            return Res(null, errorMessage: "网络错误".tl);
          }
          data.comics[data.page] = [];
          data.comics[data.page]!.addAll(data.galleries!.galleries);
          data.galleries!.galleries.clear();
        }
        return Res(data.comics[i]);
      }
    }
    return fData.loadComic(i, folder);
  }
}

class _ChooseNetworkFolderWidgetState
    extends State<_ChooseNetworkFolderWidget> {
  late final List<FavoriteData> _folders;

  late List<bool> isExpanded;

  String? selected;
  bool agreeSync = false;

  Map<String, Map<String, String>> multiFolderData = {
    "ehentai": Map.fromIterables(
        List.generate(10, (index) => index.toString()), EhNetwork().folderNames)
  };

  @override
  void initState() {
    var folders = <FavoriteData>[];
    for (var key in appdata.settings[68].split(',')) {
      folders.add(getFavoriteData(key));
    }
    _folders = folders;
    isExpanded = _folders.map((e) => false).toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(
 topBar: MiuixSmallTopAppBar(color: MiuixTheme.of(context).colors.background, 
 title: "选择收藏夹".tl,
 navigationIcon: Navigator.of(context).canPop() ? MiuixIconButton(onPressed: () => Navigator.of(context).maybePop(), child: const Icon(Icons.arrow_back)) : null,
 actions: [
          MiuixIconButton(onPressed: context.pop, child: const Icon(Icons.close))
        ],
),
 content: (padding) => ScrollUnderBar(
 padding: padding,
 child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: padding.top),
              child: Column(
                children: _folders.map((e) => buildItem(e)).toList(),
              ),
            ),
          ),
          const MiuixHorizontalDivider(),
          SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(
                  width: 8,
                ),
                MiuixCheckbox(
                    value: agreeSync,
                    onChanged: (b) {
                      setState(() {
                        agreeSync = b ?? false;
                      });
                    }),
                Text("支持下拉更新".tl),
                const Spacer(),
                MiuixButton(colors: MiuixButtonDefaults.buttonColorsPrimary(context), onPressed: onConfirm, child: Text("继续".tl)),
                const SizedBox(
                  width: 24,
                ),
              ],
            ),
          ),
          if (UiMode.m1(context))
            SizedBox(height: MediaQuery.of(context).padding.bottom)
        ],
      ),
 ),
);
  }

  Widget buildItem(FavoriteData data) {
    final i = _folders.indexOf(data);
    final expand = isExpanded[i];
    return MiuixCard(
      insideMargin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiuixBasicComponent(
            title: data.title,
            endActions: [
              AnimatedRotation(
                turns: expand ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.expand_more),
              ),
            ],
            onClick: () => setState(() => isExpanded[i] = !expand),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: expand ? buildBody(data) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ).paddingHorizontal(12).paddingVertical(4);
  }

  Widget buildTile(String key, String title) {
    return MiuixRadioButtonPreference(
        title: title,
        selected: selected == key,
        onClick: () {
          setState(() {
            selected = key;
          });
        });
  }

  Widget buildBody(FavoriteData data) {
    if (!data.multiFolder) {
      return buildTile(data.key, data.title);
    } else {
      return StatefulBuilder(builder: (context, updater) {
        if (multiFolderData[data.key] == null) {
          if (isExpanded[_folders.indexOf(data)]) {
            data.loadFolders!().then((value) {
              if (value.error) {
                showToast(message: "网络错误".tl);
              } else {
                updater(() {
                  multiFolderData[data.key] = value.data;
                });
              }
            });
          }
          return const SizedBox(
            height: 56,
            width: double.infinity,
            child: Center(
              child: MiuixCircularProgressIndicator(),
            ),
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: multiFolderData[data.key]!
                .entries
                .map((e) => buildTile("${data.key}:${e.key}", e.value))
                .toList(),
          );
        }
      });
    }
  }

  void onConfirm() {
    var key = selected!.split(":").first;
    var folderId = selected!.split(":").last;
    var data = _folders.firstWhere((element) => element.key == key);
    String name;
    if (!data.multiFolder) {
      name = data.title;
    } else {
      name = multiFolderData[data.key]![folderId]!;
      if (data.key == "ehentai") {
        name = name.substring(0, name.lastIndexOf("("));
      }
    }
    App.globalBack();
    final loadComicObj = LoadComicClass();
    startConvert<BaseComic>(
        (page) => loadComicObj.loadComic(data, page, folderId),
        null,
        App.globalContext!,
        name,
        (comic) => FavoriteItem.fromBaseComic(comic),
        data.key,
        agreeSync,
        {"folderId": folderId});
  }
}

void networkToLocal() {
  showPopUpWidget(App.globalContext!, const _ChooseNetworkFolderWidget());
}

class NetToLocalEhPageData {
  Galleries? galleries;
  int page = 1;
  Map<int, List<EhGalleryBrief>> comics = {};
}
