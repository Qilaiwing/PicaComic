part of 'components.dart';

/// One search chip with a stable identity for Element reuse.
class SearchChip {
  SearchChip(this.text) : id = _nextId++;
  static int _nextId = 0;
  final int id;
  final String text;
}

/// Text controller that turns finished words (followed by a space) into chips.
/// [query] = chips + the word currently being typed (no trailing space needed).
class SearchChipController extends TextEditingController {
  SearchChipController({super.text}) {
    addListener(_normalize);
    _normalize();
  }

  final List<SearchChip> chips = [];
  bool _busy = false;

  /// Chips plus leftover typing — used as the real search keyword.
  String get query =>
      [...chips.map((c) => c.text), text.trim()]
          .where((e) => e.isNotEmpty)
          .join(' ');

  void _normalize() {
    if (_busy) return;
    final t = text;
    final idx = lastSearchBoundary(t);
    if (idx < 0) return;
    final done = splitSearchTerms(t.substring(0, idx));
    final rest = t.substring(idx + 1);
    _busy = true;
    for (final d in done) {
      chips.add(SearchChip(d));
    }
    value = TextEditingValue(
      text: rest,
      selection: TextSelection.collapsed(offset: rest.length),
    );
    _busy = false;
  }

  void addChip(String chip) {
    final c = chip.trim();
    if (c.isEmpty) return;
    chips.add(SearchChip(c));
    notifyListeners();
  }

  /// On search submit: turn leftover typing into a chip, then return [query].
  String commitPending() {
    final t = text.trim();
    if (t.isEmpty) return query;
    _busy = true;
    chips.add(SearchChip(t));
    value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    _busy = false;
    return query;
  }

  void removeChipAt(int i) {
    if (i < 0 || i >= chips.length) return;
    chips.removeAt(i);
    notifyListeners();
  }

  void removeChipById(int id) {
    final i = chips.indexWhere((c) => c.id == id);
    if (i < 0) return;
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
  static const double _kInputWidth = 120;

  final _chipScroll = ScrollController();
  int _lastChipCount = 0;

  /// Stable field subtree — built once per deps change, never on chip updates.
  Widget? _field;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _field = _buildTextField(MiuixTheme.of(context));
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
      _field = _buildTextField(MiuixTheme.of(context));
    } else if (oldWidget.focusNode != widget.focusNode ||
        oldWidget.hint != widget.hint ||
        oldWidget.autofocus != widget.autofocus ||
        oldWidget.onChanged != widget.onChanged ||
        oldWidget.onSubmitted != widget.onSubmitted) {
      _field = _buildTextField(MiuixTheme.of(context));
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
    if (n == _lastChipCount) return;
    final grew = n > _lastChipCount;
    _lastChipCount = n;
    if (!grew) return;
    // Scroll chips strip only (TextField is pinned outside) — no viewport flash.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chipScroll.hasClients) return;
      final max = _chipScroll.position.maxScrollExtent;
      if (max <= 0) return;
      if ((_chipScroll.offset - max).abs() < 1.0) return;
      _chipScroll.animateTo(
        max,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Widget _buildTextField(MiuixThemeData theme) {
    final style = theme.textStyles.main.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colors.onSurface,
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    );
    final chipCtrl = _chipController;

    Widget field = TextField(
      key: const ValueKey('app_search_text_field'),
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      maxLines: 1,
      textAlignVertical: TextAlignVertical.center,
      textInputAction: TextInputAction.search,
      style: style,
      cursorColor: theme.colors.primary,
      onChanged: widget.onChanged,
      onSubmitted: (s) =>
          widget.onSubmitted(chipCtrl?.commitPending() ?? s),
      decoration: const InputDecoration(
        isDense: true,
        hintText: null,
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
    return field;
  }

  Widget _buildChip(MiuixThemeData theme, SearchChip chip) {
    final primary = theme.colors.primary;
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: ShapeDecoration(
        color: primary.withValues(alpha: 0.14),
        shape: const StadiumBorder(),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(
          chip.text,
          softWrap: false,
          style: TextStyle(
            fontSize: 13,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
            fontWeight: FontWeight.w500,
            color: primary,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _chipController?.removeChipById(chip.id);
            widget.onChanged?.call(_chipController?.text ?? "");
          },
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: MiuixIcon(
                vector: MiuixIcons.os4.close, size: 10, tint: primary),
          ),
        ),
      ]),
    );
  }

  Widget _hintOverlay(MiuixThemeData theme) {
    final chipCtrl = _chipController;
    final style = theme.textStyles.main.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colors.onSurfaceContainerHigh,
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    );
    if (chipCtrl == null) {
      return ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.text.isNotEmpty) {
            return const SizedBox.shrink();
          }
          return IgnorePointer(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.hint, style: style, maxLines: 1),
            ),
          );
        },
      );
    }
    return ListenableBuilder(
      listenable: chipCtrl,
      builder: (context, _) {
        if (chipCtrl.chips.isNotEmpty || chipCtrl.text.isNotEmpty) {
          return const SizedBox.shrink();
        }
        return IgnorePointer(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.hint, style: style, maxLines: 1),
          ),
        );
      },
    );
  }

  /// Chips-only strip. Rebuilds on chip changes; TextField is a sibling outside.
  Widget _chipsStrip(MiuixThemeData theme, SearchChipController chipCtrl) {
    return ListenableBuilder(
      listenable: chipCtrl,
      builder: (context, _) {
        final chips = chipCtrl.chips;
        return ListView.builder(
          controller: _chipScroll,
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: chips.length,
          findChildIndexCallback: (Key key) {
            if (key is! ValueKey<int>) return null;
            final id = key.value;
            final i = chips.indexWhere((c) => c.id == id);
            return i >= 0 ? i : null;
          },
          itemBuilder: (context, i) {
            final chip = chips[i];
            return KeyedSubtree(
              key: ValueKey<int>(chip.id),
              child: Center(child: _buildChip(theme, chip)),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final chipCtrl = _chipController;
    final field = _field ?? _buildTextField(theme);

    return SizedBox(
      height: _kHeight,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: theme.colors.surfaceContainerHigh,
          shape: const StadiumBorder(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: chipCtrl == null
              ? Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: field),
                    _hintOverlay(theme),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Chips scroll independently — TextField never moves with them.
                    Expanded(child: _chipsStrip(theme, chipCtrl)),
                    SizedBox(
                      width: _kInputWidth,
                      height: _kHeight,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: field,
                          ),
                          _hintOverlay(theme),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}