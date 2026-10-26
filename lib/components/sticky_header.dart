part of 'components.dart';

/// Frosted backdrop shared by every pinned area (chip rows, sticky section
/// headers, pinned search bars): content scrolling underneath is blurred,
/// matching the Miuix top bar.
/// One frosted surface for every top bar and pinned header.
const double kFrostSigma = 22.5;

double frostTintAlpha(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? 0.42 : 0.48;

/// Live height of the main-frame top bar for pages whose content scrolls
/// underneath it (0 when the frame still pads the page itself).
class MainTopInset extends InheritedWidget {
  const MainTopInset({super.key, required this.height, required super.child});

  final double height;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MainTopInset>()?.height ?? 0;

  @override
  bool updateShouldNotify(MainTopInset oldWidget) =>
      oldWidget.height != height;
}

/// Leading transparent pinned spacer: content starts below the top bar, then
/// scrolls under it; later pinned headers pin right below the bar.
class TopInsetSliver extends StatelessWidget {
  const TopInsetSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MainTopInset.of(context);
    if (h <= 0) return const SliverToBoxAdapter(child: SizedBox.shrink());
    return SliverPersistentHeader(pinned: true, delegate: _TopInsetDelegate(h));
  }
}

class _TopInsetDelegate extends SliverPersistentHeaderDelegate {
  _TopInsetDelegate(this.height);

  final double height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      const IgnorePointer(child: SizedBox.expand());

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_TopInsetDelegate oldDelegate) => oldDelegate.height != height;
}

/// For non-scrolling states (loading / error) of an under-bar page.
class TopInsetPadding extends StatelessWidget {
  const TopInsetPadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: EdgeInsets.only(top: MainTopInset.of(context)), child: child);
}

/// Content area of a page whose top bar floats over it: content starts below
/// the bar at rest and scrolls under it. Replaces `Padding(padding: padding)`
/// around a scaffold body. Box scroll views (ListView/GridView without an
/// explicit padding) pick the inset up from MediaQuery; CustomScrollViews add
/// [TopInsetSliver]; other scrollables use [MainTopInset.of].
class ScrollUnderBar extends StatelessWidget {
  const ScrollUnderBar({super.key, required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: padding.copyWith(top: 0),
      child: MediaQuery(
        data: mq.copyWith(
          padding: mq.padding.copyWith(
            top: padding.top,
            bottom: padding.bottom > 0 ? 0 : mq.padding.bottom,
          ),
        ),
        child: MainTopInset(height: padding.top, child: child),
      ),
    );
  }
}

class FrostedBackground extends StatelessWidget {
  const FrostedBackground({super.key, required this.child, this.alpha});

  final Widget child;
  /// Defaults to the Miuix top bar's tint so pinned areas fuse with it.
  final double? alpha;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kFrostSigma, sigmaY: kFrostSigma),
        child: ColoredBox(
          color: MiuixTheme.of(context).colors.background.withValues(alpha: alpha ?? frostTintAlpha(context)),
          child: child,
        ),
      ),
    );
  }
}

/// HyperOS-style section header that pins under the pinned rows while its
/// section is on screen. Put it as the first child of
/// `MultiSliver(pushPinnedChildren: true, ...)` so the next section's header
/// pushes it away. Only build it once the section's data has loaded.
class StickySectionHeader extends StatelessWidget {
  const StickySectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    return SliverPinnedHeader(
      child: FrostedBackground(
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textStyles.subtitle.copyWith(
                      color: theme.colors.onSurfaceVariantSummary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
