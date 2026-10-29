import 'package:flutter/material.dart';

import 'components.dart';

class CommentTile extends StatelessWidget {
  const CommentTile(
      {Key? key,
      required this.avatarUrl,
      this.frameUrl,
      required this.name,
      required this.content,
      this.onTap,
      this.slogan,
      this.level,
      this.time,
      this.tailing,
      this.likes,
      this.liked,
      this.comments,
      this.leading,
      this.like,
      this.dense = false})
      : super(key: key);
  final String? avatarUrl;
  final String? frameUrl;
  final String name;
  final String content;
  final String? slogan;
  final String? time;
  final int? likes;
  final bool? liked;
  final int? comments;
  final int? level;
  final void Function()? onTap;
  final Widget? tailing;
  final void Function()? like;
  final Widget? leading;
  /// Tighter layout for sources without likes / levels (typical JS comments).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final outlineColor =
        isDark ? const Color(0x99FFFFFF) : const Color(0x8A000000);
    final useDense = dense || (like == null && level == null);
    final avatarSize = useDense ? 40.0 : 52.0;
    final nameSize = useDense ? 13.5 : 14.0;
    final contentSize = useDense ? 13.5 : 14.5;
    final gapAfterName = useDense ? 4.0 : 8.0;

    Widget? avatar;
    if (avatarUrl != null) {
      avatar = Avatar(
        size: avatarSize,
        avatarUrl: avatarUrl,
        frame: frameUrl,
        slogan: slogan,
        name: name,
        couldBeShown: level != null,
        level: level ?? 0,
      );
    } else if (leading != null) {
      avatar = leading;
    } else {
      final ch = name.trim().isEmpty ? "?" : name.trim().substring(0, 1);
      avatar = Container(
        width: avatarSize,
        height: avatarSize,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: MiuixSquircleBorder(cornerRadius: useDense ? 12 : 14),
          color: primaryColor.withOpacity(0.14),
        ),
        child: Text(
          ch.toUpperCase(),
          style: TextStyle(
            fontSize: useDense ? 14 : 16,
            fontWeight: FontWeight.w700,
            color: primaryColor,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: MiuixCard(
        cornerRadius: 14,
        insideMargin: EdgeInsets.fromLTRB(
            12, useDense ? 10 : 12, 12, useDense ? 10 : 12),
        onPressed: onTap,
        feedbackType: onTap != null
            ? MiuixPressFeedbackType.sink
            : MiuixPressFeedbackType.none,
        child: SizedBox(
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar!,
              SizedBox(width: useDense ? 10 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                                fontSize: nameSize,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (time != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            time!,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: outlineColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: gapAfterName),
                    SelectableText(
                      content,
                      style: TextStyle(fontSize: contentSize, height: 1.3),
                    ),
                    if (like != null || comments != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Spacer(),
                          if (like != null)
                            MiuixPressable(
                                shape:
                                    const MiuixSquircleBorder(cornerRadius: 8),
                                onPressed: like,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MiuixIcon(
                                        vector: (liked ?? false)
                                            ? (MiuixIcons.extended
                                                    .byName('favoritesFill') ??
                                                MiuixIcons.os4.favorites)
                                            : (MiuixIcons.extended
                                                    .byName('favorites') ??
                                                MiuixIcons.os4.favorites),
                                        size: 14,
                                        tint: (liked ?? false)
                                            ? primaryColor
                                            : outlineColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        likes.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: (liked ?? false)
                                              ? primaryColor
                                              : outlineColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          if (like != null) const SizedBox(width: 12),
                          if (comments != null)
                            MiuixPressable(
                                shape:
                                    const MiuixSquircleBorder(cornerRadius: 8),
                                onPressed: onTap,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MiuixIcon(
                                        vector: MiuixIcons.extended
                                                .byName('messages') ??
                                            MiuixIcons.os4.more,
                                        size: 14,
                                        tint: outlineColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        comments.toString(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: outlineColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
