import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/tools/save_image.dart';
import 'package:pica_comic/tools/translations.dart';

MiuixSmallTopAppBar _buildImageTopBar(BuildContext context,
    {List<Widget>? actions}) {
  return MiuixSmallTopAppBar(color: MiuixTheme.of(context).colors.background, 
    title: "图片".tl,
    navigationIcon: MiuixIconButton(
      child: MiuixIcon(
        vector: MiuixIcons.os4.chevronBackward,
        size: 20,
      ),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    actions: actions,
  );
}

Widget _buildLoading(BuildContext context, ImageChunkEvent? event) {
  return Container(
    decoration: const BoxDecoration(color: Colors.black),
    child: const Center(
      child: MiuixCircularProgressIndicator(),
    ),
  );
}

class ShowImagePage extends StatelessWidget {
  const ShowImagePage(this.url, {super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(
      topBar: _buildImageTopBar(context),
      content: (padding) => Padding(
        padding: EdgeInsets.only(top: padding.top),
        child: PhotoView(
          minScale: PhotoViewComputedScale.contained * 0.9,
          imageProvider: CachedImageProvider(url),
          loadingBuilder: _buildLoading,
        ),
      ),
    );
  }
}

class ShowImagePageWithHero extends StatelessWidget {
  const ShowImagePageWithHero(this.url, this.tag, {super.key});

  final String url;

  final String tag;

  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(
      topBar: _buildImageTopBar(context, actions: [
        AppTooltip(
          message: "保存".tl,
          child: MiuixIconButton(
            child: const Icon(Icons.download),
            onPressed: () async {
              var file = await ImageManager().getFile(url);
              if (file != null) {
                saveImage(file);
              }
            },
          ),
        ),
      ]),
      content: (padding) => Padding(
        padding: EdgeInsets.only(top: padding.top),
        child: Hero(
          tag: tag,
          child: PhotoView(
            minScale: PhotoViewComputedScale.contained * 0.9,
            imageProvider: CachedImageProvider(url),
            loadingBuilder: _buildLoading,
          ),
        ),
      ),
    );
  }
}