part of 'components.dart';

/// Text controller that turns finished words (followed by a space) into chips.
/// [query] = chips + the word currently being typed.
class SearchChipController extends TextEditingController {
  SearchChipController({super.text}) {
    addListener(_normalize);
    _normalize();
  }

  final List<String> chips = [];
  bool _busy = false;

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
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.fromLTRB(10, 3, 3, 3),
      decoration: ShapeDecoration(
        color: primary.withOpacity(0.14),
        shape: const StadiumBorder(),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          text,
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
            child: MiuixIcon(vector: MiuixIcons.os4.close, size: 10, tint: primary),
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
      // Hardware/IME backspace on empty input removes the last chip.
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
      child: Row(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: MiuixIcon(vector: MiuixIcons.os4.search, size: 18),
        ),
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 45),
            child: Center(
              child: chipCtrl == null
                  ? field
                  : LayoutBuilder(
                      builder: (context, cons) => ListenableBuilder(
                        listenable: chipCtrl,
                        builder: (context, _) => Row(children: [
                          if (chipCtrl.chips.isNotEmpty)
                            ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: cons.maxWidth * 0.7),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                child: Row(children: [
                                  for (var i = 0; i < chipCtrl.chips.length; i++)
                                    _buildChip(theme, chipCtrl.chips[i], () {
                                      chipCtrl.removeChipAt(i);
                                      onChanged?.call(chipCtrl.text);
                                    }),
                                ]),
                              ),
                            ),
                          Expanded(child: field),
                        ]),
                      ),
                    ),
            ),
          ),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty &&
                  !(chipCtrl?.chips.isNotEmpty ?? false)
              ? const SizedBox(width: 12)
              : MiuixIconButton(
                  minWidth: 32,
                  minHeight: 32,
                  onPressed: () {
                    controller.clear();
                    onChanged?.call("");
                  },
                  child: MiuixIcon(vector: MiuixIcons.os4.close, size: 14),
                ),
        ),
      ]),
    );
  }
}