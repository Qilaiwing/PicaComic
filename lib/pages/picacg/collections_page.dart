import 'package:flutter/material.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';

class CollectionPageLogic extends StateController {
  bool isLoading = true;
  var c1 = <ComicItemBrief>[];
  var c2 = <ComicItemBrief>[];
  bool status = true;
  String? message;

  void change() {
    isLoading = !isLoading;
    update();
  }

  void get() async {
    var collections = await network.getCollection();
    if (collections.success) {
      c1 = collections.data[0];
      c2 = collections.data[1];
      change();
    } else {
      status = false;
      message = collections.errorMessageWithoutNull;
      change();
    }
  }
}

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StateBuilder<CollectionPageLogic>(
      init: CollectionPageLogic(),
      builder: (logic) {
        if (logic.isLoading) {
          network.getCollection().then((collections) {
            if (collections.success) {
              logic.c1 = collections.data[0];
              logic.c2 = collections.data[1];
              logic.change();
            } else {
              logic.status = false;
              logic.change();
            }
          });
          return MiuixScaffold(topBar: MiuixSmallTopAppBar(title: "推荐".tl, navigationIcon: MiuixIconButton(child: MiuixIcon(vector: MiuixIcons.os4.chevronBackward, size: 20), onPressed: () => Navigator.of(context).maybePop())), content: (padding) => Padding(padding: EdgeInsets.only(top: padding.top), child: const Center(
              child: MiuixInfiniteProgressIndicator(),
            )),
          );
        } else if (logic.status) {
          return MiuixScaffold(content: (_) => SmoothCustomScrollView(
              slivers: [
                SliverAppbar(title: Text("推荐".tl)),
                SliverGridComics(
                  comics: logic.c1 + logic.c2,
                  sourceKey: 'picacg',
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(App.globalContext!).padding.bottom + 20,
                  ),
                )
              ],
            ),
          );
        } else {
          return MiuixScaffold(topBar: MiuixSmallTopAppBar(title: "推荐".tl, navigationIcon: MiuixIconButton(child: MiuixIcon(vector: MiuixIcons.os4.chevronBackward, size: 20), onPressed: () => Navigator.of(context).maybePop())), content: (padding) => Padding(padding: EdgeInsets.only(top: padding.top), child: NetworkError(
              message: logic.message ?? "网络错误".tl,
              retry: () {
                logic.status = true;
                logic.change();
              },
            )),
          );
        }
      },
    );
  }
}
