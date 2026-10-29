part of 'components.dart';

/// 可展开的 Miuix 列表项（标题行点击展开/收起子项）。
class MiuixExpandable extends StatefulWidget {
  const MiuixExpandable({
    super.key,
    required this.title,
    required this.children,
    this.summary,
    this.initiallyExpanded = false,
    this.startAction,
    this.titleTrailing,
  });

  final Widget? startAction;

  /// 紧跟在标题后的小部件（例如延迟胶囊）。
  final Widget? titleTrailing;

  final String title;
  final String? summary;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<MiuixExpandable> createState() => MiuixExpandableState();
}

class MiuixExpandableState extends State<MiuixExpandable> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiuixBasicComponent(
          startAction: widget.startAction,
          title: widget.titleTrailing == null ? widget.title : null,
          summary: widget.titleTrailing == null ? widget.summary : null,
          content: widget.titleTrailing == null
              ? null
              : [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: MiuixTheme.of(context).textStyles.headline1.copyWith(
                              color: MiuixTheme.of(context).colors.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      widget.titleTrailing!,
                    ],
                  ),
                  if (widget.summary != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        widget.summary!,
                        style: MiuixTheme.of(context).textStyles.body2.copyWith(
                            color: MiuixTheme.of(context).colors.onSurfaceVariantSummary),
                      ),
                    ),
                ],
          onClick: () => setState(() => _expanded = !_expanded),
          endActions: [
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
