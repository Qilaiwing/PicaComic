import 'package:pica_comic/components/comment.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';

class CommentsPageLogic extends StateController {
  bool isLoading = true;
  var comments = Comments([], "", 0, 0);
  bool sending = false;
  var controller = TextEditingController();

  void change() {
    isLoading = !isLoading;
    update();
  }
}

class CommentsPage extends StatelessWidget {
  final String id;
  final String type;
  final bool popUp;

  const CommentsPage(this.id,
      {Key? key, this.type = "comics", this.popUp = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget body = StateBuilder<CommentsPageLogic>(
      init: CommentsPageLogic(),
      builder: (logic) {
        if (logic.isLoading) {
          network.getCommends(id, type: type).then((c) {
            logic.comments = c;
            logic.change();
          });
          return const Center(
            child: MiuixInfiniteProgressIndicator(),
          );
        } else if (logic.comments.loaded == 0) {
          return NetworkError(
            message: "网络错误".tl,
            retry: () => logic.change(),
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
                          childCount: logic.comments.comments.length,
                          (context, index) {
                    if (index == logic.comments.comments.length - 1 &&
                        logic.comments.pages != logic.comments.loaded) {
                      network
                          .loadMoreCommends(logic.comments, type: type)
                          .then((t) {
                        logic.update();
                      });
                    }
                    var comment = logic.comments.comments[index];
                    var subInfo =
                        "${comment.time.substring(0, 10)}  ${comment.time.substring(11, 19)}";
                    return CommentTile(
                      avatarUrl: comment.avatarUrl,
                      name: comment.name,
                      content: comment.text,
                      slogan: comment.slogan,
                      level: comment.level,
                      time: subInfo,
                      like: () {
                        network.likeOrUnlikeComment(comment.id);
                        comment.isLiked = !comment.isLiked;
                        comment.isLiked ? comment.likes++ : comment.likes--;
                        logic.update();
                      },
                      likes: comment.likes,
                      liked: comment.isLiked,
                      comments: comment.reply,
                      onTap: () => showReply(context, comment.id, comment),
                    );
                  })),
                  if (logic.comments.loaded != logic.comments.pages &&
                      logic.comments.pages != 1)
                    const SliverToBoxAdapter(
                      child: ListLoadingIndicator(),
                    ),
                  SliverPadding(
                      padding: EdgeInsets.only(
                          top:
                              MediaQuery.of(App.globalContext!).padding.bottom))
                ],
              )),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  8 + MediaQuery.of(context).padding.bottom,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: MiuixTextField(controller: logic.controller, label: "评论...".tl, useLabelAsPlaceholder: true, minLines: 1, maxLines: 4),
                        ),
                        logic.sending
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: MiuixInfiniteProgressIndicator(size: 20),
                                ),
                              )
                            : MiuixIconButton(
                                minWidth: 36,
                                minHeight: 36,
                                child: MiuixIcon(
                                  vector: MiuixIcons.extended.byName('send') ??
                                      MiuixIcons.os4.share,
                                  size: 19,
                                  tint: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () async {
                                  if (logic.controller.text.length < 2) {
                                    showToast(message: "评论至少需要2个字".tl);
                                    return;
                                  }
                                  logic.sending = true;
                                  logic.update();
                                  var b = await network.comment(
                                      id, logic.controller.text, false);
                                  if (b) {
                                    logic.controller.text = "";
                                    logic.sending = false;
                                    var res = await network.getCommends(id);
                                    logic.comments = Comments([], id, 1, 1);
                                    logic.update();
                                    await Future.delayed(
                                        const Duration(milliseconds: 200));
                                    logic.comments = res;
                                    logic.update();
                                  } else {
                                    showToast(message: "网络错误".tl);
                                    logic.sending = false;
                                    logic.update();
                                  }
                                },
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      },
    );

    if (popUp) {
      return body;
    } else {
      return MiuixScaffold(topBar: MiuixSmallTopAppBar(color: MiuixTheme.of(context).colors.background, title: "评论".tl, navigationIcon: MiuixIconButton(child: MiuixIcon(vector: MiuixIcons.os4.chevronBackward, size: 20), onPressed: () => Navigator.of(context).maybePop())), content: (padding) => Padding(padding: EdgeInsets.only(top: padding.top), child: body),
      );
    }
  }
}

void showComments(BuildContext context, String id) {
  showSideBar(
      context,
      CommentsPage(
        id,
        popUp: true,
      ),
      title: "评论".tl);
}

class ReplyPageLogic extends StateController {
  bool isLoading = true;
  var comments = Reply("", 0, 1, []);
  bool sending = false;
  var controller = TextEditingController();

  void change() {
    isLoading = !isLoading;
    update();
  }
}

class ReplyPage extends StatelessWidget {
  final String id;
  final Comment replyTo;
  final bool popUp;

  const ReplyPage(this.id, this.replyTo, {this.popUp = false, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var body = StateBuilder<ReplyPageLogic>(
      init: ReplyPageLogic(),
      builder: (commentsPageLogic) {
        if (commentsPageLogic.isLoading) {
          network.getReply(id).then((c) {
            commentsPageLogic.comments = c;
            commentsPageLogic.change();
          });
          return const Center(
            child: MiuixInfiniteProgressIndicator(),
          );
        } else if (commentsPageLogic.comments.loaded == 0) {
          return NetworkError(
            message: "网络错误".tl,
            retry: () => commentsPageLogic.change(),
            withAppbar: false,
          );
        } else {
          return Column(
            children: [
              Expanded(
                  child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: CommentTile(
                      avatarUrl: replyTo.avatarUrl,
                      name: replyTo.name,
                      content: replyTo.text,
                      time:
                          "${replyTo.time.substring(0, 10)}  ${replyTo.time.substring(11, 19)}",
                      slogan: replyTo.slogan,
                      level: replyTo.level,
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.all(2)),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Padding(padding: EdgeInsets.symmetric(vertical: 8), child: MiuixHorizontalDivider()),
                    ),
                  ),
                  SliverList(
                      delegate: SliverChildBuilderDelegate(
                          childCount: commentsPageLogic
                              .comments.comments.length, (context, index) {
                    if (index ==
                            commentsPageLogic.comments.comments.length - 1 &&
                        commentsPageLogic.comments.total !=
                            commentsPageLogic.comments.loaded) {
                      network
                          .getMoreReply(commentsPageLogic.comments)
                          .then((t) {
                        commentsPageLogic.update();
                      });
                    }
                    var comment = commentsPageLogic.comments.comments[index];
                    var subInfo =
                        "${comment.time.substring(0, 10)}  ${comment.time.substring(11, 19)}";
                    return CommentTile(
                      avatarUrl: comment.avatarUrl,
                      name: comment.name,
                      content: comment.text,
                      slogan: comment.slogan,
                      level: comment.level,
                      time: subInfo,
                      like: () {
                        network.likeOrUnlikeComment(comment.id);
                        comment.isLiked = !comment.isLiked;
                        comment.isLiked ? comment.likes++ : comment.likes--;
                        commentsPageLogic.update();
                      },
                      likes: comment.likes,
                      liked: comment.isLiked,
                    );
                  })),
                  if (commentsPageLogic.comments.loaded !=
                          commentsPageLogic.comments.total &&
                      commentsPageLogic.comments.total != 1)
                    const SliverToBoxAdapter(
                      child: ListLoadingIndicator(),
                    ),
                  SliverPadding(
                      padding: EdgeInsets.only(
                          top:
                              MediaQuery.of(App.globalContext!).padding.bottom))
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
                        child: MiuixTextField(controller: commentsPageLogic.controller, label: "回复...".tl, useLabelAsPlaceholder: true, minLines: 1, maxLines: 4),
                      ),
                      commentsPageLogic.sending
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: MiuixInfiniteProgressIndicator(size: 20),
                              ),
                            )
                          : MiuixIconButton(
                              minWidth: 36,
                              minHeight: 36,
                              child: MiuixIcon(
                                vector: MiuixIcons.extended.byName('send') ??
                                    MiuixIcons.os4.share,
                                size: 19,
                                tint: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () async {
                                if (commentsPageLogic.controller.text.length < 2) {
                                  showToast(message: "评论至少需要2个字".tl);
                                  return;
                                }
                                commentsPageLogic.sending = true;
                                commentsPageLogic.update();
                                var b = await network.comment(
                                    id,
                                    commentsPageLogic.controller.text,
                                    true);
                                if (b) {
                                  commentsPageLogic.controller.text = "";
                                  commentsPageLogic.sending = false;
                                  var res = await network.getReply(id);
                                  commentsPageLogic.comments =
                                      Reply(id, 1, 1, []);
                                  commentsPageLogic.update();
                                  await Future.delayed(
                                      const Duration(milliseconds: 200));
                                  commentsPageLogic.comments = res;
                                  commentsPageLogic.update();
                                } else {
                                  showToast(message: "网络错误".tl);
                                  commentsPageLogic.sending = false;
                                  commentsPageLogic.update();
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
      },
    );

    if (popUp) {
      return body;
    } else {
      return MiuixScaffold(topBar: MiuixSmallTopAppBar(color: MiuixTheme.of(context).colors.background, title: "回复".tl, navigationIcon: MiuixIconButton(child: MiuixIcon(vector: MiuixIcons.os4.chevronBackward, size: 20), onPressed: () => Navigator.of(context).maybePop())), content: (padding) => Padding(padding: EdgeInsets.only(top: padding.top), child: body),
      );
    }
  }
}

void showReply(BuildContext context, String id, Comment replyTo) {
  showSideBar(
      context,
      ReplyPage(
        id,
        replyTo,
        popUp: true,
      ),
      title: "回复".tl,
      showBarrier: false);
}
