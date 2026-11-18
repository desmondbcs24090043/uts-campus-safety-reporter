import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_repo/preview/demo_report_photos.dart';
import 'package:team_repo/preview_integrated/preview_app_integrated.dart';

void main() {
  for (final count in [0, 1, 2, 3]) {
    testWidgets('Attached Photos shows exactly $count demo attachments', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DemoAttachedPhotos(
              photos: DemoReportPhoto.samples.take(count).toList(),
            ),
          ),
        ),
      );
      final strip = find.byType(DemoPhotoStrip);
      expect(
        find.text('No photo attached'),
        count == 0 ? findsOneWidget : findsNothing,
      );
      expect(strip, count == 0 ? findsNothing : findsOneWidget);
      expect(find.byType(Image), findsNWidgets(count));
      final viewer = find.byKey(const Key('report-photo-viewer'));
      expect(viewer, findsNothing);
      if (count == 0) return;

      for (final (index, photo)
          in DemoReportPhoto.samples.take(count).indexed) {
        final thumbnail = find.byKey(ValueKey('open-${photo.asset}'));
        await tester.tap(thumbnail);
        await tester.pumpAndSettle();
        expect(viewer, findsOneWidget);
        expect(
          tester.getSize(find.byType(Dialog)),
          tester.view.physicalSize / tester.view.devicePixelRatio,
        );
        final image = find.descendant(of: viewer, matching: find.byType(Image));
        expect(tester.widget<Image>(image).image, AssetImage(photo.asset));
        expect(
          find.text(
            count == 1 ? 'Demo photo' : 'Demo photo ${index + 1} of $count',
          ),
          findsOneWidget,
        );
        expect(
          find.byTooltip('Next photo'),
          count > 1 ? findsOneWidget : findsNothing,
        );
        if (count == 1) {
          final bounds = tester.getRect(viewer);
          final left = await tester.startGesture(
            bounds.center - const Offset(40, 0),
          );
          final right = await tester.startGesture(
            bounds.center + const Offset(40, 0),
          );
          await left.moveBy(const Offset(-40, 0));
          await right.moveBy(const Offset(40, 0));
          await tester.pump();
          final transform = find
              .descendant(of: viewer, matching: find.byType(Transform))
              .first;
          expect(
            tester.widget<Transform>(transform).transform.getMaxScaleOnAxis(),
            greaterThan(1),
          );
          await left.up();
          await right.up();
        }
        await tester.tap(find.byTooltip('Close photo'));
        await tester.pumpAndSettle();
        expect(viewer, findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
