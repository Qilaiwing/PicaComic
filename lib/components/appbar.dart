part of 'components.dart';

class Appbar extends StatefulWidget implements PreferredSizeWidget {
  const Appbar(
      {required this.title,
      this.leading,
      this.actions,
      this.backgroundColor,
      super.key});

  final Widget title;

  final Widget? leading;

  final List<Widget>? actions;

  final Color? backgroundColor;

  @override
  State<Appbar> createState() => _AppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(_kAppBarHeight);
}

class _AppbarState extends State<Appbar> {
  ScrollNotificationObserverState? _scrollNotificationObserver;
  bool _scrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  @override
  void dispose() {
    if (_scrollNotificationObserver != null) {
      _scrollNotificationObserver!.removeListener(_handleScrollNotification);
      _scrollNotificationObserver = null;
    }
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        defaultScrollNotificationPredicate(notification)) {
      final bool oldScrolledUnder = _scrolledUnder;
      final ScrollMetrics metrics = notification.metrics;
      switch (metrics.axisDirection) {
        case AxisDirection.up:
          // Scroll view is reversed
          _scrolledUnder = metrics.extentAfter > 0;
        case AxisDirection.down:
          _scrolledUnder = metrics.extentBefore > 0;
        case AxisDirection.right:
        case AxisDirection.left:
          // Scrolled under is only supported in the vertical axis, and should
          // not be altered based on horizontal notifications of the same
          // predicate since it could be a 2D scroller.
          break;
      }

      if (_scrolledUnder != oldScrolledUnder) {
        setState(() {
          // React to a change in MaterialState.scrolledUnder
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var content = SizedBox(
      height: _kAppBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: DefaultTextStyle(
                  style: DefaultTextStyle.of(context).style.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  child: widget.title,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            child: widget.leading ??
                (Navigator.of(context).canPop()
                    ? Tooltip(
                        message: "返回".tl,
                        child: MiuixIconButton(
                          onPressed: () => Navigator.pop(context),
                          child: MiuixIcon(
                            vector: MiuixIcons.extended.byName('chevronBackward') ??
                                MiuixIcons.os4.back,
                            size: 20,
                            tint: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF111111),
                          ),
                        ),
                      )
                    : const SizedBox()),
          ),
          if (widget.actions != null)
            Positioned(
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.actions!,
              ),
            ),
        ],
      ),
    ).paddingTop(context.padding.top);
    if (widget.backgroundColor != Colors.transparent) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final baseColor = widget.backgroundColor ??
          Theme.of(context).scaffoldBackgroundColor;
      final translucentColor = baseColor.withOpacity(isDark ? 0.45 : 0.52);
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              color: translucentColor,
              border: _scrolledUnder
                  ? Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0x18FFFFFF)
                            : const Color(0x0F000000),
                        width: 0.6,
                      ),
                    )
                  : null,
            ),
            child: content,
          ),
        ),
      );
    }
    return content;
  }
}

class SliverAppbar extends StatelessWidget {
  const SliverAppbar({
    super.key,
    required this.title,
    this.largeTitle,
    this.leftSmallTitle = false,
    this.leading,
    this.actions,
    this.color,
    this.radius = 0,
  });

  final Widget? leading;

  final Widget title;

  final Widget? largeTitle;

  final bool leftSmallTitle;

  final List<Widget>? actions;

  final Color? color;

  final double radius;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _MySliverAppBarDelegate(
        leading: leading,
        title: title,
        largeTitle: largeTitle,
        leftSmallTitle: leftSmallTitle,
        actions: actions,
        topPadding: MediaQuery.of(context).padding.top,
        color: color,
        radius: radius,
      ),
    );
  }
}

const _kAppBarHeight = 52.0;

class _MySliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget? leading;

  final Widget title;

  final Widget? largeTitle;

  final bool leftSmallTitle;

  final List<Widget>? actions;

  final double topPadding;

  final Color? color;

  final double radius;

  _MySliverAppBarDelegate({
    this.leading,
    required this.title,
    this.largeTitle,
    this.leftSmallTitle = false,
    this.actions,
    this.color,
    required this.topPadding,
    this.radius = 0,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxShrink = maxExtent - minExtent;
    final progress =
        maxShrink > 0 ? (shrinkOffset / maxShrink).clamp(0.0, 1.0) : 0.0;
    final largeTitleOpacity = (1.0 - progress * 2.2).clamp(0.0, 1.0);
    final smallTitleOpacity = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);

    final baseColor = color ?? Theme.of(context).scaffoldBackgroundColor;
    final translucentColor = baseColor.withOpacity(isDark ? 0.45 : 0.52);

    return SizedBox.expand(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            decoration: BoxDecoration(
              color: translucentColor,
              border: (overlapsContent || progress >= 0.9)
                  ? Border(
                      bottom: BorderSide(
                        color: isDark
                            ? const Color(0x18FFFFFF)
                            : const Color(0x0F000000),
                        width: 0.6,
                      ),
                    )
                  : null,
            ),
            child: Stack(
          children: [
            Positioned(
              top: topPadding,
              left: 0,
              right: 0,
              height: _kAppBarHeight,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: leftSmallTitle
                        ? Padding(
                            padding: const EdgeInsets.only(left: 58, right: 54),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Opacity(
                                opacity: smallTitleOpacity,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - smallTitleOpacity) - 1.0),
                                  child: DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                      height: 1.2,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111111),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                    child: title,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 50),
                              child: Opacity(
                                opacity: smallTitleOpacity,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - smallTitleOpacity) - 1.0),
                                  child: DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                      height: 1.2,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111111),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    child: title,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    left: 8,
                    child: leading ??
                        (Navigator.of(context).canPop()
                            ? Tooltip(
                                message: "返回".tl,
                                child: MiuixIconButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: MiuixIcon(
                                    vector: MiuixIcons.extended
                                            .byName('chevronBackward') ??
                                        MiuixIcons.os4.back,
                                    size: 20,
                                    tint: isDark
                                        ? Colors.white
                                        : const Color(0xFF111111),
                                  ),
                                ),
                              )
                            : const SizedBox()),
                  ),
                  if (actions != null)
                    Positioned(
                      right: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
                    ),
                ],
              ),
            ),
            if (largeTitleOpacity > 0.01)
              Positioned(
                left: 24,
                right: 24,
                bottom: 18 + (1 - largeTitleOpacity) * 6,
                child: Opacity(
                  opacity: largeTitleOpacity,
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                      color: isDark ? Colors.white : const Color(0xFF111111),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: largeTitle ?? title,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  ),
);
  }

  @override
  double get maxExtent => 88.0 + topPadding;

  @override
  double get minExtent => _kAppBarHeight + topPadding;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is! _MySliverAppBarDelegate ||
        leading != oldDelegate.leading ||
        title != oldDelegate.title ||
        actions != oldDelegate.actions;
  }
}

class FloatingSearchBar extends StatefulWidget {
  const FloatingSearchBar({
    Key? key,
    this.height = 56,
    this.trailing,
    required this.onSearch,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  /// height of search bar
  final double height;

  /// end of search bar
  final Widget? trailing;

  /// callback when user do search
  final void Function(String) onSearch;

  /// controller of [TextField]
  final TextEditingController controller;

  final void Function(String)? onChanged;

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  double get effectiveHeight {
    return math.max(widget.height, 53);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF262628) : const Color(0xFFF0F1F5);
    final border = isDark ? const Color(0x28FFFFFF) : const Color(0x12000000);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      width: double.infinity,
      height: effectiveHeight,
      child: Container(
        height: 46,
        decoration: ShapeDecoration(
          color: bg,
          shape: MiuixSquircleBorder(
            cornerRadius: 23,
            side: BorderSide(color: border, width: 0.6),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: [
          Tooltip(
            message: "返回".tl,
            child: MiuixIconButton(
              minWidth: 36,
              minHeight: 36,
              onPressed: () => context.pop(),
              child: MiuixIcon(
                vector: MiuixIcons.extended.byName('chevronBackward') ??
                    MiuixIcons.os4.back,
                size: 20,
                tint: isDark
                    ? const Color(0xEEFFFFFF)
                    : const Color(0xDD000000),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Center(
              child: TextField(
                controller: widget.controller,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xEEFFFFFF)
                      : const Color(0xDD000000),
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: "Search",
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0x66FFFFFF)
                        : const Color(0x66000000),
                    fontSize: 15,
                  ),
                ),
                onSubmitted: (s) {
                  widget.onSearch(s);
                },
                onChanged: widget.onChanged,
              ),
            ),
          ),
          if (widget.trailing != null) widget.trailing!
        ]),
      ),
    );
  }
}

class FilledTabBar extends StatefulWidget {
  const FilledTabBar({super.key, this.controller, required this.tabs});

  final TabController? controller;

  final List<Tab> tabs;

  @override
  State<FilledTabBar> createState() => _FilledTabBarState();
}

class _FilledTabBarState extends State<FilledTabBar> {
  late TabController _controller;

  late List<GlobalKey> keys;

  static const _kTabHeight = 44.0;

  final scrollController = ScrollController();

  final tabBarKey = GlobalKey();

  int? previousIndex;

  @override
  void initState() {
    keys = widget.tabs.map((e) => GlobalKey()).toList();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _controller = widget.controller ?? DefaultTabController.of(context);
    _controller.animation!.addListener(onTabChanged);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant FilledTabBar oldWidget) {
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? DefaultTabController.of(context);
      _controller.animation!.addListener(onTabChanged);
    }
    if (widget.tabs.length != keys.length) {
      keys = widget.tabs.map((e) => GlobalKey()).toList();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void onTabChanged() {
    final int i = _controller.index;
    if (i == previousIndex) {
      return;
    }
    _scrollToCenter(i);
    previousIndex = i;
  }

  void _scrollToCenter(int i) {
    if (i < 0 || i >= keys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;
      final keyContext = keys[i].currentContext;
      if (keyContext == null) return;
      final renderBox = keyContext.findRenderObject() as RenderBox?;
      if (renderBox == null) return;
      final position = renderBox.localToGlobal(Offset.zero,
          ancestor: tabBarKey.currentContext?.findRenderObject());
      final tabBarBox =
          tabBarKey.currentContext?.findRenderObject() as RenderBox?;
      if (tabBarBox == null) return;
      final double tabCenter = position.dx + renderBox.size.width / 2;
      final double screenCenter = tabBarBox.size.width / 2;
      final double target = (scrollController.offset + tabCenter - screenCenter)
          .clamp(0.0, scrollController.position.maxScrollExtent);
      scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void onTabClicked(int i) {
    _controller.animateTo(i);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: buildTabBar,
    );
  }

  Widget buildTabBar(BuildContext context, Widget? _) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      key: tabBarKey,
      height: _kTabHeight,
      width: double.infinity,
      color: Colors.transparent,
      child: widget.tabs.isEmpty
          ? const SizedBox()
          : SmoothScrollProvider(
              controller: scrollController,
              builder: (context, controller, physics) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 3),
                  controller: controller,
                  physics: physics,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < widget.tabs.length; i++)
                        _buildCapsuleTab(context, i, isDark, primaryColor),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCapsuleTab(
      BuildContext context, int i, bool isDark, Color primaryColor) {
    final isSelected = i == _controller.index;
    final tab = widget.tabs[i];
    final String text = tab.text ??
        (tab.child is Text ? (tab.child as Text).data ?? '' : '');

    return Padding(
      key: keys[i],
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            onTabClicked(i);
            _scrollToCenter(i);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: ShapeDecoration(
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected
                      ? primaryColor
                      : (isDark
                          ? const Color(0x1FFFFFFF)
                          : const Color(0x12000000)),
                  width: 0.8,
                ),
              ),
              color: isSelected
                  ? primaryColor
                  : (isDark
                      ? const Color(0x18FFFFFF)
                      : const Color(0x0C000000)),
            ),
            child: Text(
              text.isNotEmpty ? text : 'Tab ${i + 1}',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? const Color(0xDDFFFFFF)
                        : const Color(0xCC000000)),
                letterSpacing: -0.2,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
