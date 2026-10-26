part of 'app_page_route.dart';

/// HyperOS-like page transition: the new page slides in from the right with
/// an emphasized-decelerate curve and a slight fade, while the page below
/// moves left with parallax and dims a little. During a user gesture (iOS
/// edge swipe or Android predictive back) the animation follows the finger
/// linearly.
class HyperPageTransition extends StatelessWidget {
  const HyperPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.linear,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool linear;
  final Widget child;

  static const _curve = Easing.emphasizedDecelerate;
  static const _reverseCurve = Curves.easeInOutCubic;

  @override
  Widget build(BuildContext context) {
    final primary = linear
        ? animation
        : CurvedAnimation(
            parent: animation, curve: _curve, reverseCurve: _reverseCurve);
    final secondary = linear
        ? secondaryAnimation
        : CurvedAnimation(
            parent: secondaryAnimation,
            curve: _curve,
            reverseCurve: _reverseCurve);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final dir = isRtl ? -1.0 : 1.0;
    return SlideTransition(
      position: Tween(begin: Offset(-0.28 * dir, 0), end: Offset.zero)
          .animate(ReverseAnimation(secondary)),
      child: AnimatedBuilder(
        animation: secondary,
        builder: (context, child) {
          final dim = 0.06 * secondaryAnimation.value;
          if (dim <= 0) return child!;
          return Stack(fit: StackFit.passthrough, children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                    color: Colors.black.withValues(alpha: dim)),
              ),
            ),
          ]);
        },
        child: SlideTransition(
          position: Tween(begin: Offset(dir, 0), end: Offset.zero)
              .animate(primary),
          // No fade on the incoming page: a half-transparent page over the
          // dimmed page below read as a gray scrim popping up first.
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                ),
              ]),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Android 14+ predictive back: feeds the system back-gesture progress into
/// the route's own controller (same contract as Flutter's
/// PredictiveBackPageTransitionsBuilder), so [HyperPageTransition] tracks the
/// gesture and the previous page is revealed live.
class _PredictiveBackDetector extends StatefulWidget {
  const _PredictiveBackDetector({required this.route, required this.child});

  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<_PredictiveBackDetector> createState() =>
      _PredictiveBackDetectorState();
}

class _PredictiveBackDetectorState extends State<_PredictiveBackDetector>
    with WidgetsBindingObserver {
  bool _active = false;

  bool get _enabled =>
      widget.route.isCurrent && widget.route.popGestureEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    _active = _enabled;
    if (!_active) return false;
    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (!_active) return;
    widget.route.handleUpdateBackGestureProgress(
        progress: 1 - backEvent.progress);
  }

  @override
  void handleCancelBackGesture() {
    if (!_active) return;
    _active = false;
    widget.route.handleCancelBackGesture();
  }

  @override
  void handleCommitBackGesture() {
    if (!_active) return;
    _active = false;
    widget.route.handleCommitBackGesture();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
