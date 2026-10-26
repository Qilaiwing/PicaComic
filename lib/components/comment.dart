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
      this.like})
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final outlineColor = isDark ? const Color(0x99FFFFFF) : const Color(0x8A000000);

    return Material(
      color: Colors.transparent,
      shape: const MiuixSquircleBorder(cornerRadius: 14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (avatarUrl != null)
                  Avatar(
                    size: 52,
                    avatarUrl: avatarUrl,
                    frame: frameUrl,
                    slogan: slogan,
                    name: name,
                    couldBeShown: level != null,
                    level: level ?? 0,
                  ),
                if (leading != null) leading!,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        content,
                        style: const TextStyle(fontSize: 14.5, height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (time != null)
                            Text(
                              time!,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: outlineColor,
                              ),
                            ),
                          const Spacer(),
                          if (like != null)
                            Material(
                              color: Colors.transparent,
                              shape: const MiuixSquircleBorder(cornerRadius: 8),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: like,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MiuixIcon(
                                        vector: (liked ?? false)
                                            ? (MiuixIcons.extended.byName('favoritesFill') ??
                                                MiuixIcons.os4.favorites)
                                            : (MiuixIcons.extended.byName('favorites') ??
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
                                ),
                              ),
                            ),
                          if (like != null) const SizedBox(width: 12),
                          if (comments != null)
                            Material(
                              color: Colors.transparent,
                              shape: const MiuixSquircleBorder(cornerRadius: 8),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: onTap,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      MiuixIcon(
                                        vector: MiuixIcons.extended.byName('messages') ??
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
                                ),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
