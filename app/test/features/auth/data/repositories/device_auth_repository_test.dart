import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/auth/data/repositories/device_auth_repository.dart';
import 'package:warrantyvault/features/auth/domain/entities/auth_user.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late DeviceAuthRepository repo;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    repo = DeviceAuthRepository(storage: mockStorage);
  });

  group('DeviceAuthRepository', () {
    group('getCurrentUser', () {
      test('generates and stores UUID on first call when none exists',
          () async {
        when(() => mockStorage.read(key: 'device_user_id'))
            .thenAnswer((_) async => null);
        when(() => mockStorage.write(key: 'device_user_id', value: any(named: 'value')))
            .thenAnswer((_) async {});

        final user = await repo.getCurrentUser();

        expect(user, isNotNull);
        expect(user!.userId, isNotEmpty);
        expect(user.email, 'device@local');
        expect(user.provider, AuthProvider.device);
        expect(user.isEmailVerified, isTrue);

        verify(() => mockStorage.write(
              key: 'device_user_id',
              value: any(named: 'value'),
            )).called(1);
      });

      test('returns existing UUID from storage on subsequent calls', () async {
        const storedId = 'existing-uuid-1234';
        when(() => mockStorage.read(key: 'device_user_id'))
            .thenAnswer((_) async => storedId);

        final user = await repo.getCurrentUser();

        expect(user, isNotNull);
        expect(user!.userId, storedId);
        expect(user.email, 'device@local');
        expect(user.provider, AuthProvider.device);
        expect(user.isEmailVerified, isTrue);

        verifyNever(() => mockStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value'),
            ));
      });

      test('returns same UUID across multiple calls when stored', () async {
        const storedId = 'persistent-uuid';
        when(() => mockStorage.read(key: 'device_user_id'))
            .thenAnswer((_) async => storedId);

        final user1 = await repo.getCurrentUser();
        final user2 = await repo.getCurrentUser();

        expect(user1!.userId, user2!.userId);
        expect(user1.userId, storedId);
      });
    });

    group('signOut', () {
      test('is a no-op — user is still returned after signOut', () async {
        const storedId = 'persistent-uuid';
        when(() => mockStorage.read(key: 'device_user_id'))
            .thenAnswer((_) async => storedId);

        await repo.signOut();

        final user = await repo.getCurrentUser();
        expect(user, isNotNull);
        expect(user!.userId, storedId);
      });
    });

    group('deleteAccount', () {
      test('deletes the stored UUID', () async {
        when(() => mockStorage.delete(key: 'device_user_id'))
            .thenAnswer((_) async {});

        await repo.deleteAccount();

        verify(() => mockStorage.delete(key: 'device_user_id')).called(1);
      });
    });

    group('getAvailableProviders', () {
      test('returns only AuthProvider.device', () {
        expect(repo.getAvailableProviders(), [AuthProvider.device]);
      });
    });

    group('unsupported methods', () {
      test('signInWithEmail throws UnsupportedError', () {
        expect(
          () => repo.signInWithEmail(email: 'a@b.c', password: 'pass'),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('signUpWithEmail throws UnsupportedError', () {
        expect(
          () => repo.signUpWithEmail(email: 'a@b.c', password: 'pass'),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('confirmSignUp throws UnsupportedError', () {
        expect(
          () => repo.confirmSignUp(email: 'a@b.c', code: '123456'),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('resendConfirmationCode throws UnsupportedError', () {
        expect(
          () => repo.resendConfirmationCode(email: 'a@b.c'),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('sendPasswordResetCode throws UnsupportedError', () {
        expect(
          () => repo.sendPasswordResetCode(email: 'a@b.c'),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('confirmPasswordReset throws UnsupportedError', () {
        expect(
          () => repo.confirmPasswordReset(
            email: 'a@b.c',
            code: '123456',
            newPassword: 'newpass',
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('signInWithGoogle throws UnsupportedError', () {
        expect(
          () => repo.signInWithGoogle(),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('signInWithApple throws UnsupportedError', () {
        expect(
          () => repo.signInWithApple(),
          throwsA(isA<UnsupportedError>()),
        );
      });
    });
  });
}
