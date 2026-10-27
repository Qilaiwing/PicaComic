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

class AppSearchField extends StatefulWidget {
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

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  static const double _kHeight = 45;

  final _chipScroll = ScrollController();
  int _lastChipCount = 0;

  SearchChipController? get _chipController =>
      widget.controller is SearchChipController
          ? widget.controller as SearchChipController
          : null;

  @override
  void initState() {
    super.initState();
    _chipController?.addListener(_onChipCtrl);
    _lastChipCount = _chipController?.chips.length ?? 0;
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller is SearchChipController) {
        (oldWidget.controller as SearchChipController)
            .removeListener(_onChipCtrl);
      }
      _chipController?.addListener(_onChipCtrl);
      _lastChipCount = _chipController?.chips.length ?? 0;
    }
  }

  @override
  void dispose() {
    _chipController?.removeListener(_onChipCtrl);
    _chipScroll.dispose();
    super.dispose();
  }

  void _onChipCtrl() {
    final n = _chipController?.chips.length ?? 0;
    if (n != _lastChipCount) {
      _lastChipCount = n;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_chipScroll.hasClients) return;
        _chipScroll.jumpTo(_chipScroll.position.maxScrollExtent);
      });
    }
    if (mounted) setState(() {});
  }

  Widget _buildChip(MiuixThemeData theme, String text, VoidCallback onRemove) {
    final primary = theme.colors.primary;
    return Container(
      margin: const EdgeInsets.only(right: 4),
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
            height: 1.15,
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
    final style = theme.textStyles.main.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colors.onSurface,
      height: 1.2,
    );
    final chipCtrl = _chipController;
    final showHint = chipCtrl == null || chipCtrl.chips.isEmpty;

    Widget field = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      maxLines: 1,
      textAlignVertical: TextAlignVertical.center,
      textInputAction: TextInputAction.search,
      style: style,
      cursorColor: theme.colors.primary,
      onChanged: widget.onChanged,
      onSubmitted: (s) => widget.onSubmitted(chipCtrl?.query ?? s),
      decoration: InputDecoration(
        isDense: true,
        hintText: showHint ? widget.hint : null,
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
            widget.onChanged?.call("");
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: field,
      );
    }

    return SizedBox(
      height: _kHeight,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: theme.colors.surfaceContainerHigh,
          shape: const StadiumBorder(),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            MiuixIcon(vector: MiuixIcons.os4.search, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: chipCtrl == null
                  ? Align(alignment: Alignment.centerLeft, child: field)
                  : LayoutBuilder(
                      builder: (context, cons) {
                        final inputWidth =
                            (cons.maxWidth * 0.42).clamp(88.0, 180.0);
                        return SingleChildScrollView(
                          controller: _chipScroll,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              for (var i = 0; i < chipCtrl.chips.length; i++)
                                _buildChip(theme, chipCtrl.chips[i], () {
                                  chipCtrl.removeChipAt(i);
                                  widget.onChanged?.call(chipCtrl.text);
                                }),
                              SizedBox(
                                width: inputWidth,
                                height: _kHeight,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: field,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}