part of 'components.dart';

/// Text controller that turns finished words (followed by a space) into chips.
/// [query] = chips + the word currently being typed (no trailing space needed).
class SearchChipController extends TextEditingController {
  SearchChipController({super.text}) {
    addListener(_normalize);
    _normalize();
  }

  final List<String> chips = [];
  bool _busy = false;

  /// Chips plus leftover typing — used as the real search keyword.
  String get query =>
      [...chips, text.trim()].where((e) => e.isNotEmpty).join(' ');

  void _normalize() {
    if (_busy) return;
    final t = text;
    final idx = lastSearchBoundary(t);
    if (idx < 0) return;
    final done = splitSearchTerms(t.substring(0, idx));
    final rest = t.substring(idx + 1);
    _busy = true;
    chips.addAll(done);
    value = TextEditingValue(
      text: rest,
      selection: TextSelection.collapsed(offset: rest.length),
    );
    _busy = false;
  }

  void addChip(String chip) {
    final c = chip.trim();
    if (c.isEmpty) return;
    chips.add(c);
    notifyListeners();
  }

  void removeChipAt(int i) {
    if (i < 0 || i >= chips.length) return;
    chips.removeAt(i);
    notifyListeners();
  }

  @override
  void clear() {
    chips.clear();
    super.clear();
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSubmitted,
    this.focusNode,
    this.onChanged,
    this.autofocus = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final void Function(String)? onChanged;
  final void Function(String) onSubmitted;
  final bool autofocus;

  SearchChipController? get _chipController =>
      controller is SearchChipController
          ? controller as SearchChipController
          : null;

  Widget _buildChip(MiuixThemeData theme, String text, VoidCallback onRemove) {
    final primary = theme.colors.primary;
    return Container(
      margin: const EdgeInsets.only(right: 4, top: 2, bottom: 2),
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: ShapeDecoration(
        color: primary.withOpacity(0.14),
        shape: const StadiumBorder(),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          text,
          softWrap: false,
          style: TextStyle(
            fontSize: 13,
            height: 1.2,
            fontWeight: FontWeight.w500,
            color: primary,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRemove,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: MiuixIcon(
                vector: MiuixIcons.os4.close, size: 10, tint: primary),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final style = theme.textStyles.main
        .copyWith(fontWeight: FontWeight.w500, color: theme.colors.onSurface);
    final chipCtrl = _chipController;

    Widget field = TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      maxLines: 1,
      textInputAction: TextInputAction.search,
      style: style,
      cursorColor: theme.colors.primary,
      onChanged: onChanged,
      onSubmitted: (s) => onSubmitted(chipCtrl?.query ?? s),
      decoration: InputDecoration(
        isDense: true,
        hintText: (chipCtrl?.chips.isNotEmpty ?? false) ? null : hint,
        hintStyle: style.copyWith(color: theme.colors.onSurfaceContainerHigh),
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
      ),
    );

    if (chipCtrl != null) {
      field = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              chipCtrl.text.isEmpty &&
              chipCtrl.chips.isNotEmpty) {
            chipCtrl.removeChipAt(chipCtrl.chips.length - 1);
            onChanged?.call("");
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: field,
      );
    }

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: theme.colors.surfaceContainerHigh,
        shape: const StadiumBorder(),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, right: 6),
          child: MiuixIcon(vector: MiuixIcons.os4.search, size: 18),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
            child: chipCtrl == null
                ? ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 33),
                    child: Center(child: field),
                  )
                : LayoutBuilder(
                    builder: (context, cons) => ListenableBuilder(
                      listenable: chipCtrl,
                      builder: (context, _) {
                        // Chips wrap onto new lines so none are clipped;
                        // leftover typing sits after the last chip.
                        return Wrap(
                          spacing: 0,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            for (var i = 0; i < chipCtrl.chips.length; i++)
                              _buildChip(theme, chipCtrl.chips[i], () {
                                chipCtrl.removeChipAt(i);
                                onChanged?.call(chipCtrl.text);
                              }),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: 72,
                                maxWidth: cons.maxWidth,
                                minHeight: 33,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: field,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}