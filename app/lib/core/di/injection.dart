import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../notifications/local_notification_service.dart';
import '../notifications/notification_service.dart';
import '../notifications/reminder_scheduler.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/bulk_import/data/services/device_gallery_scanner_service.dart';
import '../../features/bulk_import/domain/services/gallery_scanner_service.dart';
import '../../features/bulk_import/presentation/cubit/bulk_import_cubit.dart';
import '../../features/receipt/data/repositories/local_receipt_repository.dart';
import '../../features/receipt/data/services/device_export_service.dart';
import '../../features/receipt/data/services/device_image_pipeline_service.dart';
import '../../features/receipt/data/services/hybrid_ocr_service.dart';
import '../../features/receipt/domain/repositories/receipt_repository.dart';
import '../../features/receipt/domain/services/export_service.dart';
import '../../features/receipt/domain/services/image_pipeline_service.dart';
import '../../features/receipt/domain/services/ocr_service.dart';
import '../../features/receipt/presentation/bloc/category_cubit.dart';
import '../../features/receipt/presentation/bloc/trash_cubit.dart';
import '../../features/receipt/presentation/bloc/vault_bloc.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/warranty/presentation/bloc/expiring_bloc.dart';
import '../security/app_lock_cubit.dart';
import '../security/app_lock_service.dart';
import '../security/local_auth_service.dart';

final getIt = GetIt.instance;

/// Configures all dependency injection bindings.
///
/// Must be called before [runApp] in main.dart.
/// Uses manual registration (no code-gen) for simplicity.
Future<void> configureDependencies() async {
  // --- Database (async) ---
  getIt.registerSingletonAsync<AppDatabase>(
    () => DatabaseProvider.getInstance(),
  );

  // --- Core Services ---
  getIt.registerLazySingleton<AppLockService>(() => LocalAuthService());
  getIt.registerLazySingleton<ImagePipelineService>(
    () => DeviceImagePipelineService(),
  );
  getIt.registerLazySingleton<OcrService>(
    () => HybridOcrService(),
    dispose: (service) => (service as HybridOcrService).dispose(),
  );
  getIt.registerLazySingleton<NotificationService>(
    () => LocalNotificationService(),
  );
  getIt.registerLazySingleton<ExportService>(() => DeviceExportService());
  getIt.registerLazySingleton<GalleryScannerService>(
    () => DeviceGalleryScannerService(),
  );
  getIt.registerLazySingleton<ReminderScheduler>(
    () => ReminderScheduler(
      notificationService: getIt<NotificationService>(),
    ),
  );

  // --- Repositories ---
  getIt.registerLazySingleton<AuthRepository>(() => MockAuthRepository());

  getIt.registerSingletonWithDependencies<ReceiptRepository>(
    () => LocalReceiptRepository(
      receiptsDao: getIt<AppDatabase>().receiptsDao,
    ),
    dependsOn: [AppDatabase],
  );

  // --- BLoCs / Cubits ---
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerFactory<AppLockCubit>(
    () => AppLockCubit(appLockService: getIt<AppLockService>()),
  );
  getIt.registerFactory<VaultBloc>(
    () => VaultBloc(receiptRepository: getIt<ReceiptRepository>()),
  );
  getIt.registerFactory<ExpiringBloc>(
    () => ExpiringBloc(
      receiptRepository: getIt<ReceiptRepository>(),
      reminderScheduler: getIt<ReminderScheduler>(),
      settingsDao: getIt<AppDatabase>().settingsDao,
    ),
  );
  getIt.registerFactory<CategoryManagementCubit>(
    () => CategoryManagementCubit(
      categoriesDao: getIt<AppDatabase>().categoriesDao,
    ),
  );
  getIt.registerFactoryParam<SearchBloc, String, void>(
    (userId, _) => SearchBloc(
      receiptRepository: getIt<ReceiptRepository>(),
      userId: userId,
    ),
  );
  getIt.registerFactoryParam<TrashCubit, String, void>(
    (userId, _) => TrashCubit(
      receiptRepository: getIt<ReceiptRepository>(),
      userId: userId,
    ),
  );
  getIt.registerFactory<BulkImportCubit>(
    () => BulkImportCubit(
      galleryScannerService: getIt<GalleryScannerService>(),
      imagePipelineService: getIt<ImagePipelineService>(),
      ocrService: getIt<OcrService>(),
      receiptRepository: getIt<ReceiptRepository>(),
    ),
  );

  // --- Startup tasks ---
  await getIt.allReady();

  // Auto-purge soft-deleted receipts older than 30 days.
  await getIt<ReceiptRepository>().purgeOldDeleted(30);
}
