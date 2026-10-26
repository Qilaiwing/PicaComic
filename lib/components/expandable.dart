part of 'components.dart';

/// 可展开的 Miuix 列表项（标题行点击展开/收起子项）。
class MiuixExpandable extends StatefulWidget {
  const MiuixExpandable(
      {super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  State<MiuixExpandable> createState() => MiuixExpandableState();
}

class MiuixExpandableState extends State<MiuixExpandable> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiuixBasicComponent(
          title: widget.title,
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
