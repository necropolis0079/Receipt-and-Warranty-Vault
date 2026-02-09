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

  final testReceipt = Receipt(
    receiptId: 'r-001',
    userId: 'user-1',
    storeName: 'Test Store',
    status: ReceiptStatus.active,
    isFavorite: false,
    createdAt: now,
    updatedAt: now,
  );

  final testReceipt2 = Receipt(
    receiptId: 'r-002',
    userId: 'user-1',
    storeName: 'Another Store',
    status: ReceiptStatus.active,
    isFavorite: true,
    createdAt: now,
    updatedAt: now,
  );

  final returnedReceipt = Receipt(
    receiptId: 'r-003',
    userId: 'user-1',
    storeName: 'Returned Store',
    status: ReceiptStatus.returned,
    isFavorite: false,
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() {
    registerFallbackValue(FakeReceipt());
  });

  setUp(() {
    mockRepo = MockReceiptRepository();
  });

  group('VaultBloc', () {
    test('initial state is VaultInitial', () {
      final bloc = VaultBloc(receiptRepository: mockRepo);
      expect(bloc.state, const VaultInitial());
      bloc.close();
    });

    // --- VaultLoadRequested ---
    group('VaultLoadRequested', () {
      blocTest<VaultBloc, VaultState>(
        'emits [Loading, Loaded] with receipts',
        build: () {
          when(() => mockRepo.watchUserReceipts(any()))
              .thenAnswer((_) => Stream.value([testReceipt, testReceipt2]));
          return VaultBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const VaultLoadRequested('user-1')),
        expect: () => [
          const VaultLoading(),
          VaultLoaded(
            receipts: [testReceipt, testReceipt2],
            activeCount: 2,
          ),
        ],
      );

      blocTest<VaultBloc, VaultState>(
        'emits [Loading, Empty] when no receipts',
        build: () {
          when(() => mockRepo.watchUserReceipts(any()))
              .thenAnswer((_) => Stream.value([]));
          return VaultBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const VaultLoadRequested('user-1')),
        expect: () => [
          const VaultLoading(),
          const VaultEmpty(),
        ],
      );

      blocTest<VaultBloc, VaultState>(
        'emits [Loading, Error] on stream error',
        build: () {
          when(() => mockRepo.watchUserReceipts(any()))
              .thenAnswer((_) => Stream.error(Exception('DB failure')));
          return VaultBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const VaultLoadRequested('user-1')),
        expect: () => [
          const VaultLoading(),
          isA<VaultError>(),
        ],
      );

      blocTest<VaultBloc, VaultState>(
        'emits [Loading, Error] when watchUserReceipts throws',
        build: () {
          when(() => mockRepo.watchUserReceipts(any()))
              .thenThrow(Exception('Connection error'));
          return VaultBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const VaultLoadRequested('user-1')),
        expect: () => [
          const VaultLoading(),
          isA<VaultError>(),
        ],
      );

      blocTest<VaultBloc, VaultState>(
        'activeCount only counts active receipts',
        build: () {
          when(() => mockRepo.watchUserReceipts(any())).thenAnswer(
            (_) => Stream.value([testReceipt, returnedReceipt]),
          );
          return VaultBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const VaultLoadRequested('user-1')),
        expect: () => [
          const VaultLoading(),
          VaultLoaded(
            receipts: [testReceipt, returnedReceipt],
            activeCount: 1,
          ),
        ],
      );

      blocTest<VaultBloc, VaultState>(
        'stream updates cause new VaultLoaded emissions',
        build: () {
          when(() => mockRepo.watchUserReceipts(any())).thenAnswer(
            (_) => Stream.fromIterable([
              [testReceipt],
              [testReceipt, testReceipt2],
            ]),
          );
          return VaultBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const VaultLoadRequested('user-1')),
        expect: () => [
          const VaultLoading(),
          VaultLoaded(receipts: [testReceipt], activeCount: 1),
          VaultLoaded(
            receipts: [testReceipt, testReceipt2],
            activeCount: 2,
          ),
        ],
      );
    });

    // --- VaultReceiptDeleted ---
    group('VaultReceiptDeleted', () {
      blocTest<VaultBloc, VaultState>(
        'calls repository.softDelete',
        build: () {
          when(() => mockRepo.softDelete(any()))
              .thenAnswer((_) async {});
          return VaultBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const VaultReceiptDeleted('r-001')),
        verify: (_) {
          verify(() => mockRepo.softDelete('r-001')).called(1);
        },
      );
    });

    // --- VaultReceiptFavoriteToggled ---
    group('VaultReceiptFavoriteToggled', () {
      blocTest<VaultBloc, VaultState>(
        'calls repository.updateReceipt to toggle favorite',
        build: () {
          when(() => mockRepo.getById(any()))
              .thenAnswer((_) async => testReceipt);
          when(() => mockRepo.updateReceipt(any()))
              .thenAnswer((_) async {});
          return VaultBloc(receiptRepository: mockRepo);
        },
        act: (bloc) => bloc.add(const VaultReceiptFavoriteToggled(
          receiptId: 'r-001',
          isFavorite: true,
        )),
        verify: (_) {
          verify(() => mockRepo.getById('r-001')).called(1);
          verify(() => mockRepo.updateReceipt(any())).called(1);
        },
      );
    });
  });
}
