import 'package:pica_comic/components/comment.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/components/components.dart';

class JmCommentsPageLogic extends StateController {
  JmCommentsPageLogic(this.totalComments);

  bool loading = true;
  List<Comment>? comments;
  String? message;
  int totalComments;
  int page = 1;
  var controller = TextEditingController();

  void change() {
    loading = !loading;
    update();
  }

  void get(String id, [String? mode]) async {
    var res = await jmNetwork.getComment(id, 1);
    if (res.error) {
      message = res.errorMessage;
      change();
    } else {
      comments = res.data;
      change();
    }
  }

  void retry() async {
    message = null;
    comments = null;
    loading = true;
    page = 1;
    update();
  }

  void loadMore(String id) async {
    if (totalComments <= comments!.length) {
      return;
    }
    var res = await jmNetwork.getComment(id, page + 1);
    totalComments = res.subData ?? totalComments;
    if (res.error) {
      return;
    } else {
      page++;
      comments!.addAll(res.data);
      update();
    }
  }

  void refresh_() {
    comments = null;
    message = null;
    page = 1;
    controller.text = "";
    loading = true;
    update();
  }
}

class JmCommentsPage extends StatelessWidget {
  const JmCommentsPage(this.id, this.totalComments,
      {this.mode, this.popUp = false, Key? key})
      : super(key: key);
  final String id;
  final bool popUp;
  final String? mode;
  final int totalComments;

  @override
  Widget build(BuildContext context) {
    Widget body = StateBuilder<JmCommentsPageLogic>(
        init: JmCommentsPageLogic(totalComments),
        builder: (logic) {
          if (logic.loading) {
            logic.get(id, mode);
            return const Center(
              child: MiuixInfiniteProgressIndicator(),
            );
          } else if (logic.comments == null) {
            return NetworkError(message: logic.message!, retry: logic.retry);
          } else {
            return Column(
              children: [
                Expanded(
                    child: CustomScrollView(
                  slivers: [
                    SliverList(
                        delegate: SliverChildBuilderDelegate(
                            childCount: logic.comments!.length,
                            (context, index) {
                      if (index == logic.comments!.length - 1) {
                        logic.loadMore(id);
                      }
                      return CommentTile(
                        avatarUrl: logic.comments![index].avatar,
                        name: logic.comments![index].name,
                        content: logic.comments![index].content,
                        comments: logic.comments![index].reply.length,
                        onTap: () => showReply(
                            context,
                            logic.comments![index].reply,
                            logic.comments![index]),
                        time: logic.comments![index].time,
                      );
                    })),
                    if (logic.totalComments > logic.comments!.length)
                      const SliverToBoxAdapter(
                        child: ListLoadingIndicator(),
                      ),
                    SliverPadding(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(App.globalContext!)
                                .padding
                                .bottom))
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
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: MiuixTextField(controller: logic.controller, label: "评论...".tl, useLabelAsPlaceholder: true, minLines: 1, maxLines: 5),
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
                          onPressed: () async {
                            showToast(message: "正在发送评论".tl);
                            var res = await JmNetwork()
                                .comment(id, logic.controller.text);
                            if (res.error) {
                              showToast(message: res.errorMessage!);
                            } else {
                              showToast(message: "成功发表评论".tl);
                              logic.refresh_();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
        });
    if (popUp) {
      return body;
    } else {
      return MiuixScaffold(topBar: MiuixSmallTopAppBar(title: "评论".tl, navigationIcon: MiuixIconButton(child: MiuixIcon(vector: MiuixIcons.os4.chevronBackward, size: 20), onPressed: () => Navigator.of(context).maybePop())), content: (padding) => Padding(padding: EdgeInsets.only(top: padding.top), child: body),
      );
    }
  }
}

void showReply(BuildContext context, List<Comment> comments, Comment replyTo) {
  if (comments.isEmpty) return;
  showSideBar(
      context,
      SingleChildScrollView(
        child: Column(
          children: [
            CommentTile(
              avatarUrl: replyTo.avatar,
              name: replyTo.name,
              content: replyTo.content,
              time: replyTo.time,
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: MiuixHorizontalDivider()),
            for (int index = 0; index < comments.length; index++)
              CommentTile(
                avatarUrl: comments[index].avatar,
                name: comments[index].name,
                content: comments[index].content,
                time: comments[index].time,
              )
          ],
        ),
      ),
      title: "回复".tl,
      showBarrier: false);
}

void showComments(BuildContext context, String id, int totalComments,
    [String? mode]) {
  showSideBar(
      context,
      JmCommentsPage(
        id,
        totalComments,
        popUp: true,
        mode: mode,
      ),
      title: "评论".tl);
}
