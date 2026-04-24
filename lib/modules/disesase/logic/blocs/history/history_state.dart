import 'package:equatable/equatable.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/models/history_model.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<PredictionHistoryItem> historyItems;
  final bool hasMoreData;
  final bool isLoadingMore;
  final String selectedFilter;
  final String selectedSort;
  final int currentPage;

  const HistoryLoaded({
    required this.historyItems,
    required this.hasMoreData,
    this.isLoadingMore = false,
    this.selectedFilter = 'all',
    this.selectedSort = 'newest',
    this.currentPage = 0,
  });

  HistoryLoaded copyWith({
    List<PredictionHistoryItem>? historyItems,
    bool? hasMoreData,
    bool? isLoadingMore,
    String? selectedFilter,
    String? selectedSort,
    int? currentPage,
  }) {
    return HistoryLoaded(
      historyItems: historyItems ?? this.historyItems,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedSort: selectedSort ?? this.selectedSort,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  List<PredictionHistoryItem> get filteredHistory {
    List<PredictionHistoryItem> filtered;

    // Apply filter
    if (selectedFilter == 'all') {
      filtered = List.from(historyItems);
    } else if (selectedFilter == 'healthy') {
      filtered = historyItems
          .where((item) => item.diseaseCategory == 'Sehat')
          .toList();
    } else if (selectedFilter == 'disease') {
      filtered = historyItems
          .where((item) => item.diseaseCategory != 'Sehat')
          .toList();
    } else {
      filtered = List.from(historyItems);
    }

    // Apply sort
    if (selectedSort == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (selectedSort == 'oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (selectedSort == 'confidence') {
      filtered.sort(
        (a, b) => b.confidencePercentage.compareTo(a.confidencePercentage),
      );
    }

    return filtered;
  }

  @override
  List<Object?> get props => [
    historyItems,
    hasMoreData,
    isLoadingMore,
    selectedFilter,
    selectedSort,
    currentPage,
  ];
}

class HistoryEmpty extends HistoryState {
  const HistoryEmpty();
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class HistoryDeleted extends HistoryState {
  final String message;

  const HistoryDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

class HistoryDeleteError extends HistoryState {
  final String message;

  const HistoryDeleteError(this.message);

  @override
  List<Object?> get props => [message];
}
