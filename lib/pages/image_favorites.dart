import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_loader/base_image_provider.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/components/components.dart';

import 'reader/comic_reading_page.dart';

class ImageFavoritesPage extends StatefulWidget {
  const ImageFavoritesPage({super.key});

  @override
  State<ImageFavoritesPage> createState() => _ImageFavoritesPageState();
}

class _ImageFavoritesPageState extends State<ImageFavoritesPage> {
  @override
  Widget build(BuildContext context) {
    return StateBuilder(
      tag: "image_favorites_page",
      init: SimpleController(),
      builder: (controller) {
        final images = ImageFavoriteManager.getAll();
        return Scaffold(
          body: SmoothCustomScrollView(
            slivers: [
              SliverAppbar(
                title: Text("图片收藏".tl),
                largeTitle: Text("图片收藏".tl),
              ),
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => FavoriteImageTile(images[index]),
                  childCount: images.length,
                ),
                gridDelegate:
                    SliverGridDelegateWithComics(true, appdata.settings[74]),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FavoriteImageTile extends StatelessWidget {
  const FavoriteImageTile(this.image, {super.key});

  final ImageFavorite image;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Material(
        color: Colors.transparent,
        shape: const MiuixSquircleBorder(cornerRadius: 14),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        child: Container(
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
            color: Theme.of(context).colorScheme.secondaryContainer,
            shadows: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: Image(
                  image: _ImageProvider(image),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                        Colors.black.withOpacity(0.72),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 8),
                  child: Text(
                    image.title.replaceAll("\n", ""),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13.0,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    onLongPress: onLongTap,
                    onSecondaryTapDown: onSecondaryTap,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onTap() {
    var type = image.id.split("-")[0];
    _readWithKey(type, image.id.replaceFirst("$type-", ""), image.ep, image.page,
        image.title, image.otherInfo);
  }

  void _readWithKey(String key, String target, int ep, int page, String title,
      Map<String, dynamic> otherInfo) async {
    switch (key) {
      case "picacg":
        App.globalTo(() => ComicReadingPage.picacg(
            target, ep, List.from(otherInfo["eps"]), title,
            initialPage: page));
      case "ehentai":
        App.globalTo(
          () => ComicReadingPage.ehentai(
            Gallery.fromJson(otherInfo["gallery"]),
            initialPage: page,
          ),
        );
      case "jm":
        App.globalTo(
          () => ComicReadingPage(
            JmReadingData(
              title,
              target,
              List.from(otherInfo["eps"]),
              List.from(
                otherInfo["jmEpNames"],
              ),
            ),
            page,
            ep,
          ),
        );
      case "hitomi":
        App.globalTo(
          () => ComicReadingPage(
            HitomiReadingData(
              title,
              target,
              (otherInfo["hitomi"] as List)
                  .map((e) => HitomiFile.fromMap(e))
                  .toList(),
              target,
            ),
            page,
            0,
          ),
        );
      case "htManga":
      case "htmanga":
        App.globalTo(
          () => ComicReadingPage.htmanga(target, title, initialPage: page),
        );
      case "nhentai":
        App.globalTo(
          () => ComicReadingPage.nhentai(target, title, initialPage: page),
        );
      default:
        var source = ComicSource.find(key);
        if (source == null) throw "Unknown source $key";
        App.globalTo(
          () => ComicReadingPage(
            CustomReadingData(
              target,
              title,
              source,
              Map.from(otherInfo["eps"]),
            ),
            page,
            ep,
          ),
        );
    }
  }

  void onLongTap() {
    showConfirmDialog(App.globalContext!, "确认删除".tl, "要删除这个图片吗".tl, delete);
  }

  void delete() {
    ImageFavoriteManager.delete(image);
    showToast(message: "删除成功".tl);
    StateController.findOrNull(tag: "image_favorites_page")?.update();
  }

  void onSecondaryTap(TapDownDetails details) {
    showDesktopMenu(App.globalContext!, details.globalPosition, [
      DesktopMenuEntry(text: "查看".tl, onClick: onTap),
      DesktopMenuEntry(text: "删除".tl, onClick: delete),
    ]);
  }
}

class _ImageProvider extends BaseImageProvider<_ImageProvider> {
  _ImageProvider(this.image);

  final ImageFavorite image;

  @override
  String get key => image.id + image.ep.toString() + image.page.toString();

  @override
  Future<Uint8List> load(StreamController<ImageChunkEvent> chunkEvents) async {
    // 收藏时存的是文件名，实际文件在 data/images/ 下；
    // 之前直接拿文件名去 existsSync()，永远判为不存在，每次都要重新联网下载。
    final localFile = File("${App.dataPath}/images/${image.imagePath}");
    if (localFile.existsSync()) {
      return await localFile.readAsBytes();
    } else {
      var type = image.id.split("-")[0];
      Stream<DownloadProgress> stream;
      switch (type) {
        case "ehentai":
          stream = ImageManager().getEhImageNew(
              Gallery.fromJson(image.otherInfo["gallery"]), image.page);
        case "jm":
          stream = ImageManager().getJmImage(image.otherInfo["url"], null,
              epsId: image.otherInfo["epsId"],
              scrambleId: "220980",
              bookId: image.otherInfo["bookId"]);
        case "hitomi":
          stream = ImageManager().getHitomiImage(
              HitomiFile.fromMap(image.otherInfo["hitomi"][image.page - 1]),
              image.otherInfo["galleryId"]);
        default:
          stream = ImageManager().getImage(image.otherInfo["url"]);
      }
      DownloadProgress? finishProgress;
      await for (var progress in stream) {
        if (progress.currentBytes == progress.expectedBytes) {
          finishProgress = progress;
        }
        chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: progress.currentBytes,
            expectedTotalBytes: progress.expectedBytes));
      }
      var file = finishProgress!.getFile();
      var data = await file.readAsBytes();
      var file2 = File("${App.dataPath}/images/${image.imagePath}");
      if (!file2.existsSync()) {
        await file2.create(recursive: true);
      }
      await file2.writeAsBytes(data);
      return data;
    }
  }

  @override
  Future<_ImageProvider> obtainKey(ImageConfiguration configuration) async {
    return this;
  }
}
