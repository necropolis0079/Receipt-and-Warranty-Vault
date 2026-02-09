import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../notifications/mock_notification_service.dart';
import '../notifications/notification_service.dart';
import '../notifications/reminder_scheduler.dart';
import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/receipt/data/repositories/local_receipt_repository.dart';
import '../../features/receipt/data/services/mock_export_service.dart';
import '../../features/receipt/data/services/mock_image_pipeline_service.dart';
import '../../features/receipt/data/services/mock_ocr_service.dart';
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

  // --- Services ---
  getIt.registerLazySingleton<AppLockService>(() => LocalAuthService());
  getIt.registerLazySingleton<ImagePipelineService>(
    () => MockImagePipelineService(),
  );
  getIt.registerLazySingleton<OcrService>(() => MockOcrService());
  getIt.registerLazySingleton<NotificationService>(
    () => MockNotificationService(),
  );
  getIt.registerLazySingleton<ExportService>(() => MockExportService());
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
      syncQueueDao: getIt<AppDatabase>().syncQueueDao,
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

  // --- Startup tasks ---
  await getIt.allReady();

  // Auto-purge soft-deleted receipts older than 30 days.
  await getIt<ReceiptRepository>().purgeOldDeleted(30);
}
