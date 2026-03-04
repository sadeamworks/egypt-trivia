import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egypt_trivia/app.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EgyptTriviaApp()));

    // Verify the app title appears
    expect(find.text('تريفيا مصر'), findsOneWidget);
  });
}
