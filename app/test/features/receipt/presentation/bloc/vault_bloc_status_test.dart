import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/vault_bloc.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/vault_event.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/vault_state.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

class FakeReceipt extends Fake implements Receipt {}

void main() {
  late MockReceiptRepository mockRepo;

  final now = DateTime.now().toIso8601String();

  final activeReceipt = Receipt(
    receiptId: 'test-id',
    userId: 'user-1',
    storeName: 'Test Store',
    status: ReceiptStatus.active,
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(FakeReceipt());
  });

  setUp(() {
    mockRepo = MockReceiptRepository();
  });

  group('VaultBloc — VaultReceiptStatusChanged', () {
    blocTest<VaultBloc, VaultState>(
      'calls getById then updateReceipt with new status',
      build: () {
        when(() => mockRepo.getById('test-id'))
            .thenAnswer((_) async => activeReceipt);
        when(() => mockRepo.updateReceipt(any()))
            .thenAnswer((_) async {});
        return VaultBloc(receiptRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const VaultReceiptStatusChanged(
        receiptId: 'test-id',
        status: 'deleted',
      )),
      verify: (_) {
        verify(() => mockRepo.getById('test-id')).called(1);
        final captured =
            verify(() => mockRepo.updateReceipt(captureAny())).captured;
        expect(captured, hasLength(1));
        final updatedReceipt = captured.first as Receipt;
        expect(updatedReceipt.status, ReceiptStatus.deleted);
        expect(updatedReceipt.receiptId, 'test-id');
      },
    );

    blocTest<VaultBloc, VaultState>(
      'with non-existent receipt does nothing (no updateReceipt call)',
      build: () {
        when(() => mockRepo.getById('nonexistent'))
            .thenAnswer((_) async => null);
        return VaultBloc(receiptRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const VaultReceiptStatusChanged(
        receiptId: 'nonexistent',
        status: 'returned',
      )),
      expect: () => <VaultState>[],
      verify: (_) {
        verify(() => mockRepo.getById('nonexistent')).called(1);
        verifyNever(() => mockRepo.updateReceipt(any()));
      },
    );

    blocTest<VaultBloc, VaultState>(
      'when getById throws emits VaultError',
      build: () {
        when(() => mockRepo.getById('test-id'))
            .thenThrow(Exception('Database unavailable'));
        return VaultBloc(receiptRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const VaultReceiptStatusChanged(
        receiptId: 'test-id',
        status: 'returned',
      )),
      expect: () => [
        isA<VaultError>().having(
          (e) => e.message,
          'message',
          contains('Database unavailable'),
        ),
      ],
    );

    blocTest<VaultBloc, VaultState>(
      'sets status to returned correctly',
      build: () {
        when(() => mockRepo.getById('test-id'))
            .thenAnswer((_) async => activeReceipt);
        when(() => mockRepo.updateReceipt(any()))
            .thenAnswer((_) async {});
        return VaultBloc(receiptRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const VaultReceiptStatusChanged(
        receiptId: 'test-id',
        status: 'returned',
      )),
      verify: (_) {
        final captured =
            verify(() => mockRepo.updateReceipt(captureAny())).captured;
        expect(captured, hasLength(1));
        final updatedReceipt = captured.first as Receipt;
        expect(updatedReceipt.status, ReceiptStatus.returned);
        expect(updatedReceipt.storeName, 'Test Store');
        // updatedAt should be refreshed (different from original)
        expect(updatedReceipt.updatedAt, isNot(equals(now)));
      },
    );
  });
}
