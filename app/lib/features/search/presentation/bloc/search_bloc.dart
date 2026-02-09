import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../receipt/domain/repositories/receipt_repository.dart';
import '../../domain/models/search_filters.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required ReceiptRepository receiptRepository,
    required String userId,
  })  : _receiptRepository = receiptRepository,
        _userId = userId,
        super(const SearchInitial()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchFilterChanged>(_onFilterChanged);
    on<SearchCleared>(_onCleared);
  }

  final ReceiptRepository _receiptRepository;
  final String _userId;
  Timer? _debounceTimer;
  String _lastQuery = '';
  SearchFilters _currentFilters = SearchFilters.empty;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    _lastQuery = event.query;
    if (event.query.trim().isEmpty) {
      _debounceTimer?.cancel();
      emit(const SearchInitial());
      return;
    }

    // Cancel previous debounce timer.
    _debounceTimer?.cancel();

    // Wait for debounce period before executing search.
    final completer = Completer<void>();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      completer.complete();
    });

    try {
      await completer.future;
    } catch (_) {
      return;
    }

    // If the query changed during the debounce window, skip this execution.
    if (_lastQuery != event.query) return;

    emit(const SearchLoading());
    try {
      final results = await _receiptRepository.search(_userId, event.query);
      final filtered = _currentFilters.applyTo(results);
      if (filtered.isEmpty) {
        emit(SearchEmpty(event.query));
      } else {
        emit(SearchLoaded(
          results: filtered,
          query: event.query,
          filters: _currentFilters,
        ));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    SearchFilterChanged event,
    Emitter<SearchState> emit,
  ) async {
    _currentFilters = event.filters;
    if (_lastQuery.trim().isEmpty) return;

    emit(const SearchLoading());
    try {
      final results = await _receiptRepository.search(_userId, _lastQuery);
      final filtered = _currentFilters.applyTo(results);
      if (filtered.isEmpty) {
        emit(SearchEmpty(_lastQuery));
      } else {
        emit(SearchLoaded(
          results: filtered,
          query: _lastQuery,
          filters: _currentFilters,
        ));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _lastQuery = '';
    _currentFilters = SearchFilters.empty;
    _debounceTimer?.cancel();
    emit(const SearchInitial());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
