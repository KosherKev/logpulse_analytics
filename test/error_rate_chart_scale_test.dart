import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logpulse_analytics/presentation/widgets/dashboard/error_rate_chart.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('dual-axis scale helpers (Phase 22)', () {
    test('traffic-dominant: error transform not squashed near zero', () {
      // Traffic peaks at 1000; error rate peaks at 2% — shared axis would
      // squash error to 2/1000 of height. Independent scale should put peak
      // error near full chart height (trafficMaxY).
      final traffic = [
        const FlSpot(0, 800),
        const FlSpot(1, 1000),
        const FlSpot(2, 900),
      ];
      final errors = [
        const FlSpot(0, 0.5),
        const FlSpot(1, 2.0),
        const FlSpot(2, 1.0),
      ];

      final tMax = computeTrafficMaxY(traffic);
      final eMax = computeErrorMaxY(errors);
      // 1000 * 1.25 = 1250 → niceCeil → 1500
      expect(tMax, 1500);
      // 2% * 1.25 = 2.5, floor 5.0 → nice stays 5
      expect(eMax, kErrorAxisFloorPercent);

      final plotted = transformErrorPointsForPlot(
        errors,
        errorMaxY: eMax,
        trafficMaxY: tMax,
      );

      // Peak true error 2.0 on a 5.0 axis → 40% of host height → well above floor.
      final peakPlotY = plotted.map((p) => p.y).reduce((a, b) => a > b ? a : b);
      expect(peakPlotY, greaterThan(tMax * 0.3));
      expect(peakPlotY, lessThanOrEqualTo(tMax));

      // True values still recoverable for tooltips.
      expect(trueErrorValueAtX(errors, 1), 2.0);
      expect(trueErrorValueAtX(errors, 0), 0.5);
    });

    test('all-zero error series: floor applies, no divide-by-zero', () {
      final errors = [
        const FlSpot(0, 0),
        const FlSpot(1, 0),
      ];
      final eMax = computeErrorMaxY(errors);
      expect(eMax, kErrorAxisFloorPercent);

      final plotted = transformErrorPointsForPlot(
        errors,
        errorMaxY: eMax,
        trafficMaxY: 100,
      );
      expect(plotted.every((p) => p.y == 0), isTrue);
    });

    test('empty traffic: host scale defaults to 1.0', () {
      expect(computeTrafficMaxY(const []), 1.0);
      final plotted = transformErrorPointsForPlot(
        const [FlSpot(0, 10), FlSpot(1, 20)],
        errorMaxY: computeErrorMaxY(const [FlSpot(0, 10), FlSpot(1, 20)]),
        trafficMaxY: computeTrafficMaxY(const []),
      );
      expect(plotted, hasLength(2));
      // Max true error 20% with headroom 25, clamped — peak plots near host max.
      expect(plotted.last.y, greaterThan(0.5));
    });

    test('errorMaxY clamps at 100', () {
      final errors = [const FlSpot(0, 90), const FlSpot(1, 100)];
      // 100 * 1.25 = 125 → clamp to 100 → nice stays 100
      expect(computeErrorMaxY(errors), 100.0);
    });

    test('niceCeilMax rounds awkward headroom (109 → 150)', () {
      expect(niceCeilMax(108.75), 150);
      expect(niceCeilMax(43), 50);
    });

    test('axis ticks are exactly 0 / mid / top — no stacked max labels', () {
      // Old bug: maxY=109 interval=20 showed both 100 and 109.
      final ticks = axisTickHosts(109, 20);
      expect(ticks.first, 0);
      expect(ticks.last, 100); // floor step, not 109
      expect(ticks.where((t) => t > 90).length, 1);

      expect(isAxisTick(0, 109, 20), isTrue);
      expect(isAxisTick(100, 109, 20), isTrue);
      expect(isAxisTick(109, 109, 20), isFalse); // not a preferred host
      expect(isAxisTick(80, 109, 20), isFalse);
    });

    test('formatPercentTick uses 0% not 0.0%', () {
      expect(formatPercentTick(0), '0%');
      expect(formatPercentTick(40), '40%');
      expect(formatPercentTick(9.5), '9.5%');
    });

    test('tooltip lookup uses true %, not transformed y', () {
      const trueErrors = [
        FlSpot(0, 1.5),
        FlSpot(1, 33.00970873786408),
      ];
      final tMax = 1250.0;
      final eMax = computeErrorMaxY(trueErrors);
      final plotted = transformErrorPointsForPlot(
        trueErrors,
        errorMaxY: eMax,
        trafficMaxY: tMax,
      );

      // Transformed y is NOT the true percentage.
      expect(plotted[1].y, isNot(closeTo(33.00970873786408, 0.01)));

      // Lookup returns true value for tooltip formatting.
      final trueVal = trueErrorValueAtX(trueErrors, plotted[1].x)!;
      expect(trueVal, closeTo(33.00970873786408, 1e-9));
      expect('${trueVal.toStringAsFixed(1)}%', '33.0%');
    });
  });

  group('ErrorRateChart widget', () {
    testWidgets('legacy single-series still renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRateChart(
              points: const [
                FlSpot(0, 0),
                FlSpot(1, 1),
                FlSpot(2, 0.5),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No data'), findsNothing);
    });

    testWidgets('dual series with traffic-dominant data renders',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorRateChart(
              trafficPoints: const [
                FlSpot(0, 800),
                FlSpot(1, 1000),
                FlSpot(2, 900),
              ],
              errorPoints: const [
                FlSpot(0, 0.5),
                FlSpot(1, 2.0),
                FlSpot(2, 1.0),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Traffic & Errors'), findsOneWidget);
      expect(find.text('errors %'), findsOneWidget);
    });

    testWidgets('empty traffic + present errors does not crash',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorRateChart(
              trafficPoints: [],
              errorPoints: [
                FlSpot(0, 5),
                FlSpot(1, 10),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('both empty shows No data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorRateChart(
              trafficPoints: [],
              errorPoints: [],
            ),
          ),
        ),
      );
      expect(find.text('No data'), findsOneWidget);
    });
  });
}
