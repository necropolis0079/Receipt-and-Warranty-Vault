import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/database/app_database.dart';
import 'package:warrantyvault/core/l10n/locale_cubit.dart';
import 'package:warrantyvault/core/notifications/mock_notification_service.dart';
import 'package:warrantyvault/core/notifications/notification_service.dart';
import 'package:warrantyvault/core/notifications/reminder_scheduler.dart';
import 'package:warrantyvault/core/security/app_lock_cubit.dart';
import 'package:warrantyvault/core/security/app_lock_service.dart';
import 'package:warrantyvault/core/theme/theme_cubit.dart';
import 'package:warrantyvault/features/auth/domain/repositories/auth_repository.dart';
import 'package:warrantyvault/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:warrantyvault/features/receipt/domain/entities/image_data.dart';
import 'package:warrantyvault/features/receipt/domain/entities/ocr_result.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/domain/services/image_pipeline_service.dart';
import 'package:warrantyvault/features/receipt/domain/services/ocr_service.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/trash_cubit.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/vault_bloc.dart';
import 'package:warrantyvault/features/search/presentation/bloc/search_bloc.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_bloc.dart';

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAppLockService extends Mock implements AppLockService {}

class MockReceiptRepository extends Mock implements ReceiptRepository {}

class MockImagePipelineService extends Mock implements ImagePipelineService {}

class MockOcrService extends Mock implements OcrService {}

class FakeReceipt extends Fake implements Receipt {}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const testImage = ImageData(
  id: 'img-1',
  localPath: '/tmp/receipt1.jpg',
  sizeBytes: 1024,
  mimeType: 'image/jpeg',
);

const testImage2 = ImageData(
  id: 'img-2',
  localPath: '/tmp/receipt2.jpg',
  sizeBytes: 2048,
  mimeType: 'image/jpeg',
);

const highConfidenceOcr = OcrResult(
  rawText: 'Store ABC\n2024-01-15\nTotal: 49.99 EUR',
  extractedStoreName: 'Store ABC',
  extractedDate: '2024-01-15',
  extractedTotal: 49.99,
  extractedCurrency: 'EUR',
  confidence: 0.85,
);

const lowConfidenceOcr = OcrResult(
  rawText: 'blurry text',
  confidence: 0.2,
);

// ---------------------------------------------------------------------------
// Setup helpers
// ---------------------------------------------------------------------------

/// Holds all mocks and blocs for a test scenario. Dispose via [tearDown].
class TestContext {
  late MockAuthRepository authRepo;
  late MockAppLockService lockService;
  late MockReceiptRepository receiptRepo;
  late MockImagePipelineService imagePipeline;
  late MockOcrService ocrService;
  late MockNotificationService notificationService;

  late AuthBloc authBloc;
  late AppLockCubit lockCubit;
  late LocaleCubit localeCubit;
  late ThemeCubit themeCubit;
  late VaultBloc vaultBloc;
  late ExpiringBloc expiringBloc;
  late SearchBloc searchBloc;
  late TrashCubit trashCubit;

  late AppDatabase db;
  final getIt = GetIt.instance;
}

/// Call this in setUp. Returns a [TestContext] pre-configured with mocks.
Future<TestContext> setUpTestContext() async {
  final ctx = TestContext();

  ctx.authRepo = MockAuthRepository();
  ctx.lockService = MockAppLockService();
  ctx.receiptRepo = MockReceiptRepository();
  ctx.imagePipeline = MockImagePipelineService();
  ctx.ocrService = MockOcrService();
  ctx.notificationService = MockNotificationService();

  // Default stubs
  when(() => ctx.receiptRepo.watchUserReceipts(any()))
      .thenAnswer((_) => Stream.value([]));
  when(() => ctx.receiptRepo.getExpiringWarranties(any(), any()))
      .thenAnswer((_) async => []);
  when(() => ctx.receiptRepo.getExpiredWarranties(any()))
      .thenAnswer((_) async => []);
  when(() => ctx.receiptRepo.search(any(), any()))
      .thenAnswer((_) async => []);
  when(() => ctx.receiptRepo.watchByStatus(any(), any()))
      .thenAnswer((_) => Stream.value([]));
  when(() => ctx.receiptRepo.saveReceipt(any())).thenAnswer((_) async {});
  when(() => ctx.lockService.isDeviceSupported())
      .thenAnswer((_) async => false);
  when(() => ctx.authRepo.getCurrentUser()).thenAnswer((_) async => null);
  when(() => ctx.authRepo.signOut()).thenAnswer((_) async {});
  when(() => ctx.imagePipeline.requestCameraPermission())
      .thenAnswer((_) async => true);
  when(() => ctx.imagePipeline.requestStoragePermission())
      .thenAnswer((_) async => true);

  registerFallbackValue(FakeReceipt());
  registerFallbackValue(ReceiptStatus.active);

  // BLoCs
  ctx.authBloc = AuthBloc(authRepository: ctx.authRepo);
  ctx.lockCubit = AppLockCubit(appLockService: ctx.lockService);
  ctx.localeCubit = LocaleCubit();
  ctx.themeCubit = ThemeCubit();
  ctx.vaultBloc = VaultBloc(receiptRepository: ctx.receiptRepo);
  ctx.expiringBloc = ExpiringBloc(receiptRepository: ctx.receiptRepo);
  ctx.searchBloc =
      SearchBloc(receiptRepository: ctx.receiptRepo, userId: 'test');
  ctx.trashCubit =
      TrashCubit(receiptRepository: ctx.receiptRepo, userId: 'test');

  // In-memory Drift database
  ctx.db = AppDatabase.forTesting(NativeDatabase.memory());

  // GetIt registrations
  await ctx.getIt.reset();
  ctx.getIt.registerSingleton<AppDatabase>(ctx.db);
  ctx.getIt.registerSingleton<NotificationService>(ctx.notificationService);
  ctx.getIt.registerSingleton<ReminderScheduler>(
    ReminderScheduler(
      notificationService: ctx.notificationService,
      settingsDao: ctx.db.settingsDao,
    ),
  );
  ctx.getIt.registerSingleton<ImagePipelineService>(ctx.imagePipeline);
  ctx.getIt.registerSingleton<OcrService>(ctx.ocrService);
  ctx.getIt.registerSingleton<ReceiptRepository>(ctx.receiptRepo);

  return ctx;
}

/// Call this in tearDown.
Future<void> tearDownTestContext(TestContext ctx) async {
  ctx.authBloc.close();
  ctx.lockCubit.close();
  ctx.localeCubit.close();
  ctx.themeCubit.close();
  ctx.vaultBloc.close();
  ctx.expiringBloc.close();
  ctx.searchBloc.close();
  ctx.trashCubit.close();
  await ctx.db.close();
  await ctx.getIt.reset();
}

/// Build a test MaterialApp with all required providers for a given [child].
Widget buildTestApp(TestContext ctx, Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: ctx.authBloc),
        BlocProvider.value(value: ctx.lockCubit),
        BlocProvider.value(value: ctx.localeCubit),
        BlocProvider.value(value: ctx.themeCubit),
        BlocProvider.value(value: ctx.vaultBloc),
        BlocProvider.value(value: ctx.expiringBloc),
        BlocProvider.value(value: ctx.searchBloc),
        BlocProvider.value(value: ctx.trashCubit),
      ],
      child: child,
    ),
  );
}
