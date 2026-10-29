part of 'components.dart';

/// 有新版本时的更新弹窗: 显示版本号与更新日志 (简易 Markdown 渲染, 可滚动)。
Future<void> showUpdateDialog(
  BuildContext context, {
  required String? version,
  required String? notes,
  required String releaseUrl,
  VoidCallback? onDisableCheck,
}) {
  return showMiuixDialog<void>(
    context: context,
    title: "有可用更新".tl,
    summary: version == null ? null : "${"最新版本".tl}: $version · ${"当前:".tl} $appVersion",
    contentBuilder: (context, close) {
      final colors = MiuixTheme.of(context).colors;
      final mq = MediaQuery.of(context);
      var maxH = mq.size.height * 0.5;
      if (maxH < 160) maxH = 160;
      final hasNotes = notes != null && notes.trim().isNotEmpty;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text("更新日志".tl,
                style: TextStyle(
                    fontSize: 13, color: colors.onSurfaceVariantSummary)),
          ),
          Container(
            constraints: BoxConstraints(maxHeight: maxH),
            decoration: ShapeDecoration(
              color: colors.secondaryContainer,
              shape: const MiuixSquircleBorder(cornerRadius: 14),
            ),
            child: hasNotes
                ? Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: SimpleMarkdown(notes),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(14),
                    child: GestureDetector(
                      onTap: () => launchUrlString(releaseUrl,
                          mode: LaunchMode.externalApplication),
                      child: Text(
                        "暂无更新日志, 点击在 GitHub 查看".tl,
                        style: TextStyle(fontSize: 14, color: colors.primary),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          if (onDisableCheck != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MiuixTextButton("关闭更新检查".tl, onPressed: () {
                close();
                onDisableCheck();
              }),
            ),
          Row(children: [
            Expanded(
                child: MiuixTextButton("取消".tl, onPressed: () => close())),
            const SizedBox(width: 12),
            Expanded(
              child: MiuixButton(
                colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                onPressed: () {
                  close();
                  launchUrlString(releaseUrl,
                      mode: LaunchMode.externalApplication);
                },
                child: Text("下载".tl),
              ),
            ),
          ]),
        ],
      );
    },
  );
}

/// 轻量 Markdown 渲染: 标题 / 列表 / 引用 / 分割线 / **粗体** / `代码` / [链接](url)。
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final colors = MiuixTheme.of(context).colors;
    final base = TextStyle(fontSize: 14, height: 1.45, color: colors.onSurface);
    final children = <Widget>[];
    var inCode = false;
    final code = <String>[];
    for (var raw in data.replaceAll('\r\n', '\n').split('\n')) {
      final line = raw.trimRight();
      if (line.trimLeft().startsWith('```')) {
        if (inCode) {
          children.add(Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(code.join('\n'),
                style: base.copyWith(fontFamily: 'monospace', fontSize: 12.5)),
          ));
          code.clear();
        }
        inCode = !inCode;
        continue;
      }
      if (inCode) {
        code.add(raw);
        continue;
      }
      final t = line.trimLeft();
      if (t.isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }
      final h = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(t);
      if (h != null) {
        final level = h.group(1)!.length;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text.rich(
              _inline(h.group(2)!, base, colors.primary),
              style: base.copyWith(
                  fontSize: level <= 1 ? 17 : (level == 2 ? 16 : 15),
                  fontWeight: FontWeight.w600)),
        ));
        continue;
      }
      if (RegExp(r'^(-{3,}|\*{3,}|_{3,})$').hasMatch(t)) {
        children.add(Divider(height: 14, color: colors.dividerLine));
        continue;
      }
      final li = RegExp(r'^([-*+]|\d+[.)])\s+(.*)$').firstMatch(t);
      if (li != null) {
        final indent = (line.length - t.length) ~/ 2;
        final marker = RegExp(r'^\d').hasMatch(li.group(1)!) ? li.group(1)! : '•';
        children.add(Padding(
          padding: EdgeInsets.only(left: 4.0 + indent * 14, top: 1, bottom: 1),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
                width: 18,
                child: Text(marker,
                    style: base.copyWith(color: colors.onSurfaceVariantSummary))),
            Expanded(child: Text.rich(_inline(li.group(2)!, base, colors.primary))),
          ]),
        ));
        continue;
      }
      if (t.startsWith('>')) {
        children.add(Container(
          padding: const EdgeInsets.only(left: 8),
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
              border: Border(
                  left: BorderSide(color: colors.primary.withValues(alpha: 0.5), width: 3))),
          child: Text.rich(_inline(t.substring(1).trimLeft(), base, colors.primary),
              style: base.copyWith(color: colors.onSurfaceVariantSummary)),
        ));
        continue;
      }
      children.add(Text.rich(_inline(t, base, colors.primary)));
    }
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  static TextSpan _inline(String s, TextStyle base, Color link) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*|__(.+?)__|`([^`]+)`|\[([^\]]+)\]\(([^)]+)\)|\*(.+?)\*');
    var last = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > last) spans.add(TextSpan(text: s.substring(last, m.start)));
      if (m.group(1) != null || m.group(2) != null) {
        spans.add(TextSpan(
            text: m.group(1) ?? m.group(2),
            style: const TextStyle(fontWeight: FontWeight.w600)));
      } else if (m.group(3) != null) {
        spans.add(TextSpan(
            text: m.group(3),
            style: TextStyle(
                fontFamily: 'monospace',
                backgroundColor: base.color?.withValues(alpha: 0.08))));
      } else if (m.group(4) != null) {
        final url = m.group(5)!;
        spans.add(TextSpan(
            text: m.group(4),
            style: TextStyle(color: link),
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  launchUrlString(url, mode: LaunchMode.externalApplication)));
      } else {
        spans.add(TextSpan(
            text: m.group(6),
            style: const TextStyle(fontStyle: FontStyle.italic)));
      }
      last = m.end;
    }
    if (last < s.length) spans.add(TextSpan(text: s.substring(last)));
    return TextSpan(style: base, children: spans);
  }
}
