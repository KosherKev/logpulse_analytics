import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logpulse_analytics/app.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: LogPulseApp(),
      ),
    );
    expect(find.byType(LogPulseApp), findsOneWidget);
  });
}
