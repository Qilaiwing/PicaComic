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
    if (downloadManager.error) {
      setState(() {});
    } else if (downloadManager.downloading.length != comics.length) {
      rebuild();
    } else if (key.currentState != null) {
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

  Widget _buildStatusHeader(BuildContext context) {
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

    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final error = Theme.of(context).colorScheme.error;

    final active = downloadManager.isDownloading;
    final hasError = downloadManager.error;
    final tint = hasError ? error : (active ? primary : onSurface.withOpacity(0.55));

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: MiuixCard(
        cornerRadius: 16,
        insideMargin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                shape: const MiuixSquircleBorder(cornerRadius: 12),
                color: tint.withOpacity(0.14),
              ),
              child: MiuixIcon(
                vector: active
                    ? (MiuixIcons.extended.byName('download') ??
                        MiuixIcons.os4.download)
                    : (hasError
                        ? MiuixIcons.os4.close
                        : MiuixIcons.os4.pause),
                size: 18,
                tint: tint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
            ),
            if (downloadManager.downloading.isNotEmpty)
              MiuixPressable(
                shape: const StadiumBorder(),
                feedbackType: MiuixPressFeedbackType.sink,
                onPressed: () {
                  downloadManager.isDownloading
                      ? downloadManager.pause()
                      : downloadManager.start();
                  setState(() {});
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: ShapeDecoration(
                    shape: const StadiumBorder(),
                    color: primary.withOpacity(0.14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MiuixIcon(
                        vector: downloadManager.isDownloading
                            ? MiuixIcons.os4.pause
                            : (hasError
                                ? (MiuixIcons.extended.byName('refresh') ??
                                    MiuixIcons.os4.sort)
                                : MiuixIcons.os4.play),
                        size: 14,
                        tint: primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        downloadManager.isDownloading
                            ? "暂停".tl
                            : (hasError ? "重试".tl : "继续".tl),
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];
    for (var i in comics) {
      var tileKey = Key(i.id);
      if (i == comics.first) {
        tileKey = key;
      }
      tiles.add(_DownloadingTile(
        comic: i,
        cancel: () {
          showConfirmDialog(context, "取消".tl, "取消下载任务?".tl, () {
            setState(() {
              downloadManager.cancel(i.id);
            });
          });
        },
        onComicPositionChange: rebuild,
        key: tileKey,
      ));
    }

    return MiuixScaffold(
      content: (_) => SmoothCustomScrollView(
        slivers: [
          SliverAppbar(
            title: Text("下载管理器".tl),
            largeTitle: Text("下载管理器".tl),
          ),
          SliverToBoxAdapter(child: _buildStatusHeader(context)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => tiles[index],
              childCount: tiles.length,
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 20,
            ),
          ),
        ],
      ),
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
  void initState() {
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
    if (comic != DownloadManager().downloading.first) {
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
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: MiuixCard(
        cornerRadius: 16,
        insideMargin: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipPath(
              clipper: const ShapeBorderClipper(
                shape: MiuixSquircleBorder(cornerRadius: 12),
              ),
              child: SizedBox(
                width: 72,
                height: 96,
                child: AnimatedImage(
                  image: CachedImageProvider(comic.cover,
                      headers: {"User-Agent": webUA}),
                  width: 72,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comic.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      getProgressText(),
                      style: TextStyle(
                        fontSize: 12,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipPath(
                      clipper: const ShapeBorderClipper(
                        shape: StadiumBorder(),
                      ),
                      child: MiuixLinearProgressIndicator(
                        progress: value.clamp(0.0, 1.0),
                        height: 6,
                        colors: MiuixProgressIndicatorColors(
                          foregroundColor: primary,
                          disabledForegroundColor: primary,
                          backgroundColor: primary.withOpacity(0.14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AppTooltip(
                  message: "置顶".tl,
                  child: MiuixIconButton(
                    minWidth: 36,
                    minHeight: 36,
                    child: Icon(
                      Icons.vertical_align_top_rounded,
                      size: 19,
                      color: onSurface.withOpacity(0.75),
                    ),
                    onPressed: () {
                      DownloadManager().moveToFirst(comic);
                      widget.onComicPositionChange();
                    },
                  ),
                ),
                AppTooltip(
                  message: "取消".tl,
                  child: MiuixIconButton(
                    minWidth: 36,
                    minHeight: 36,
                    child: MiuixIcon(
                      vector: MiuixIcons.os4.close,
                      size: 18,
                      tint: onSurface.withOpacity(0.75),
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

    if (comic is EhDownloadingItem &&
        (comic as EhDownloadingItem).downloadType != 0) {
      status = "${_bytesToSize(downloadPages).split(' ').first}"
          "/${_bytesToSize(pagesCount!)}";
    }

    return "$status  $speedInfo";
  }
}