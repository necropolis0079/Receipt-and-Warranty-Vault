import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:warrantyvault/core/database/app_database.dart';
import 'package:warrantyvault/core/database/daos/categories_dao.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/category_cubit.dart';
import 'package:warrantyvault/features/receipt/presentation/bloc/category_state.dart';

class MockCategoriesDao extends Mock implements CategoriesDao {}

void main() {
  late MockCategoriesDao mockDao;

  final testEntries = [
    const CategoryEntry(
      id: 1,
      name: 'Electronics',
      icon: 'devices',
      isDefault: true,
      isHidden: false,
      sortOrder: 0,
    ),
    const CategoryEntry(
      id: 2,
      name: 'Groceries',
      icon: 'shopping_cart',
      isDefault: true,
      isHidden: false,
      sortOrder: 1,
    ),
  ];

  final expectedItems = [
    const CategoryItem(
      id: 1,
      name: 'Electronics',
      icon: 'devices',
      isDefault: true,
      isHidden: false,
      sortOrder: 0,
    ),
    const CategoryItem(
      id: 2,
      name: 'Groceries',
      icon: 'shopping_cart',
      isDefault: true,
      isHidden: false,
      sortOrder: 1,
    ),
  ];

  setUp(() {
    mockDao = MockCategoriesDao();
  });

  setUpAll(() {
    registerFallbackValue(CategoriesCompanion.insert(name: 'fallback'));
  });

  group('CategoryManagementCubit', () {
    test('initial state has empty categories, isLoading false', () {
      final cubit = CategoryManagementCubit(categoriesDao: mockDao);
      expect(cubit.state, CategoryState.initial());
      expect(cubit.state.categories, isEmpty);
      expect(cubit.state.isLoading, false);
      expect(cubit.state.error, isNull);
      cubit.close();
    });

    // --- loadAll ---
    blocTest<CategoryManagementCubit, CategoryState>(
      'loadAll emits loading then loaded with categories',
      build: () {
        when(() => mockDao.getAll()).thenAnswer((_) async => testEntries);
        return CategoryManagementCubit(categoriesDao: mockDao);
      },
      act: (cubit) => cubit.loadAll(),
      expect: () => [
        CategoryState.initial().copyWith(isLoading: true),
        CategoryState(
          categories: expectedItems,
          isLoading: false,
        ),
      ],
    );

    blocTest<CategoryManagementCubit, CategoryState>(
      'loadAll emits error on exception',
      build: () {
        when(() => mockDao.getAll()).thenThrow(Exception('DB error'));
        return CategoryManagementCubit(categoriesDao: mockDao);
      },
      act: (cubit) => cubit.loadAll(),
      expect: () => [
        CategoryState.initial().copyWith(isLoading: true),
        CategoryState.initial()
            .copyWith(isLoading: false, error: 'Exception: DB error'),
      ],
    );

    // --- addCategory ---
    blocTest<CategoryManagementCubit, CategoryState>(
      'addCategory calls insertCategory then reloads',
      build: () {
        when(() => mockDao.insertCategory(any())).thenAnswer((_) async => 3);
        when(() => mockDao.getAll()).thenAnswer((_) async => testEntries);
        return CategoryManagementCubit(categoriesDao: mockDao);
      },
      act: (cubit) => cubit.addCategory('Clothing'),
      verify: (_) {
        verify(() => mockDao.insertCategory(any())).called(1);
        verify(() => mockDao.getAll()).called(1);
      },
      expect: () => [
        // loadAll emits: loading, then loaded
        CategoryState.initial().copyWith(isLoading: true),
        CategoryState(
          categories: expectedItems,
          isLoading: false,
        ),
      ],
    );

    // --- deleteCategory ---
    blocTest<CategoryManagementCubit, CategoryState>(
      'deleteCategory calls deleteCategory then reloads',
      build: () {
        when(() => mockDao.deleteCategory(any())).thenAnswer((_) async {});
        when(() => mockDao.getAll()).thenAnswer((_) async => testEntries);
        return CategoryManagementCubit(categoriesDao: mockDao);
      },
      act: (cubit) => cubit.deleteCategory(2),
      verify: (_) {
        verify(() => mockDao.deleteCategory(2)).called(1);
        verify(() => mockDao.getAll()).called(1);
      },
      expect: () => [
        CategoryState.initial().copyWith(isLoading: true),
        CategoryState(
          categories: expectedItems,
          isLoading: false,
        ),
      ],
    );

    // --- toggleVisibility (visible -> hidden) ---
    blocTest<CategoryManagementCubit, CategoryState>(
      'toggleVisibility calls hide for visible category',
      build: () {
        when(() => mockDao.hide(any())).thenAnswer((_) async {});
        when(() => mockDao.getAll()).thenAnswer((_) async => testEntries);
        return CategoryManagementCubit(categoriesDao: mockDao);
      },
      seed: () => CategoryState(
        categories: expectedItems,
        isLoading: false,
      ),
      act: (cubit) => cubit.toggleVisibility(1),
      verify: (_) {
        verify(() => mockDao.hide(1)).called(1);
        verifyNever(() => mockDao.show(any()));
      },
    );

    // --- toggleVisibility (hidden -> visible) ---
    blocTest<CategoryManagementCubit, CategoryState>(
      'toggleVisibility calls show for hidden category',
      build: () {
        when(() => mockDao.show(any())).thenAnswer((_) async {});
        when(() => mockDao.getAll()).thenAnswer((_) async => testEntries);
        return CategoryManagementCubit(categoriesDao: mockDao);
      },
      seed: () => CategoryState(
        categories: [
          const CategoryItem(
            id: 1,
            name: 'Electronics',
            icon: 'devices',
            isDefault: true,
            isHidden: true, // Hidden
            sortOrder: 0,
          ),
        ],
        isLoading: false,
      ),
      act: (cubit) => cubit.toggleVisibility(1),
      verify: (_) {
        verify(() => mockDao.show(1)).called(1);
        verifyNever(() => mockDao.hide(any()));
      },
    );

    // --- reorder ---
    blocTest<CategoryManagementCubit, CategoryState>(
      'reorder calls reorder then reloads',
      build: () {
        when(() => mockDao.reorder(any(), any())).thenAnswer((_) async {});
        when(() => mockDao.getAll()).thenAnswer((_) async => testEntries);
        return CategoryManagementCubit(categoriesDao: mockDao);
      },
      act: (cubit) => cubit.reorder(1, 5),
      verify: (_) {
        verify(() => mockDao.reorder(1, 5)).called(1);
        verify(() => mockDao.getAll()).called(1);
      },
      expect: () => [
        CategoryState.initial().copyWith(isLoading: true),
        CategoryState(
          categories: expectedItems,
          isLoading: false,
        ),
      ],
    );
  });
}
