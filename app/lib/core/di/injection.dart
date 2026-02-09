import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/mock_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../security/app_lock_cubit.dart';
import '../security/app_lock_service.dart';
import '../security/local_auth_service.dart';

final getIt = GetIt.instance;

/// Configures all dependency injection bindings.
///
/// Must be called before [runApp] in main.dart.
/// Uses manual registration (no code-gen) for simplicity.
Future<void> configureDependencies() async {
  // --- Services ---
  getIt.registerLazySingleton<AppLockService>(() => LocalAuthService());

  // --- Repositories ---
  getIt.registerLazySingleton<AuthRepository>(() => MockAuthRepository());

  // --- BLoCs / Cubits ---
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerFactory<AppLockCubit>(
    () => AppLockCubit(appLockService: getIt<AppLockService>()),
  );
}
