part of 'components.dart';

class Avatar extends StatelessWidget {
  const Avatar(
      {Key? key,
      required this.size,
      this.avatarUrl,
      this.frame,
      this.couldBeShown = false,
      this.name = "",
      this.slogan,
      this.level = 0})
      : super(key: key);
  final double size;
  final String? avatarUrl;
  final String? frame;
  final bool couldBeShown;
  final String name;
  final String? slogan;
  final int level;

  @override
  Widget build(BuildContext context) {
    var avatarUrl = this.avatarUrl;
    if(avatarUrl != null && !avatarUrl.isURL){
      avatarUrl = null;
    }
    // 只有在确实要显示头像框时才给头像留出空间, 否则头像铺满整个圆形
    final showFrame = frame != null && appdata.settings[5] == "1";
    final theme = Theme.of(context);
    final hasAvatar = avatarUrl != null && avatarUrl != "DEFAULT AVATAR URL";
    // 厚色环宽度, 有头像框时不画环(由头像框占用外围空间)
    final ringWidth = showFrame ? 0.0 : (size * 0.055).clamp(3.0, 6.0);
    final avatarSize = size - ringWidth * 2;

    // 头像始终用 ClipOval 紧贴图片本身裁剪, 确保是正圆
    Widget avatarCircle = ClipOval(
      child: SizedBox(
        width: avatarSize,
        height: avatarSize,
        child: hasAvatar
            ? AnimatedImage(
                image: CachedImageProvider(avatarUrl,
                    headers: {"User-Agent": webUA}),
                forceFit: BoxFit.cover,
                width: avatarSize,
                height: avatarSize,
                clipShape: const CircleBorder(),
                filterQuality: FilterQuality.medium,
              )
            : ColoredBox(
                color: theme.colorScheme.primary.withOpacity(0.12),
                child: Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: avatarSize * 0.55,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
      ),
    );

    Widget content;
    if (showFrame) {
      // 有头像框: 按 75% 内缩留白, 再把框铺满整个区域
      final frameInset = size * 0.25 / 2;
      final frameAvatarSize = size - frameInset * 2;
      content = Stack(
        children: [
          Positioned(
            top: frameInset,
            left: frameInset,
            child: ClipOval(
              child: SizedBox(
                width: frameAvatarSize,
                height: frameAvatarSize,
                child: hasAvatar
                    ? AnimatedImage(
                        image: CachedImageProvider(avatarUrl,
                            headers: {"User-Agent": webUA}),
                        forceFit: BoxFit.cover,
                        width: frameAvatarSize,
                        height: frameAvatarSize,
                        clipShape: const CircleBorder(),
                        filterQuality: FilterQuality.medium,
                      )
                    : ColoredBox(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        child: Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: frameAvatarSize * 0.55,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Positioned.fill(
            child: Image(image: CachedImageProvider(frame!)),
          ),
        ],
      );
    } else {
      // 无头像框: 外层圆形容器当厚色环, 内层头像居中
      content = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.primary.withOpacity(
            theme.brightness == Brightness.dark ? 0.28 : 0.16,
          ),
        ),
        child: avatarCircle,
      );
    }

    return GestureDetector(
      onTap: () {
        if (couldBeShown) {
          showUserInfo(context, avatarUrl, frame, name, slogan, level);
        } else if(hasAvatar){
          App.globalTo(() => ShowImagePageWithHero(avatarUrl!, "avatar"));
        }
      },
      child: SizedBox(
        width: size,
        height: size,
        child: content,
      ),
    );
  }
}

void showUserInfo(BuildContext context, String? avatarUrl, String? frameUrl, String name, String? slogan, int level){
  showMiuixDialog<void>(context: context, contentBuilder: (dialogContext, close){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.center,
          child: Column(
            children: [
              Avatar(size: 80, avatarUrl: avatarUrl, frame: frameUrl,),
              Text(name,style: const TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
              Text("Lv${level.toString()}"),
              const SizedBox(height: 10,width: 0,),
              SizedBox(width: 400,child: Align(
                alignment: Alignment.center,
                child: Text(slogan??""),
              ),)
            ],
          ),
        )
      ],
    );
  });
}
