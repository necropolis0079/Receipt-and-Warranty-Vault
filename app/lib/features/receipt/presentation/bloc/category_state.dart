import 'package:equatable/equatable.dart';

class CategoryItem extends Equatable {
  const CategoryItem({
    required this.id,
    required this.name,
    this.icon,
    required this.isDefault,
    required this.isHidden,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String? icon;
  final bool isDefault;
  final bool isHidden;
  final int sortOrder;

  @override
  List<Object?> get props => [id, name, icon, isDefault, isHidden, sortOrder];
}

class CategoryState extends Equatable {
  const CategoryState({
    required this.categories,
    required this.isLoading,
    this.error,
  });

  final List<CategoryItem> categories;
  final bool isLoading;
  final String? error;

  factory CategoryState.initial() => const CategoryState(
        categories: [],
        isLoading: false,
      );

  CategoryState copyWith({
    List<CategoryItem>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [categories, isLoading, error];
}
