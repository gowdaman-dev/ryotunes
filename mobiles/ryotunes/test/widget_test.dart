import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ryotunes/app.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('shell shows Home with the floating tab bar', (tester) async {
    await tester.pumpWidget(const RyotunesApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Home'), findsWidgets);
    for (final tab in ['New', 'Radio', 'Library']) {
      expect(find.text(tab), findsOneWidget);
    }
    // Nothing is playing yet.
    expect(find.text('Not Playing'), findsOneWidget);
  });
}
