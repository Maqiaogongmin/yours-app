import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yours/redesign/shared/widgets/responsive_action_button.dart';
import 'package:yours/theme/theme.dart';

void main() {
  for (final label in [
    'Create and Export',
    'Restore from iCloud Drive',
    '作成してエクスポート',
    'iCloud Driveから復元',
  ]) {
    testWidgets('action button does not overflow for "$label"', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: yoursLightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(280, 600),
              textScaler: TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 230,
                  child: YoursResponsiveActionButton(
                    label: label,
                    icon: Icons.ios_share_outlined,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text(label), findsOneWidget);
      expect(
        tester.getSize(find.byType(YoursResponsiveActionButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  }
}
