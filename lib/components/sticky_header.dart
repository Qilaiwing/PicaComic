part of 'components.dart';

/// Frosted backdrop shared by every pinned area (chip rows, sticky section
/// headers, pinned search bars): content scrolling underneath is blurred,
/// matching the Miuix top bar.
class FrostedBackground extends StatelessWidget {
  const FrostedBackground({super.key, required this.child, this.alpha = 0.82});

  final Widget child;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: ColoredBox(
          color: MiuixTheme.of(context).colors.background.withValues(alpha: alpha),
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
