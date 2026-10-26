import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../network/eh_network/eh_main_network.dart';
import '../../network/eh_network/eh_models.dart';
import '../../network/res.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(topBar: MiuixSmallTopAppBar(title: "EH订阅".tl, navigationIcon: MiuixIconButton(child: MiuixIcon(vector: MiuixIcons.os4.chevronBackward, size: 20), onPressed: () => Navigator.of(context).maybePop()), actions: [
        MiuixTooltipBox(tooltip: (context, scope) => MiuixPlainTooltip(scope: scope, child: Text("更多".tl)), child: MiuixIconButton(
            child: const Icon(Icons.more_horiz),
            onPressed: (){
              Future.microtask(() => showMiuixDialog<void>(
                context: App.globalContext!,
                title: "订阅".tl,
                summary: "请在网页端管理订阅".tl,
                actionsBuilder: (context, close) => [
                  MiuixTextButton("返回".tl, onPressed: () => close()),
                ],
              ));
            },
          ),
        )
      ]), content: (padding) => Padding(padding: EdgeInsets.only(top: padding.top), child: EhSubscriptionComics()));
  }
}


class PageData{
  Galleries? galleries;
  int page = 1;
  Map<int, List<EhGalleryBrief>> comics = {};
}

class EhSubscriptionComics extends ComicsPage<EhGalleryBrief>{
  EhSubscriptionComics({super.key});

  final data = PageData();

  @override
  Future<Res<List<EhGalleryBrief>>> getComics(int i) async{
    if(data.galleries == null){
      Res<Galleries> res = await EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/watched");
      if(res.error){
        return Res(null, errorMessage: res.errorMessage);
      }else{
        data.galleries = res.data;
        data.comics[1] = [];
        data.comics[1]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
    }
    if(data.comics[i] != null){
      return Res(data.comics[i]!);
    }else{
      while(data.comics[i] == null){
        data.page++;
        if(! await EhNetwork().getNextPageGalleries(data.galleries!)){
          return const Res(null, errorMessage: "网络错误");
        }
        data.comics[data.page] = [];
        data.comics[data.page]!.addAll(data.galleries!.galleries);
        data.galleries!.galleries.clear();
      }
      return Res(data.comics[i]);
    }
  }

  @override
  String? get tag => "EhSubscriptionPage";

  @override
  String? get title => null;

  @override
  String get sourceKey => 'ehentai';
}