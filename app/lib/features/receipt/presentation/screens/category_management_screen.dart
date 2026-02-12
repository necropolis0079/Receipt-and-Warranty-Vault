import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

  void _showAddCategoryDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addCategory),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.categoryName,
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context
                    .read<CategoryManagementCubit>()
                    .addCategory(name);
                Navigator.of(dialogContext).pop();
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCategories),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        child: const Icon(Icons.add),
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
            return Center(child: Text(l10n.noCategories));
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
                    ? Text(l10n.defaultCategory)
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
