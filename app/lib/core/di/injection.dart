import 'package:get_it/get_it.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../network/api_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/connectivity_interceptor.dart';
import '../notifications/mock_notification_service.dart';
import '../notifications/notification_service.dart';
import '../notifications/reminder_scheduler.dart';
import '../services/connectivity_service.dart';
import '../sync/conflict_resolver.dart';
import '../sync/image_sync_service.dart';
import '../sync/sync_service.dart';
import '../../features/auth/data/repositories/amplify_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/receipt/data/datasources/image_remote_source.dart';
import '../../features/receipt/data/datasources/receipt_remote_source.dart';
import '../../features/receipt/data/datasources/sync_remote_source.dart';
import '../../features/receipt/data/repositories/local_receipt_repository.dart';
import '../../features/receipt/data/repositories/sync_aware_receipt_repository.dart';
import '../../features/receipt/data/services/mock_export_service.dart';
import '../../features/receipt/data/services/mock_image_pipeline_service.dart';
import '../../features/receipt/data/services/mock_ocr_service.dart';
import '../../features/receipt/domain/repositories/receipt_repository.dart';
import '../../features/receipt/domain/services/export_service.dart';
import '../../features/receipt/domain/services/image_pipeline_service.dart';
import '../../features/receipt/domain/services/ocr_service.dart';
import '../../features/receipt/presentation/bloc/category_cubit.dart';
import '../../features/receipt/presentation/bloc/sync_bloc.dart';
import '../../features/receipt/presentation/bloc/trash_cubit.dart';
import '../../features/receipt/presentation/bloc/vault_bloc.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/settings/data/datasources/settings_remote_source.dart';
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
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
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

  // --- Network ---
  getIt.registerLazySingleton<AuthInterceptor>(() => AuthInterceptor());
  getIt.registerLazySingleton<ConnectivityInterceptor>(
    () => ConnectivityInterceptor(
      connectivityService: getIt<ConnectivityService>(),
    ),
  );
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      authInterceptor: getIt<AuthInterceptor>(),
      connectivityInterceptor: getIt<ConnectivityInterceptor>(),
    ),
  );

  // --- Remote Data Sources ---
  getIt.registerLazySingleton<ReceiptRemoteSource>(
    () => ReceiptRemoteSource(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SyncRemoteSource>(
    () => SyncRemoteSource(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<ImageRemoteSource>(
    () => ImageRemoteSource(apiClient: getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<SettingsRemoteSource>(
    () => SettingsRemoteSource(apiClient: getIt<ApiClient>()),
  );

  // --- Repositories ---
  getIt.registerLazySingleton<AuthRepository>(() => AmplifyAuthRepository());

  // Local receipt repository (still used internally by SyncAwareReceiptRepository)
  getIt.registerSingletonWithDependencies<LocalReceiptRepository>(
    () => LocalReceiptRepository(
      receiptsDao: getIt<AppDatabase>().receiptsDao,
      syncQueueDao: getIt<AppDatabase>().syncQueueDao,
    ),
    dependsOn: [AppDatabase],
  );

  // --- Sync Engine ---
  getIt.registerLazySingleton<ConflictResolver>(() => ConflictResolver());
  getIt.registerSingletonWithDependencies<SyncService>(
    () => SyncService(
      receiptsDao: getIt<AppDatabase>().receiptsDao,
      syncQueueDao: getIt<AppDatabase>().syncQueueDao,
      syncRemoteSource: getIt<SyncRemoteSource>(),
      conflictResolver: getIt<ConflictResolver>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
    dependsOn: [AppDatabase],
  );
  getIt.registerSingletonWithDependencies<ImageSyncService>(
    () => ImageSyncService(
      imageRemoteSource: getIt<ImageRemoteSource>(),
      receiptsDao: getIt<AppDatabase>().receiptsDao,
    ),
    dependsOn: [AppDatabase],
  );

  // SyncAwareReceiptRepository — the primary ReceiptRepository implementation
  getIt.registerSingletonWithDependencies<ReceiptRepository>(
    () => SyncAwareReceiptRepository(
      localRepository: getIt<LocalReceiptRepository>(),
      syncService: getIt<SyncService>(),
      connectivityService: getIt<ConnectivityService>(),
    ),
    dependsOn: [LocalReceiptRepository, SyncService],
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
  getIt.registerFactoryParam<SyncBloc, String, void>(
    (userId, _) => SyncBloc(
      syncService: getIt<SyncService>(),
      connectivityService: getIt<ConnectivityService>(),
      syncQueueDao: getIt<AppDatabase>().syncQueueDao,
      userId: userId,
    ),
  );

  // --- Startup tasks ---
  await getIt.allReady();

  // Auto-purge soft-deleted receipts older than 30 days.
  await getIt<ReceiptRepository>().purgeOldDeleted(30);
}
