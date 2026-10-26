// 顶栏高度上报的回归测试。
//
// 背景：页面内容上沿原来是写死的 114 / 176，而顶栏真实高度是
// 「状态栏 + 52 + 大标题行高 + 6 (+ Tab 条)」。状态栏更高或系统字体被放大时，
// 内容会被顶栏压住。这里验证顶栏把自己真实高度报出来、并且和实测布局一致。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/miuix.dart';

/// 造一个和 App 里一样的「顶栏 + 内容」组合，返回内容区域的顶部位置。
Future<double> pumpAndMeasure({
  required WidgetTester tester,
  required double topInset,
  required double textScale,
  Widget? bottomContent,
  String title = 'Pica Comic',
}) async {
  MiuixTopAppBarHeightInfo? reported;

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          padding: EdgeInsets.only(top: topInset),
          textScaler: TextScaler.linear(textScale),
        ),
        child: MiuixTheme(
          data: MiuixThemeData.light(),
          child: Column(
            children: [
              MiuixTopAppBar(
                title: title,
                scrollBehavior: MiuixExitUntilCollapsedScrollBehavior(),
                onHeightChanged: (info) => reported = info,
                bottomContent: bottomContent,
              ),
              const Expanded(child: SizedBox.expand()),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(reported, isNotNull, reason: '顶栏应该上报自己的高度');
  expect(reported!.expanded, greaterThan(0));

  // 顶栏实际渲染高度应该和上报的展开高度一致。
  final topBarSize = tester.getSize(find.byType(MiuixTopAppBar));
  expect(
    topBarSize.height,
    closeTo(reported!.expanded, 0.5),
    reason: '上报的展开高度必须等于实际渲染高度',
  );

  // 再加一个带折叠的验证：collapsed 应该正好等于「状态栏 + 52 + Tab 条」。
  final tabHeight = bottomContent == null ? 0.0 : 44.0;
  expect(
    reported!.collapsed,
    closeTo(topInset + 52 + tabHeight, 0.5),
    reason: '折叠到底只剩状态栏 + 折叠带 + bottomContent',
  );

  return reported!.expanded;
}

void main() {
  testWidgets('状态栏变高时，上报高度跟着变高', (tester) async {
    final small = await pumpAndMeasure(
        tester: tester, topInset: 24, textScale: 1.0);
    final large = await pumpAndMeasure(
        tester: tester, topInset: 48, textScale: 1.0);
    expect(large - small, closeTo(24, 0.5));
  });

  testWidgets('系统字体放大时，上报高度包含多出来的标题行高', (tester) async {
    final normal = await pumpAndMeasure(
        tester: tester, topInset: 24, textScale: 1.0);
    final scaled = await pumpAndMeasure(
        tester: tester, topInset: 24, textScale: 1.3);
    expect(scaled, greaterThan(normal),
        reason: '字体放大后标题行高变大，顶栏应该更高');
  });

  testWidgets('带 Tab 条时上报高度包含 Tab 条', (tester) async {
    final without =
        await pumpAndMeasure(tester: tester, topInset: 24, textScale: 1.0);
    final withTabs = await pumpAndMeasure(
      tester: tester,
      topInset: 24,
      textScale: 1.0,
      bottomContent: const SizedBox(height: 44),
    );
    // 44 的 Tab 条 + 顶栏原有给 bottomContent 预留的 6 间距（包内既有布局）。
    expect(withTabs - without, closeTo(44 + 6, 0.5));
  });
}
