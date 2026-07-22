import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yours/main.dart' as app;
import 'package:yours/redesign/navigation/main_shell.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cold start and primary navigation remain usable', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byType(MainShell), findsOneWidget);
    final profile = find.bySemanticsLabel(RegExp(r'^(用户|User|ユーザー)$'));
    expect(profile, findsOneWidget);
    await tester.tap(profile);
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel(RegExp(r'^(数据管理|Data management|データ管理)$')),
      findsOneWidget,
    );
  });
}
