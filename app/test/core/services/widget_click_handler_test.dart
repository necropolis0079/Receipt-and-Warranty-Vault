import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:warrantyvault/core/services/widget_click_handler.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/domain/services/image_pipeline_service.dart';
import 'package:warrantyvault/features/receipt/domain/services/ocr_service.dart';
import 'package:warrantyvault/features/receipt/presentation/screens/add_receipt_screen.dart';

class MockImagePipelineService extends Mock implements ImagePipelineService {}

class MockOcrService extends Mock implements OcrService {}

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  final getIt = GetIt.instance;

  setUp(() async {
    await getIt.reset();
    final mockPipeline = MockImagePipelineService();
    // Stub permission checks so AddReceiptScreen's auto-capture doesn't fail.
    when(() => mockPipeline.requestCameraPermission())
        .thenAnswer((_) async => true);
    when(() => mockPipeline.requestStoragePermission())
        .thenAnswer((_) async => true);
    getIt.registerLazySingleton<ImagePipelineService>(() => mockPipeline);
    getIt.registerLazySingleton<OcrService>(() => MockOcrService());
    getIt.registerLazySingleton<ReceiptRepository>(
        () => MockReceiptRepository());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildTestApp({
    required _TestNavigatorObserver observer,
    required Uri uri,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      navigatorObservers: [observer],
      home: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              WidgetClickHandler.handle(uri, context);
            },
            child: const Text('Test'),
          );
        },
      ),
    );
  }

  group('WidgetClickHandler', () {
    testWidgets('camera source navigates to AddReceiptScreen',
        (tester) async {
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(buildTestApp(
        observer: observer,
        uri: Uri.parse('warrantyvault://capture?source=camera'),
      ));

      await tester.tap(find.text('Test'));
      await tester.pump();
      await tester.pump();

      expect(observer.pushedRoutes, equals(1));
      expect(find.byType(AddReceiptScreen), findsOneWidget);
    });

    testWidgets('gallery source navigates to AddReceiptScreen',
        (tester) async {
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(buildTestApp(
        observer: observer,
        uri: Uri.parse('warrantyvault://capture?source=gallery'),
      ));

      await tester.tap(find.text('Test'));
      await tester.pump();
      await tester.pump();

      expect(observer.pushedRoutes, equals(1));
      expect(find.byType(AddReceiptScreen), findsOneWidget);
    });

    testWidgets('files source navigates to AddReceiptScreen',
        (tester) async {
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(buildTestApp(
        observer: observer,
        uri: Uri.parse('warrantyvault://capture?source=files'),
      ));

      await tester.tap(find.text('Test'));
      await tester.pump();
      await tester.pump();

      expect(observer.pushedRoutes, equals(1));
      expect(find.byType(AddReceiptScreen), findsOneWidget);
    });

    testWidgets('unknown source defaults to camera (still pushes)',
        (tester) async {
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(buildTestApp(
        observer: observer,
        uri: Uri.parse('warrantyvault://capture?source=unknown'),
      ));

      await tester.tap(find.text('Test'));
      await tester.pump();
      await tester.pump();

      expect(observer.pushedRoutes, equals(1));
      expect(find.byType(AddReceiptScreen), findsOneWidget);
    });

    testWidgets('missing source parameter defaults to camera (still pushes)',
        (tester) async {
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(buildTestApp(
        observer: observer,
        uri: Uri.parse('warrantyvault://capture'),
      ));

      await tester.tap(find.text('Test'));
      await tester.pump();
      await tester.pump();

      expect(observer.pushedRoutes, equals(1));
      expect(find.byType(AddReceiptScreen), findsOneWidget);
    });

    testWidgets('wrong host does not push any route', (tester) async {
      final observer = _TestNavigatorObserver();
      await tester.pumpWidget(buildTestApp(
        observer: observer,
        uri: Uri.parse('warrantyvault://settings'),
      ));

      await tester.tap(find.text('Test'));
      await tester.pump();

      expect(observer.pushedRoutes, equals(0));
      expect(find.byType(AddReceiptScreen), findsNothing);
    });
  });
}

/// Counts how many routes were pushed (excluding the initial route).
class _TestNavigatorObserver extends NavigatorObserver {
  int pushedRoutes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      pushedRoutes++;
    }
  }
}
