import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/eh_network/eh_download_model.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/components/components.dart';

class DownloadingPage extends StatefulWidget {
  const DownloadingPage({Key? key}) : super(key: key);

  @override
  State<DownloadingPage> createState() => _DownloadingPageState();
}

class _DownloadingPageState extends State<DownloadingPage> {
  var comics = <DownloadingItem>[];

  @override
  void dispose() {
    downloadManager.removeListener(onChange);
    super.dispose();
  }

  @override
  void initState() {
    downloadManager.addListener(onChange);
    comics = List.from(downloadManager.downloading);
    super.initState();
  }

  void onChange() {
    if(downloadManager.error) {
      setState(() {});
    } else if (downloadManager.downloading.length != comics.length) {
      rebuild();
    } else if (key.currentState != null){
      key.currentState!.updateUi();
    }
  }

  void rebuild() {
    key = GlobalKey<_DownloadingTileState>();
    setState(() {
      comics = List.from(downloadManager.downloading);
    });
  }

  var key = GlobalKey<_DownloadingTileState>();

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[];
    for (var i in comics) {
      var key = Key(i.id);
      if(i == comics.first) {
        key = this.key;
      }

      widgets.add(_DownloadingTile(
        comic: i,
        cancel: () {
          showConfirmDialog(context, "取消".tl, "取消下载任务?".tl, () {
            setState(() {
              downloadManager.cancel(i.id);
            });
          });
        },
        onComicPositionChange: rebuild,
        key: key,
      ));
    }

    final body = ListView.builder(
        itemCount: downloadManager.downloading.length + 1,
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          if (index == 0) {
            String downloadStatus;
            if (downloadManager.isDownloading) {
              downloadStatus = " 下载中".tl;
            } else if (downloadManager.downloading.isNotEmpty) {
              downloadStatus = " 已暂停".tl;
            } else {
              downloadStatus = "";
            }

            String downloadTaskText = "@length 项下载任务".tlParams(
                {"length": downloadManager.downloading.length.toString()});

            String displayText = downloadManager.error
                ? "下载出错".tl
                : downloadTaskText + downloadStatus;

            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primary = Theme.of(context).colorScheme.primary;

            return Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: ShapeDecoration(
                shape: const MiuixSquircleBorder(cornerRadius: 14),
                color: isDark
                    ? const Color(0xFF222226)
                    : const Color(0xFFF4F4F6),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      shape: const MiuixSquircleBorder(cornerRadius: 10),
                      color: downloadManager.isDownloading
                          ? primary.withOpacity(isDark ? 0.25 : 0.12)
                          : (downloadManager.error
                              ? Colors.red.withOpacity(isDark ? 0.25 : 0.12)
                              : const Color(0x18000000)),
                    ),
                    child: MiuixIcon(
                      vector: downloadManager.isDownloading
                          ? (MiuixIcons.extended.byName('download') ?? MiuixIcons.os4.download)
                          : (downloadManager.error
                              ? MiuixIcons.os4.close
                              : MiuixIcons.os4.pause),
                      size: 17,
                      tint: downloadManager.isDownloading
                          ? primary
                          : (downloadManager.error ? Colors.red : Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayText,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (downloadManager.downloading.isNotEmpty)
                    Material(
                      color: Colors.transparent,
                      shape: const StadiumBorder(),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          downloadManager.isDownloading
                              ? downloadManager.pause()
                              : downloadManager.start();
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: ShapeDecoration(
                            shape: const StadiumBorder(),
                            color: primary.withOpacity(isDark ? 0.25 : 0.12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MiuixIcon(
                                vector: downloadManager.isDownloading
                                    ? MiuixIcons.os4.pause
                                    : (downloadManager.error
                                        ? MiuixIcons.os4.sort
                                        : MiuixIcons.os4.play),
                                size: 14,
                                tint: primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                downloadManager.isDownloading
                                    ? "暂停".tl
                                    : (downloadManager.error
                                        ? "重试".tl
                                        : "继续".tl),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          } else {
            return widgets[index - 1];
          }
        });

    return PopUpWidgetScaffold(
      title: "下载管理器".tl,
      body: body,
    );
  }
}

class _DownloadingTile extends StatefulWidget {
  const _DownloadingTile({
    required this.comic,
    required this.cancel,
    required this.onComicPositionChange,
    super.key,
  });

  final DownloadingItem comic;

  final void Function() cancel;

  final void Function() onComicPositionChange;

  @override
  State<_DownloadingTile> createState() => _DownloadingTileState();
}

class _DownloadingTileState extends State<_DownloadingTile> {
  late DownloadingItem comic;

  double value = 0.0;
  int downloadPages = 0;
  int? pagesCount;
  int? speed;

  @override
  initState() {
    super.initState();
    comic = widget.comic;
    updateStatistic();
  }

  @override
  void didUpdateWidget(covariant _DownloadingTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.comic != comic) {
      setState(() {
        comic = widget.comic;
      });
    }
  }

  void updateStatistic() {
    if(comic != DownloadManager().downloading.first) {
      return;
    }
    comic = DownloadManager().downloading.first;
    speed = comic.currentSpeed;
    downloadPages = comic.downloadedPages;
    pagesCount = comic.totalPages;
    if (pagesCount == 0) {
      pagesCount = null;
    }
    if (pagesCount != null && pagesCount! > 0) {
      value = downloadPages / pagesCount!;
    }
  }

  void updateUi() {
    setState(() {
      updateStatistic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
      child: Container(
        height: 114,
        padding: const EdgeInsets.all(8),
        decoration: ShapeDecoration(
          shape: MiuixSquircleBorder(
            cornerRadius: 16,
            side: BorderSide(
              color: isDark ? const Color(0x18FFFFFF) : const Color(0x0A000000),
              width: 0.6,
            ),
          ),
          color: isDark ? const Color(0xFF222226) : const Color(0xFFF7F7F9),
        ),
        child: Row(
          children: [
            Container(
              width: 74,
              height: double.infinity,
              decoration: const ShapeDecoration(
                shape: MiuixSquircleBorder(cornerRadius: 10),
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedImage(
                image: CachedImageProvider(comic.cover,
                    headers: {"User-Agent": webUA}),
                width: 74,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comic.title,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    getProgressText(),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 5,
                      backgroundColor: isDark
                          ? const Color(0x22FFFFFF)
                          : const Color(0x18000000),
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Tooltip(
                  message: "置顶".tl,
                  child: MiuixIconButton(
                    minWidth: 34,
                    minHeight: 34,
                    child: const Icon(
                      Icons.vertical_align_top_rounded,
                      size: 19,
                    ),
                    onPressed: () {
                      DownloadManager().moveToFirst(comic);
                      widget.onComicPositionChange();
                    },
                  ),
                ),
                Tooltip(
                  message: "取消".tl,
                  child: MiuixIconButton(
                    minWidth: 34,
                    minHeight: 34,
                    child: MiuixIcon(
                      vector: MiuixIcons.os4.close,
                      size: 18,
                    ),
                    onPressed: widget.cancel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _bytesToSize(int bytes) {
    if (bytes < 1024) {
      return "$bytes B";
    } else if (bytes < 1024 * 1024) {
      return "${(bytes / 1024).toStringAsFixed(2)} KB";
    } else if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / 1024 / 1024).toStringAsFixed(2)} MB";
    } else {
      return "${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB";
    }
  }

  String getProgressText() {
    if (pagesCount == null) {
      if (comic == DownloadManager().downloading.first) {
        return "获取图片信息...".tl;
      } else {
        return "";
      }
    }

    String speedInfo = "";
    if (speed != null) {
      speedInfo = "${_bytesToSize(speed!)}/s";
    }

    String status = "${"已下载".tl}$downloadPages/$pagesCount";

    if (comic is EhDownloadingItem
        && (comic as EhDownloadingItem).downloadType != 0) {
      status = "${_bytesToSize(downloadPages).split(' ').first}"
          "/${_bytesToSize(pagesCount!)}";
    }

    return "$status  $speedInfo";
  }
}
