// App-side wrapper of flutter_miuix's MiuixScaffold (same API).
//
// Why: the package scaffold seeds the content padding of a [MiuixTopAppBar]
// with its *collapsed* height (52 + status bar) and only reports the real
// (expanded, large-title) height in a post-frame callback. Every page whose
// bar starts expanded (settings, its sub-pages, …) therefore laid its content
// out 60–80px too high on the first frame and then jumped down: the visible
// "jitter/flash once" when opening a page. The submodule is intentionally
// left untouched, so the fix lives here:
//  * the real padding measured for a bar title is cached and reused for the
//    first frames of the next page with the same title;
//  * when nothing is cached yet, the content is kept invisible until the real
//    padding arrives (one frame, hidden by the route transition) instead of
//    being shown at the wrong offset.

import 'package:flutter/material.dart';
import 'package:flutter_miuix/miuix.dart' as m;

class MiuixScaffold extends StatelessWidget {
  const MiuixScaffold({
    super.key,
    this.topBar,
    this.bottomBar,
    this.floatingActionButton,
    this.floatingActionButtonPosition = m.MiuixFabPosition.end,
    this.floatingToolbar,
    this.floatingToolbarPosition = m.MiuixToolbarPosition.bottomCenter,
    this.snackbarHost,
    this.popupHost,
    this.containerColor,
    this.contentWindowInsets,
    required this.content,
  });

  final Widget? topBar;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final m.MiuixFabPosition floatingActionButtonPosition;
  final Widget? floatingToolbar;
  final m.MiuixToolbarPosition floatingToolbarPosition;
  final Widget? snackbarHost;
  final Widget? popupHost;
  final Color? containerColor;
  final EdgeInsets? contentWindowInsets;
  final m.MiuixScaffoldContentBuilder content;

  @override
  Widget build(BuildContext context) {
    final bar = topBar;
    m.MiuixScaffoldContentBuilder builder = content;
    if (bar is m.MiuixTopAppBar) {
      final cacheKey = '${bar.title}|${bar.largeTitle}|'
          '${bar.bottomContent != null}';
      builder = (padding) => _StableTopPadding(
            cacheKey: cacheKey,
            padding: padding,
            builder: content,
          );
    }
    return m.MiuixScaffold(
      topBar: topBar,
      bottomBar: bottomBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonPosition: floatingActionButtonPosition,
      floatingToolbar: floatingToolbar,
      floatingToolbarPosition: floatingToolbarPosition,
      snackbarHost: snackbarHost,
      popupHost: popupHost,
      containerColor: containerColor,
      contentWindowInsets: contentWindowInsets,
      content: builder,
    );
  }
}

class _StableTopPadding extends StatefulWidget {
  const _StableTopPadding({
    required this.cacheKey,
    required this.padding,
    required this.builder,
  });

  final String cacheKey;
  final EdgeInsets padding;
  final m.MiuixScaffoldContentBuilder builder;

  /// Real (measured) content padding per top-bar identity.
  static final Map<String, EdgeInsets> _cache = {};

  @override
  State<_StableTopPadding> createState() => _StableTopPaddingState();
}

class _StableTopPaddingState extends State<_StableTopPadding> {
  /// True while the scaffold may still be handing us its first-frame estimate.
  bool _settling = true;

  double get _estimateTop =>
      m.MiuixTopAppBarDefaults.collapsedHeight +
      MediaQuery.paddingOf(context).top;

  bool get _isEstimate => (widget.padding.top - _estimateTop).abs() < 0.5;

  @override
  void initState() {
    super.initState();
    // The scaffold reports the measured padding in a post-frame callback of
    // the first frame; give it two frames, then trust whatever it passes
    // (including a genuinely collapsed bar).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _settling) setState(() => _settling = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var padding = widget.padding;
    if (_settling) {
      if (!_isEstimate) {
        _settling = false;
      } else {
        final cached = _StableTopPadding._cache[widget.cacheKey];
        if (cached != null) {
          padding = cached;
        } else {
          // Nothing known yet: don't show content at a wrong offset.
          return Opacity(opacity: 0, child: widget.builder(padding));
        }
      }
    }
    if (!_settling && !_isEstimate) {
      // Only cache the expanded/real value, never the collapsed estimate.
      final old = _StableTopPadding._cache[widget.cacheKey];
      if (old == null || padding.top > old.top) {
        _StableTopPadding._cache[widget.cacheKey] = padding;
      }
    }
    return widget.builder(padding);
  }
}
