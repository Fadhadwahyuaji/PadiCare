// ignore_for_file: avoid_print

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final ApiService _apiService;
  static const int _pageSize = 20;

  HistoryBloc({ApiService? apiService})
    : _apiService = apiService ?? ApiService(),
      super(const HistoryInitial()) {
    on<LoadHistory>(_onLoadHistory);
    on<LoadMoreHistory>(_onLoadMoreHistory);
    on<DeleteHistoryItem>(_onDeleteHistoryItem);
    on<ApplyFilterAndSort>(_onApplyFilterAndSort);
  }

  // LOAD INITIAL HISTORY
  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HistoryState> emit,
  ) async {
    print('🔄 BLoC: Loading history - refresh: ${event.refresh}');

    if (event.refresh || state is! HistoryLoaded) {
      emit(const HistoryLoading());
    } // MEMANCARKAN STATE LOADING JIKA REFRESH ATAU BELUM TERLOAD

    try {
      final response = await _apiService.getUserHistory(
        limit: _pageSize,
        offset: 0,
      ); // MEMANGGIL API UNTUK MENDAPATKAN DATA RIWAYAT

      if (response != null && response.success) {
        print(
          '✅ BLoC: History loaded - ${response.history.length} items',
        ); // CEK APAKAH DATA KOSONG ATAU TIDAK

        if (response.history.isEmpty) {
          emit(
            const HistoryEmpty(),
          ); // MEMANCARKAN STATE KOSONG JIKA TIDAK ADA DATA
        } else {
          emit(
            HistoryLoaded(
              historyItems: response.history,
              hasMoreData: response.pagination.hasMore,
              currentPage: 0,
            ), // MEMANCARKAN STATE DENGAN DATA YANG DIDAPATKAN
          );
        }
      } else {
        emit(const HistoryError('Gagal memuat riwayat'));
      }
    } catch (e) {
      print('❌ BLoC: Error loading history: $e');
      emit(HistoryError('Error: $e'));
    }
  }

  // LOAD MORE HISTORY (Pagination)
  Future<void> _onLoadMoreHistory(
    LoadMoreHistory event,
    Emitter<HistoryState> emit, //
  ) async {
    if (state is! HistoryLoaded) return;

    final currentState = state as HistoryLoaded; // MENYIMPAN STATE SAAT INI
    // CEK APAKAH MASIH ADA DATA LEBIH ATAU SEDANG MEMUAT
    if (!currentState.hasMoreData || currentState.isLoadingMore) return;

    print('📄 BLoC: Loading more history...');

    emit(
      currentState.copyWith(isLoadingMore: true),
    ); // MEMANCARKAN STATE DENGAN LOADING MORE

    try {
      final nextPage =
          currentState.currentPage + 1; // MENGHITUNG HALAMAN BERIKUTNYA
      final response = await _apiService.getUserHistory(
        limit: _pageSize,
        offset: nextPage * _pageSize,
      ); // MEMANGGIL API UNTUK MENDAPATKAN DATA LEBIH

      if (response != null && response.success) {
        print(
          '✅ BLoC: More history loaded - ${response.history.length} items',
        ); // MENAMBAHKAN DATA BARU KE DAFTAR YANG SUDAH ADA

        emit(
          currentState.copyWith(
            historyItems: [
              ...currentState.historyItems,
              ...response.history,
            ], // MENGGABUNGKAN DAFTAR
            hasMoreData:
                response.pagination.hasMore, // MEMPERBARUI STATUS HAS MORE
            isLoadingMore: false,
            currentPage: nextPage, // MEMPERBARUI HALAMAN SAAT INI
          ), // MEMANCARKAN STATE TERBARU
        );
      } else {
        emit(
          currentState.copyWith(isLoadingMore: false),
        ); // JIKA GAGAL, KEMBALIKAN KE STATE SEBELUMNYA
      }
    } catch (e) {
      print('❌ BLoC: Error loading more history: $e');
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  // DELETE HISTORY ITEM
  Future<void> _onDeleteHistoryItem(
    DeleteHistoryItem event,
    Emitter<HistoryState> emit,
  ) async {
    if (state is! HistoryLoaded) return; // MEMASTIKAN DATA SUDAH TERLOAD

    final currentState = state as HistoryLoaded; // MENYIMPAN STATE SAAT INI
    print('🗑️ BLoC: Deleting history item: ${event.predictionId}');

    try {
      final success = await _apiService.deleteHistoryItem(
        event.predictionId,
      ); // MEMANGGIL API UNTUK MENGHAPUS ITEM

      if (success) {
        final updatedItems = currentState.historyItems
            .where((item) => item.id != event.predictionId)
            .toList(); // MEMPERBARUI DAFTAR ITEM

        print('✅ BLoC: Item deleted successfully');

        if (updatedItems.isEmpty) {
          // JIKA TIDAK ADA ITEM TERSISA
          emit(const HistoryEmpty());
          emit(const HistoryDeleted('Riwayat berhasil dihapus'));
        } else {
          // JIKA MASIH ADA ITEM TERSISA
          emit(currentState.copyWith(historyItems: updatedItems)); //
          emit(const HistoryDeleted('Riwayat berhasil dihapus'));
        } // MEMANCARKAN STATE TERBARU
      } else {
        emit(const HistoryDeleteError('Gagal menghapus riwayat'));
        emit(currentState);
      }
    } catch (e) {
      print('❌ BLoC: Error deleting item: $e');
      emit(HistoryDeleteError('Error: $e'));
      emit(currentState);
    }
  }

  // APPLY FILTER AND SORT
  Future<void> _onApplyFilterAndSort(
    ApplyFilterAndSort event,
    Emitter<HistoryState> emit,
  ) async {
    if (state is! HistoryLoaded) return;

    final currentState = state as HistoryLoaded;
    print('🔍 BLoC: Applying filter: ${event.filter}, sort: ${event.sort}');

    emit(
      currentState.copyWith(
        selectedFilter: event.filter,
        selectedSort: event.sort,
      ),
    );
  }
}
