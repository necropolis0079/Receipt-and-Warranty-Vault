import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/trash_cubit.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/trash_state.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  late MockReceiptRepository mockRepo;

  const userId = 'user-1';
  final now = DateTime.now().toIso8601String();

  final deletedReceipt1 = Receipt(
    receiptId: 'del-001',
    userId: userId,
    storeName: 'Deleted Store 1',
    status: ReceiptStatus.deleted,
    createdAt: now,
    updatedAt: now,
    deletedAt: now,
  );

  final deletedReceipt2 = Receipt(
    receiptId: 'del-002',
    userId: userId,
    storeName: 'Deleted Store 2',
    status: ReceiptStatus.deleted,
    createdAt: now,
    updatedAt: now,
    deletedAt: now,
  );

  setUp(() {
    mockRepo = MockReceiptRepository();
  });

  group('TrashCubit', () {
    test('initial state has empty receipts, isLoading false, no error', () {
      final cubit = TrashCubit(
        receiptRepository: mockRepo,
        userId: userId,
      );

      expect(cubit.state.receipts, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);

      cubit.close();
    });

    group('loadDeleted', () {
      blocTest<TrashCubit, TrashState>(
        'emits loading then loaded state with deleted receipts',
        build: () {
          when(() => mockRepo.watchByStatus(userId, ReceiptStatus.deleted))
              .thenAnswer(
            (_) => Stream.value([deletedReceipt1, deletedReceipt2]),
          );
          return TrashCubit(
            receiptRepository: mockRepo,
            userId: userId,
          );
        },
        act: (cubit) => cubit.loadDeleted(),
        expect: () => [
          const TrashState(isLoading: true),
          TrashState(
            receipts: [deletedReceipt1, deletedReceipt2],
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockRepo.watchByStatus(userId, ReceiptStatus.deleted),
          ).called(1);
        },
      );

      blocTest<TrashCubit, TrashState>(
        'emits loading then loaded with empty list when no deleted receipts',
        build: () {
          when(() => mockRepo.watchByStatus(userId, ReceiptStatus.deleted))
              .thenAnswer((_) => Stream.value([]));
          return TrashCubit(
            receiptRepository: mockRepo,
            userId: userId,
          );
        },
        act: (cubit) => cubit.loadDeleted(),
        expect: () => [
          const TrashState(isLoading: true),
          const TrashState(receipts: [], isLoading: false),
        ],
      );

      blocTest<TrashCubit, TrashState>(
        'when repository stream errors emits error state',
        build: () {
          when(() => mockRepo.watchByStatus(userId, ReceiptStatus.deleted))
              .thenAnswer(
            (_) => Stream.error(Exception('Database error')),
          );
          return TrashCubit(
            receiptRepository: mockRepo,
            userId: userId,
          );
        },
        act: (cubit) => cubit.loadDeleted(),
        expect: () => [
          const TrashState(isLoading: true),
          isA<TrashState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.error, 'error', isNotNull),
        ],
      );
    });

    group('restoreReceipt', () {
      blocTest<TrashCubit, TrashState>(
        'calls repository.restoreReceipt',
        build: () {
          when(() => mockRepo.restoreReceipt(any()))
              .thenAnswer((_) async {});
          return TrashCubit(
            receiptRepository: mockRepo,
            userId: userId,
          );
        },
        act: (cubit) => cubit.restoreReceipt('del-001'),
        verify: (_) {
          verify(() => mockRepo.restoreReceipt('del-001')).called(1);
        },
      );

      blocTest<TrashCubit, TrashState>(
        'when repository throws emits error state',
        build: () {
          when(() => mockRepo.restoreReceipt(any()))
              .thenThrow(Exception('Restore failed'));
          return TrashCubit(
            receiptRepository: mockRepo,
            userId: userId,
          );
        },
        act: (cubit) => cubit.restoreReceipt('del-001'),
        expect: () => [
          isA<TrashState>()
              .having((s) => s.error, 'error', isNotNull)
              .having(
                (s) => s.error,
                'error message',
                contains('Restore failed'),
              ),
        ],
      );
    });

    group('permanentlyDelete', () {
      blocTest<TrashCubit, TrashState>(
        'calls repository.hardDelete',
        build: () {
          when(() => mockRepo.hardDelete(any()))
              .thenAnswer((_) async {});
          return TrashCubit(
            receiptRepository: mockRepo,
            userId: userId,
          );
        },
        act: (cubit) => cubit.permanentlyDelete('del-001'),
        verify: (_) {
          verify(() => mockRepo.hardDelete('del-001')).called(1);
        },
      );

      blocTest<TrashCubit, TrashState>(
        'when hardDelete throws emits error state',
        build: () {
          when(() => mockRepo.hardDelete(any()))
              .thenThrow(Exception('Delete failed'));
          return TrashCubit(
            receiptRepository: mockRepo,
            userId: userId,
          );
        },
        act: (cubit) => cubit.permanentlyDelete('del-001'),
        expect: () => [
          isA<TrashState>()
              .having((s) => s.error, 'error', isNotNull)
              .having(
                (s) => s.error,
                'error message',
                contains('Delete failed'),
              ),
        ],
      );
    });
  });
}
