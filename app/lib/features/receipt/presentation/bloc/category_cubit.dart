import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/categories_dao.dart';
import 'category_state.dart';

class CategoryManagementCubit extends Cubit<CategoryState> {
  CategoryManagementCubit({required CategoriesDao categoriesDao})
      : _categoriesDao = categoriesDao,
        super(CategoryState.initial());

  final CategoriesDao _categoriesDao;

  /// Load all categories (including hidden).
  Future<void> loadAll() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final entries = await _categoriesDao.getAll();
      final items = entries
          .map((e) => CategoryItem(
                id: e.id,
                name: e.name,
                icon: e.icon,
                isDefault: e.isDefault,
                isHidden: e.isHidden,
                sortOrder: e.sortOrder,
              ))
          .toList();
      emit(state.copyWith(categories: items, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  /// Add a new custom category.
  Future<void> addCategory(String name, {String? icon}) async {
    try {
      final nextSort = state.categories.isEmpty
          ? 0
          : state.categories
                  .map((c) => c.sortOrder)
                  .reduce((a, b) => a > b ? a : b) +
              1;
      await _categoriesDao.insertCategory(CategoriesCompanion.insert(
        name: name,
        icon: icon != null ? Value(icon) : const Value.absent(),
        isDefault: const Value(false),
        sortOrder: Value(nextSort),
      ));
      await loadAll();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Delete a custom category. Default categories cannot be deleted.
  Future<void> deleteCategory(int id) async {
    try {
      await _categoriesDao.deleteCategory(id);
      await loadAll();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Toggle visibility of a category.
  Future<void> toggleVisibility(int id) async {
    try {
      final category = state.categories.firstWhere((c) => c.id == id);
      if (category.isHidden) {
        await _categoriesDao.show(id);
      } else {
        await _categoriesDao.hide(id);
      }
      await loadAll();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Reorder a category to a new position.
  Future<void> reorder(int id, int newSortOrder) async {
    try {
      await _categoriesDao.reorder(id, newSortOrder);
      await loadAll();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
