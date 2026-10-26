import 'package:flutter/material.dart';
import 'package:pica_comic/components/comment.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';

class NhentaiCommentsPage extends StatefulWidget {
  const NhentaiCommentsPage(this.id, {super.key});

  final String id;

  @override
  State<NhentaiCommentsPage> createState() => _NhentaiCommentsPageState();
}

class _NhentaiCommentsPageState extends State<NhentaiCommentsPage> {
  bool loading = true;
  List<NhentaiComment>? comments;
  String? message;
  var controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (loading) {
      get();
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (message != null) {
      return NetworkError(
        message: message!,
        retry: () => setState(
          () {
            loading = true;
            message = null;
            comments = null;
          },
        ),
        withAppbar: false,
      );
    } else {
      return Column(
        children: [
          Expanded(
              child: CustomScrollView(
            slivers: [
              SliverList(
                  delegate: SliverChildBuilderDelegate(
                      childCount: comments!.length, (context, index) {
                return CommentTile(
                  avatarUrl: comments![index].avatar,
                  name: comments![index].userName,
                  content: comments![index].content,
                );
              })),
              SliverPadding(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.bottom))
            ],
          )),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E22)
                  : const Color(0xFFF9F9FA),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0x18FFFFFF)
                      : const Color(0x0E000000),
                  width: 0.8,
                ),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: ShapeDecoration(
                shape: const MiuixSquircleBorder(cornerRadius: 22),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(
                        Theme.of(context).brightness == Brightness.dark ? 0.45 : 0.65),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: false,
                      controller: controller,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: "评论...".tl,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  MiuixIconButton(
                    minWidth: 36,
                    minHeight: 36,
                    child: MiuixIcon(
                      vector: MiuixIcons.extended.byName('send') ??
                          MiuixIcons.os4.share,
                      size: 19,
                      tint: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      showToast(message: "未完成");
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  void get() async {
    var res = await NhentaiNetwork().getComments(widget.id);
    setState(() {
      loading = false;
      if (res.error) {
        message = res.errorMessageWithoutNull;
      } else {
        comments = res.data;
      }
    });
  }
}

void showComments(BuildContext context, String id) {
  showSideBar(context, NhentaiCommentsPage(id), title: "评论".tl);
}
