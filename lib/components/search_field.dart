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
    // Pasted / long comic titles stay plain text (see isSearchTitlePlainText).
    if (isSearchTitlePlainText(t) || hasSearchTitleMarks(t)) return;
    final idx = lastSearchBoundary(t);
    if (idx < 0) return;
    final done = splitSearchTerms(t.substring(0, idx));
    final rest = t.substring(idx + 1);
    // Single keyword alone (e.g. "全彩 ") — do not chip until combining / multi-term.
    if (chips.isEmpty &&
        done.length == 1 &&
        rest.trim().isEmpty) {
      return;
    }
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

  /// On search submit: chip leftover only when combining / multi-term.
  /// Single keyword and long titles stay plain text (still in [query]).
  String commitPending() {
    final t = text.trim();
    if (t.isEmpty) return query;
    if (!shouldAutoChipPending(t, existingChipCount: chips.length)) {
      return query;
    }
    _busy = true;
    if (chips.isEmpty) {
      for (final term in splitSearchTerms(t)) {
        chips.add(SearchChip(term));
      }
    } else {
      chips.add(SearchChip(t));
    }
    value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    _busy = false;
    notifyListeners();
    return query;
  }

  /// Restore a query string into chips (short tags) or plain text (titles).
  void applyQuery(String keyword) {
    final t = keyword.trim();
    chips.clear();
    if (t.isEmpty) {
      _busy = true;
      value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _busy = false;
      return;
    }
    // Single keyword or title → plain text; multi-term short tags → chips.
    if (isSearchTitlePlainText(t) || hasSearchTitleMarks(t) || splitSearchTerms(t).length <= 1) {
      _busy = true;
      value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
      _busy = false;
      return;
    }
    for (final term in splitSearchTerms(t)) {
      chips.add(SearchChip(term));
    }
    _busy = true;
    value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    _busy = false;
    notifyListeners();
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
    if (n == _lastChipCount) return;
    final grew = n > _lastChipCount;
    _lastChipCount = n;
    if (!grew) return;
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

  /// Soft fade at horizontal edges instead of hard clip.
  Widget _edgeFade({
    required Widget child,
    bool left = true,
    bool right = true,
  }) {
    if (!left && !right) return child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            left ? Colors.transparent : Colors.black,
            Colors.black,
            Colors.black,
            right ? Colors.transparent : Colors.black,
          ],
          stops: const [0.0, 0.08, 0.92, 1.0],
        ).createShader(rect);
      },
      child: child,
    );
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
      textAlign: TextAlign.start,
      textAlignVertical: TextAlignVertical.center,
      textInputAction: TextInputAction.search,
      style: style,
      cursorColor: theme.colors.primary,
      onChanged: widget.onChanged,
      onSubmitted: (s) {
        final q = chipCtrl?.commitPending() ?? s;
        widget.onSubmitted(q);
      },
      decoration: const InputDecoration(
        isDense: true,
        hintText: null,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        alignLabelWithHint: true,
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
    final hint = IgnorePointer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          widget.hint,
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
        ),
      ),
    );
    if (chipCtrl == null) {
      return ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.text.isNotEmpty) {
            return const SizedBox.shrink();
          }
          return hint;
        },
      );
    }
    return ListenableBuilder(
      listenable: chipCtrl,
      builder: (context, _) {
        if (chipCtrl.chips.isNotEmpty || chipCtrl.text.isNotEmpty) {
          return const SizedBox.shrink();
        }
        return hint;
      },
    );
  }

  Widget _chipsList(MiuixThemeData theme, SearchChipController chipCtrl) {
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
  }

  Widget _inputStack(MiuixThemeData theme, Widget field) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Align(alignment: Alignment.centerLeft, child: field),
        _hintOverlay(theme),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final chipCtrl = _chipController;
    final field = _buildTextField(theme);

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
              ? _edgeFade(child: _inputStack(theme, field))
              : ListenableBuilder(
                  listenable: chipCtrl,
                  builder: (context, _) {
                    final hasChips = chipCtrl.chips.isNotEmpty;
                    // Empty: input takes full width, left-aligned (fixes mid/right cursor).
                    // With chips: chips scroll on the left, input fills the rest (also LTR).
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (hasChips)
                          Expanded(
                            flex: 3,
                            child: _edgeFade(
                              child: _chipsList(theme, chipCtrl),
                            ),
                          ),
                        Expanded(
                          flex: hasChips ? 2 : 1,
                          child: _edgeFade(
                            left: hasChips,
                            right: true,
                            child: _inputStack(theme, field),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}