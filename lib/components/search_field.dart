part of 'components.dart';

/// Kept for API compatibility; chips are no longer used in the search field.
class SearchChip {
  SearchChip(this.text) : id = _nextId++;
  static int _nextId = 0;
  final int id;
  final String text;
}

/// Plain-text search controller (space no longer creates chips).
///
/// [query] / [commitPending] return the trimmed field text.
/// [addChip] appends a favorite-tag keyword as plain text (with a space).
class SearchChipController extends TextEditingController {
  SearchChipController({super.text});

  /// Always empty — retained so older call sites compile.
  final List<SearchChip> chips = [];

  /// Current search keyword (plain text).
  String get query => text.trim();

  /// Append [chip] as plain text (favorite-tag long-press).
  void addChip(String chip) {
    final c = chip.trim();
    if (c.isEmpty) return;
    final cur = text.trimRight();
    final next = cur.isEmpty ? c : '$cur $c';
    value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }

  /// Submit helper — returns plain [query] (no chip conversion).
  String commitPending() => query;

  /// Put [keyword] into the field as plain text.
  void applyQuery(String keyword) {
    final t = keyword.trim();
    value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }

  void removeChipAt(int i) {}

  void removeChipById(int id) {}

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

  SearchChipController? get _chipController =>
      widget.controller is SearchChipController
          ? widget.controller as SearchChipController
          : null;

  Widget _buildTextField(MiuixThemeData theme) {
    final style = theme.textStyles.main.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colors.onSurface,
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return TextField(
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
        final q = _chipController?.commitPending() ?? s.trim();
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
  }

  Widget _hintOverlay(MiuixThemeData theme) {
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

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
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
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Align(alignment: Alignment.centerLeft, child: field),
              _hintOverlay(theme),
            ],
          ),
        ),
      ),
    );
  }
}
