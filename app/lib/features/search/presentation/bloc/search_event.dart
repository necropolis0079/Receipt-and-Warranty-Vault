import 'package:equatable/equatable.dart';

import '../../domain/models/search_filters.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class SearchFilterChanged extends SearchEvent {
  const SearchFilterChanged(this.filters);

  final SearchFilters filters;

  @override
  List<Object?> get props => [filters];
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}
