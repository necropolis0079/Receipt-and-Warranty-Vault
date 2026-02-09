import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_bloc.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_event.dart';
import 'package:warrantyvault/features/warranty/presentation/bloc/expiring_state.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  late MockReceiptRepository mockRepo;

  final now = DateTime.now();
  final expiringDate = now.add(const Duration(days: 15)).toIso8601String();
  final expiredDate = now.subtract(const Duration(days: 10)).toIso8601String();

  final expiringSoonReceipt = Receipt(
    receiptId: 'r-exp-1',
    userId: 'user-1',
    storeName: 'Expiring Store',
    warrantyMonths: 12,
    warrantyExpiryDate: expiringDate,
    status: ReceiptStatus.active,
    createdAt: now.toIso8601String(),
    updatedAt: now.toIso8601String(),
  );

  final expiredReceipt = Receipt(
    receiptId: 'r-exp-2',
    userId: 'user-1',
    storeName: 'Expired Store',
    warrantyMonths: 6,
    warrantyExpiryDate: expiredDate,
    status: ReceiptStatus.active,
    createdAt: now.toIso8601String(),
    updatedAt: now.toIso8601String(),
  );

  setUp(() {
    mockRepo = MockReceiptRepository();
  });

  group('ExpiringBloc', () {
    test('initial state is ExpiringInitial', () {
      final bloc = ExpiringBloc(receiptRepository: mockRepo);
      expect(bloc.state, const ExpiringInitial());
      bloc.close();
    });

    // --- ExpiringLoadRequested ---
    group('ExpiringLoadRequested', () {
      blocTest<ExpiringBloc, ExpiringState>(
        'emits [Loading, Loaded] with expiring and expired warranties',
        build: () {
          when(() => mockRepo.getExpiringWarranties(any(), any()))
              .thenAnswer((_) async => [expiringSoonReceipt]);
          when(() => mockRepo.getExpiredWarranties(any()))
              .thenAnswer((_) async => [expiredReceipt]);
          return ExpiringBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const ExpiringLoadRequested('user-1')),
        expect: () => [
          const ExpiringLoading(),
          ExpiringLoaded(
            expiringSoon: [expiringSoonReceipt],
            expired: [expiredReceipt],
          ),
        ],
      );

      blocTest<ExpiringBloc, ExpiringState>(
        'emits [Loading, Empty] when no expiring or expired warranties',
        build: () {
          when(() => mockRepo.getExpiringWarranties(any(), any()))
              .thenAnswer((_) async => []);
          when(() => mockRepo.getExpiredWarranties(any()))
              .thenAnswer((_) async => []);
          return ExpiringBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const ExpiringLoadRequested('user-1')),
        expect: () => [
          const ExpiringLoading(),
          const ExpiringEmpty(),
        ],
      );

      blocTest<ExpiringBloc, ExpiringState>(
        'emits [Loading, Error] on exception',
        build: () {
          when(() => mockRepo.getExpiringWarranties(any(), any()))
              .thenThrow(Exception('DB error'));
          when(() => mockRepo.getExpiredWarranties(any()))
              .thenAnswer((_) async => []);
          return ExpiringBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const ExpiringLoadRequested('user-1')),
        expect: () => [
          const ExpiringLoading(),
          isA<ExpiringError>(),
        ],
      );

      blocTest<ExpiringBloc, ExpiringState>(
        'expiringSoon and expired are separated correctly',
        build: () {
          when(() => mockRepo.getExpiringWarranties(any(), any()))
              .thenAnswer((_) async => [expiringSoonReceipt]);
          when(() => mockRepo.getExpiredWarranties(any()))
              .thenAnswer((_) async => [expiredReceipt]);
          return ExpiringBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const ExpiringLoadRequested('user-1')),
        expect: () => [
          const ExpiringLoading(),
          isA<ExpiringLoaded>()
              .having(
                (s) => s.expiringSoon,
                'expiringSoon',
                [expiringSoonReceipt],
              )
              .having(
                (s) => s.expired,
                'expired',
                [expiredReceipt],
              ),
        ],
      );

      blocTest<ExpiringBloc, ExpiringState>(
        'passes daysAhead to repository',
        build: () {
          when(() => mockRepo.getExpiringWarranties(any(), any()))
              .thenAnswer((_) async => []);
          when(() => mockRepo.getExpiredWarranties(any()))
              .thenAnswer((_) async => []);
          return ExpiringBloc(receiptRepository: mockRepo);
        },
        act: (bloc) =>
            bloc.add(const ExpiringLoadRequested('user-1', daysAhead: 60)),
        verify: (_) {
          verify(() => mockRepo.getExpiringWarranties('user-1', 60)).called(1);
        },
      );
    });

    // --- ExpiringRefreshRequested ---
    group('ExpiringRefreshRequested', () {
      blocTest<ExpiringBloc, ExpiringState>(
        're-fetches data with last userId and daysAhead',
        build: () {
          when(() => mockRepo.getExpiringWarranties(any(), any()))
              .thenAnswer((_) async => [expiringSoonReceipt]);
          when(() => mockRepo.getExpiredWarranties(any()))
              .thenAnswer((_) async => [expiredReceipt]);
          return ExpiringBloc(receiptRepository: mockRepo);
        },
        seed: () => ExpiringLoaded(
          expiringSoon: [expiringSoonReceipt],
          expired: [expiredReceipt],
        ),
        act: (bloc) {
          // First load to set _lastUserId
          bloc.add(const ExpiringLoadRequested('user-1', daysAhead: 45));
        },
        wait: const Duration(milliseconds: 100),
        verify: (_) {
          verify(() => mockRepo.getExpiringWarranties('user-1', 45)).called(1);
        },
      );
    });
  });
}
