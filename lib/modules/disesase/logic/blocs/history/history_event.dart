import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistory extends HistoryEvent {
  final bool refresh;

  const LoadHistory({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class LoadMoreHistory extends HistoryEvent {
  const LoadMoreHistory();
}

class DeleteHistoryItem extends HistoryEvent {
  final String predictionId;

  const DeleteHistoryItem(this.predictionId);

  @override
  List<Object?> get props => [predictionId];
}

class UpdateFilter extends HistoryEvent {
  final String filter;

  const UpdateFilter(this.filter);

  @override
  List<Object?> get props => [filter];
}

class UpdateSort extends HistoryEvent {
  final String sort;

  const UpdateSort(this.sort);

  @override
  List<Object?> get props => [sort];
}

class ApplyFilterAndSort extends HistoryEvent {
  final String filter;
  final String sort;

  const ApplyFilterAndSort({required this.filter, required this.sort});

  @override
  List<Object?> get props => [filter, sort];
}
