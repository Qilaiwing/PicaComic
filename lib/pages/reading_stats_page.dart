import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app_usage.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/reading_stats.dart';
import 'package:pica_comic/pages/history_page.dart';
import 'package:pica_comic/tools/translations.dart';

class ReadingStatsPage extends StatelessWidget {
  const ReadingStatsPage({super.key});

  static String fmt(int ms) {
    final m = ms ~/ 60000;
    if (m < 60) return "${m}m";
    final h = m ~/ 60;
    final rm = m % 60;
    if (h < 24) return rm == 0 ? "${h}h" : "${h}h ${rm}m";
    return "${h ~/ 24}d ${h % 24}h";
  }

  @override
  Widget build(BuildContext context) {
    final stats = ReadingStats.instance;
    final today = stats.today;
    final top = stats.topComics(10);
    final history = HistoryManager().getAll();
    final sources = <String, int>{};
    for (final h in history) {
      final n = h.type.displayName;
      sources[n] = (sources[n] ?? 0) + 1;
    }
    final sourceList = sources.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return MiuixScaffold(
      content: (_) => SmoothCustomScrollView(
        slivers: [
          SliverAppbar(
            title: Text("阅读统计".tl),
            largeTitle: Text("阅读统计".tl),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _summary(context, [
                  ("今日阅读".tl, fmt(today[0])),
                  ("今日翻页".tl, "${today[1]}"),
                  ("累计阅读".tl, fmt(stats.totalMs)),
                ]),
                const SizedBox(height: 10),
                _summary(context, [
                  ("累计翻页".tl, "${stats.totalPages}"),
                  ("读过漫画".tl, "${history.length}"),
                  ("活跃天数".tl, "${stats.activeDays}"),
                ]),
                const SizedBox(height: 10),
                _usageRow(context),
                const SizedBox(height: 12),
                const _TrendChart(),
                const SizedBox(height: 12),
                _section(
                    context,
                    "最常读 Top 10".tl,
                    top.isEmpty
                        ? _empty(context, "开始阅读后这里会显示最常读的漫画".tl)
                        : Column(
                            children: [
                              for (var i = 0; i < top.length; i++)
                                _topItem(context, i, top[i]),
                            ],
                          )),
                const SizedBox(height: 12),
                _section(
                    context,
                    "来源分布".tl,
                    sourceList.isEmpty
                        ? _empty(context, "暂无历史记录".tl)
                        : _sources(context, sourceList, history.length)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "阅读时长与翻页从 4.2.13 版本起开始记录".tl,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5)),
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(BuildContext context, List<(String, String)> items) {
    final primary = Theme.of(context).colorScheme.primary;
    final on = Theme.of(context).colorScheme.onSurface;
    return MiuixCard(
      cornerRadius: 18,
      insideMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          for (final (t, v) in items)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 11.5, color: on.withOpacity(0.6))),
                  const SizedBox(height: 6),
                  Text(v,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    return MiuixCard(
      cornerRadius: 18,
      insideMargin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5))),
        ),
      );

  Widget _usageRow(BuildContext context) {
    final on = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;
    return MiuixCard(
      cornerRadius: 18,
      insideMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 18, color: primary),
          const SizedBox(width: 8),
          Expanded(
              child: Text("累计使用 App".tl,
                  style: TextStyle(fontSize: 13, color: on.withOpacity(0.7)))),
          Text(fmt(AppUsageTracker.instance.totalMilliseconds),
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: primary)),
        ],
      ),
    );
  }

  static Widget emptyHint(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.5))),
        ),
      );

  static Widget chart(BuildContext context, List<(DateTime, int, int)> days,
      {required bool monthly}) {
    final primary = Theme.of(context).colorScheme.primary;
    final on = Theme.of(context).colorScheme.onSurface;
    final maxMs = days.fold<int>(0, (a, b) => math.max(a, b.$2));
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Tooltip(
                    message: monthly
                        ? "${d.$1.year}/${d.$1.month}  ${fmt(d.$2)}  ${d.$3}P"
                        : "${d.$1.month}/${d.$1.day}  ${fmt(d.$2)}  ${d.$3}P",
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: days.length > 14 ? 1.5 : 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: maxMs == 0
                                ? 4
                                : math.max(4, 120 * d.$2 / maxMs).toDouble(),
                            decoration: ShapeDecoration(
                              color: d.$2 == 0
                                  ? on.withOpacity(0.08)
                                  : primary.withOpacity(
                                      d == days.last ? 1 : 0.55),
                              shape:
                                  const MiuixSquircleBorder(cornerRadius: 5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (var i = 0; i < days.length; i++)
              Expanded(
                child: Text(
                  monthly
                      ? "${days[i].$1.month}${"月".tl}"
                      : (days.length <= 14 || i % 5 == (days.length - 1) % 5)
                          ? "${days[i].$1.day}"
                          : "",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: on.withOpacity(0.5)),
                ),
              ),
          ],
        ),
        if (maxMs == 0) emptyHint(context, "这段时间还没有阅读记录".tl),
      ],
    );
  }

  Widget _topItem(BuildContext context, int i,
      MapEntry<String, Map<String, dynamic>> e) {
    final primary = Theme.of(context).colorScheme.primary;
    final on = Theme.of(context).colorScheme.onSurface;
    final v = e.value;
    final h = HistoryManager().findSync(e.key);
    return MiuixPressable(
      shape: const MiuixSquircleBorder(cornerRadius: 12),
      feedbackType: h != null
          ? MiuixPressFeedbackType.sink
          : MiuixPressFeedbackType.none,
      onPressed: h == null
          ? null
          : () {
              if (h.type.comicSource == null) {
                showToast(message: "该漫画源已停用或不存在".tl);
                return;
              }
              toComicPageWithHistory(context, h);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: primary.withOpacity(i < 3 ? 0.9 : 0.12),
                shape: const MiuixSquircleBorder(cornerRadius: 8),
              ),
              child: Text("${i + 1}",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i < 3 ? Colors.white : primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v['title']?.toString() ?? e.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                      "${ReadingStats.sourceNameOf(v)} · ${v['pages'] ?? 0}P",
                      style:
                          TextStyle(fontSize: 11.5, color: on.withOpacity(0.5))),
                ],
              ),
            ),
            Text(fmt(v['ms'] as int? ?? 0),
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: primary)),
          ],
        ),
      ),
    );
  }

  Widget _sources(
      BuildContext context, List<MapEntry<String, int>> list, int total) {
    final primary = Theme.of(context).colorScheme.primary;
    final on = Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        for (final e in list)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                    width: 80,
                    child: Text(e.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13))),
                Expanded(
                  child: ClipPath(
                    clipper: const ShapeBorderClipper(
                        shape: MiuixSquircleBorder(cornerRadius: 4)),
                    child: LinearProgressIndicator(
                      value: e.value / total,
                      minHeight: 8,
                      color: primary,
                      backgroundColor: on.withOpacity(0.08),
                    ),
                  ),
                ),
                SizedBox(
                    width: 44,
                    child: Text("${e.value}",
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontSize: 12, color: on.withOpacity(0.6)))),
              ],
            ),
          ),
      ],
    );
  }
}

class _TrendChart extends StatefulWidget {
  const _TrendChart();

  @override
  State<_TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<_TrendChart> {
  int mode = 0;

  @override
  Widget build(BuildContext context) {
    final stats = ReadingStats.instance;
    final primary = Theme.of(context).colorScheme.primary;
    final labels = ["近14天".tl, "近30天".tl, "按月".tl];
    final data = mode == 0
        ? stats.lastDays(14)
        : mode == 1
            ? stats.lastDays(30)
            : stats.months();
    Widget chart = ReadingStatsPage.chart(context, data, monthly: mode == 2);
    if (mode == 2 && data.length > 8) {
      chart = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        child: SizedBox(width: data.length * 40.0, child: chart),
      );
    }
    return MiuixCard(
      cornerRadius: 18,
      insideMargin: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text("阅读趋势".tl,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            Builder(builder: (ctx) {
              return MiuixPressable(
                shape: const MiuixSquircleBorder(cornerRadius: 12),
                feedbackType: MiuixPressFeedbackType.sink,
                onPressed: () async {
                  final i = await showMiuixMenu(
                    context: ctx,
                    anchorBounds: miuixAnchorRectOf(ctx),
                    alignment: MiuixPopupAlign.end,
                    items: labels,
                    selectedIndex: mode,
                  );
                  if (i != null && mounted) setState(() => mode = i);
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
                  decoration: ShapeDecoration(
                    color: primary.withOpacity(0.12),
                    shape: const MiuixSquircleBorder(cornerRadius: 12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(labels[mode],
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: primary)),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 16, color: primary),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        chart,
      ],
      ),
    );
  }
}
