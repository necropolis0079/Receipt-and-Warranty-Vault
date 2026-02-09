import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/database/daos/categories_dao.dart';
import '../bloc/category_cubit.dart';
import '../bloc/category_state.dart';

/// Screen for managing receipt categories (add, delete, reorder, hide).
///
/// Receives a [CategoriesDao] directly so it can create its own
/// [CategoryManagementCubit] and remain independently navigable.
class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key, required this.categoriesDao});

  final CategoriesDao categoriesDao;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoryManagementCubit(categoriesDao: categoriesDao)
        ..loadAll(),
      child: const _CategoryManagementBody(),
    );
  }
}

class _CategoryManagementBody extends StatelessWidget {
  const _CategoryManagementBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: BlocBuilder<CategoryManagementCubit, CategoryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text(state.error!));
          }
          if (state.categories.isEmpty) {
            return const Center(child: Text('No categories'));
          }
          return ListView.builder(
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return ListTile(
                leading: category.icon != null
                    ? Text(category.icon!, style: const TextStyle(fontSize: 24))
                    : const Icon(Icons.category),
                title: Text(category.name),
                subtitle: category.isDefault
                    ? const Text('Default')
                    : null,
                trailing: category.isDefault
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          context
                              .read<CategoryManagementCubit>()
                              .deleteCategory(category.id);
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
