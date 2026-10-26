part of "components.dart";

void showDesktopMenu(
    BuildContext context, Offset location, List<DesktopMenuEntry> entries) {
  Navigator.of(context).push(DesktopMenuRoute(entries, location));
}

class DesktopMenuRoute<T> extends PopupRoute<T> {
  final List<DesktopMenuEntry> entries;

  final Offset location;

  DesktopMenuRoute(this.entries, this.location);

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => "menu";

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    const width = 196.0;
    final size = MediaQuery.of(context).size;
    var left = location.dx;
    if (left + width > size.width - 10) {
      left = size.width - width - 10;
    }
    var top = location.dy;
    var height = 16 + 32 * entries.length;
    if (top + height > size.height - 15) {
      top = size.height - height - 15;
    }
    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: ShapeDecoration(
                color: App.colors(context).surfaceContainer,
                shape: const MiuixSquircleBorder(cornerRadius: 16),
                shadows: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: entries.map((e) => buildEntry(e, context)).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget buildEntry(DesktopMenuEntry entry, BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      customBorder: const MiuixSquircleBorder(cornerRadius: 8),
      onTap: () {
        Navigator.of(context).pop();
        entry.onClick();
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (entry.icon != null) ...[
              Icon(
                entry.icon,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              entry.text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation.drive(Tween<double>(begin: 0, end: 1)
          .chain(CurveTween(curve: Curves.ease))),
      child: child,
    );
  }
}

class DesktopMenuEntry {
  final String text;
  final IconData? icon;
  final void Function() onClick;

  DesktopMenuEntry({required this.text, this.icon, required this.onClick});
}
