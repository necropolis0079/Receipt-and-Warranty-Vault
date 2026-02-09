import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/features/receipt/domain/entities/receipt.dart';
import 'package:warrantyvault/features/receipt/domain/repositories/receipt_repository.dart';
import 'package:warrantyvault/features/search/domain/models/search_filters.dart';
import 'package:warrantyvault/features/search/presentation/bloc/search_bloc.dart';
import 'package:warrantyvault/features/search/presentation/bloc/search_event.dart';
import 'package:warrantyvault/features/search/presentation/bloc/search_state.dart';

class MockReceiptRepository extends Mock implements ReceiptRepository {}

void main() {
  late MockReceiptRepository mockRepository;
  const userId = 'user-1';

  final now = DateTime.now();
  final nowIso = now.toIso8601String();

  Receipt makeReceipt({
    String id = 'test-id',
    String storeName = 'Test Store',
    String? category,
    int warrantyMonths = 0,
  }) {
    return Receipt(
      receiptId: id,
      userId: userId,
      storeName: storeName,
      category: category,
      warrantyMonths: warrantyMonths,
      createdAt: nowIso,
      updatedAt: nowIso,
    );
  }

  setUp(() {
    mockRepository = MockReceiptRepository();
  });

  group('SearchBloc', () {
    // ---------------------------------------------------------------
    // Initial state
    // ---------------------------------------------------------------
    test('initial state is SearchInitial', () {
      final bloc = SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      );

      expect(bloc.state, const SearchInitial());

      bloc.close();
    });

    // ---------------------------------------------------------------
    // SearchQueryChanged — empty query
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchQueryChanged with empty query emits SearchInitial',
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) => bloc.add(const SearchQueryChanged('')),
      expect: () => [const SearchInitial()],
    );

    // ---------------------------------------------------------------
    // SearchQueryChanged — valid query with results
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchQueryChanged with valid query emits [SearchLoading, SearchLoaded]',
      setUp: () {
        when(() => mockRepository.search(userId, 'laptop'))
            .thenAnswer((_) async => [makeReceipt(id: 'r-1')]);
      },
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) => bloc.add(const SearchQueryChanged('laptop')),
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const SearchLoading(),
        isA<SearchLoaded>()
            .having((s) => s.results, 'results', hasLength(1))
            .having((s) => s.query, 'query', 'laptop'),
      ],
    );

    // ---------------------------------------------------------------
    // SearchQueryChanged — empty results
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchQueryChanged with query that returns empty results emits '
      '[SearchLoading, SearchEmpty]',
      setUp: () {
        when(() => mockRepository.search(userId, 'nonexistent'))
            .thenAnswer((_) async => []);
      },
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) => bloc.add(const SearchQueryChanged('nonexistent')),
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const SearchLoading(),
        const SearchEmpty('nonexistent'),
      ],
    );

    // ---------------------------------------------------------------
    // SearchQueryChanged — search throws
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchQueryChanged when search throws emits [SearchLoading, SearchError]',
      setUp: () {
        when(() => mockRepository.search(userId, 'crash'))
            .thenThrow(Exception('Database error'));
      },
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) => bloc.add(const SearchQueryChanged('crash')),
      wait: const Duration(milliseconds: 350),
      expect: () => [
        const SearchLoading(),
        isA<SearchError>()
            .having((s) => s.message, 'message', contains('Database error')),
      ],
    );

    // ---------------------------------------------------------------
    // SearchFilterChanged — re-runs search with filters
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchFilterChanged re-runs search with filters applied',
      setUp: () {
        when(() => mockRepository.search(userId, 'store'))
            .thenAnswer((_) async => [
                  makeReceipt(id: 'r-1', category: 'Electronics'),
                  makeReceipt(id: 'r-2', category: 'Groceries'),
                ]);
      },
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) async {
        // First: fire a query so _lastQuery is populated.
        bloc.add(const SearchQueryChanged('store'));
        await Future.delayed(const Duration(milliseconds: 350));

        // Then: apply a filter.
        bloc.add(const SearchFilterChanged(
          SearchFilters(category: 'Electronics'),
        ));
      },
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchLoading(),
        isA<SearchLoaded>().having((s) => s.results, 'results', hasLength(2)),
        // After filter change:
        const SearchLoading(),
        isA<SearchLoaded>()
            .having((s) => s.results, 'results', hasLength(1))
            .having(
                (s) => s.results.first.receiptId, 'filtered id', 'r-1'),
      ],
    );

    // ---------------------------------------------------------------
    // SearchFilterChanged — empty lastQuery does nothing
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchFilterChanged with empty lastQuery does nothing',
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) => bloc.add(const SearchFilterChanged(
        SearchFilters(category: 'Electronics'),
      )),
      wait: const Duration(milliseconds: 50),
      expect: () => <SearchState>[],
    );

    // ---------------------------------------------------------------
    // SearchCleared
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchCleared emits SearchInitial',
      setUp: () {
        when(() => mockRepository.search(userId, 'query'))
            .thenAnswer((_) async => [makeReceipt()]);
      },
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) async {
        // Populate state first so SearchCleared actually transitions.
        bloc.add(const SearchQueryChanged('query'));
        await Future.delayed(const Duration(milliseconds: 350));
        bloc.add(const SearchCleared());
      },
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchLoading(),
        isA<SearchLoaded>(),
        const SearchInitial(),
      ],
    );

    // ---------------------------------------------------------------
    // Debounce: rapid query changes only emit for the last query
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'debounce: rapid query changes only emit results for the last query',
      setUp: () {
        when(() => mockRepository.search(userId, 'l'))
            .thenAnswer((_) async => [makeReceipt(id: 'r-l')]);
        when(() => mockRepository.search(userId, 'la'))
            .thenAnswer((_) async => [makeReceipt(id: 'r-la')]);
        when(() => mockRepository.search(userId, 'lap'))
            .thenAnswer((_) async => [makeReceipt(id: 'r-lap')]);
        when(() => mockRepository.search(userId, 'lapt'))
            .thenAnswer((_) async => [makeReceipt(id: 'r-lapt')]);
        when(() => mockRepository.search(userId, 'lapto'))
            .thenAnswer((_) async => [makeReceipt(id: 'r-lapto')]);
        when(() => mockRepository.search(userId, 'laptop'))
            .thenAnswer((_) async => [makeReceipt(id: 'r-laptop')]);
      },
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) async {
        // Simulate rapid typing — each keystroke within the 300ms debounce window.
        bloc.add(const SearchQueryChanged('l'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const SearchQueryChanged('la'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const SearchQueryChanged('lap'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const SearchQueryChanged('lapt'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const SearchQueryChanged('lapto'));
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(const SearchQueryChanged('laptop'));
      },
      wait: const Duration(milliseconds: 500),
      expect: () => [
        const SearchLoading(),
        isA<SearchLoaded>()
            .having(
                (s) => s.results.first.receiptId, 'final id', 'r-laptop')
            .having((s) => s.query, 'query', 'laptop'),
      ],
      verify: (_) {
        // Only the final query should have been sent to the repository.
        verify(() => mockRepository.search(userId, 'laptop')).called(1);
        verifyNever(() => mockRepository.search(userId, 'l'));
        verifyNever(() => mockRepository.search(userId, 'la'));
        verifyNever(() => mockRepository.search(userId, 'lap'));
        verifyNever(() => mockRepository.search(userId, 'lapt'));
        verifyNever(() => mockRepository.search(userId, 'lapto'));
      },
    );

    // ---------------------------------------------------------------
    // SearchQueryChanged — whitespace-only query treated as empty
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchQueryChanged with whitespace-only query emits SearchInitial',
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) => bloc.add(const SearchQueryChanged('   ')),
      expect: () => [const SearchInitial()],
    );

    // ---------------------------------------------------------------
    // SearchFilterChanged — filters resulting in empty after server results
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchFilterChanged that filters out all results emits SearchEmpty',
      setUp: () {
        when(() => mockRepository.search(userId, 'item'))
            .thenAnswer((_) async => [
                  makeReceipt(id: 'r-1', category: 'Groceries'),
                ]);
      },
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) async {
        bloc.add(const SearchQueryChanged('item'));
        await Future.delayed(const Duration(milliseconds: 350));

        // Apply a filter that excludes all results.
        bloc.add(const SearchFilterChanged(
          SearchFilters(category: 'Electronics'),
        ));
      },
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchLoading(),
        isA<SearchLoaded>().having((s) => s.results, 'results', hasLength(1)),
        const SearchLoading(),
        const SearchEmpty('item'),
      ],
    );

    // ---------------------------------------------------------------
    // SearchFilterChanged — filter with hasWarranty
    // ---------------------------------------------------------------
    blocTest<SearchBloc, SearchState>(
      'SearchFilterChanged with hasWarranty filter returns only warranty receipts',
      setUp: () {
        when(() => mockRepository.search(userId, 'device'))
            .thenAnswer((_) async => [
                  makeReceipt(id: 'r-1', warrantyMonths: 24),
                  makeReceipt(id: 'r-2', warrantyMonths: 0),
                  makeReceipt(id: 'r-3', warrantyMonths: 12),
                ]);
      },
      build: () => SearchBloc(
        receiptRepository: mockRepository,
        userId: userId,
      ),
      act: (bloc) async {
        bloc.add(const SearchQueryChanged('device'));
        await Future.delayed(const Duration(milliseconds: 350));

        bloc.add(const SearchFilterChanged(
          SearchFilters(hasWarranty: true),
        ));
      },
      wait: const Duration(milliseconds: 400),
      expect: () => [
        const SearchLoading(),
        isA<SearchLoaded>().having((s) => s.results, 'results', hasLength(3)),
        const SearchLoading(),
        isA<SearchLoaded>()
            .having((s) => s.results, 'results', hasLength(2))
            .having(
              (s) => s.results.map((r) => r.receiptId).toList(),
              'receipt ids',
              containsAll(['r-1', 'r-3']),
            ),
      ],
    );
  });
}
