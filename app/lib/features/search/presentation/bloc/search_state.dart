import 'package:equatable/equatable.dart';

import '../../../receipt/domain/entities/receipt.dart';
import '../../domain/models/search_filters.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  const SearchLoaded({
    required this.results,
    required this.query,
    this.filters = SearchFilters.empty,
  });

  final List<Receipt> results;
  final String query;
  final SearchFilters filters;

  @override
  List<Object?> get props => [results, query, filters];
}

class SearchEmpty extends SearchState {
  const SearchEmpty(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class SearchError extends SearchState {
  const SearchError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
