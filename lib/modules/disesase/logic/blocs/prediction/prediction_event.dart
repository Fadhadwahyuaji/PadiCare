import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object?> get props => [];
}

class InitializePrediction extends PredictionEvent {
  final bool isHistoryMode;
  final String? historyItemId;

  const InitializePrediction({this.isHistoryMode = false, this.historyItemId});

  @override
  List<Object?> get props => [isHistoryMode, historyItemId];
}

class CheckServerStatus extends PredictionEvent {}

class PickImageFromCamera extends PredictionEvent {}

class PickImageFromGallery extends PredictionEvent {}

class AnalyzeImage extends PredictionEvent {}

class SendChatMessage extends PredictionEvent {
  final String message;

  const SendChatMessage(this.message);

  @override
  List<Object> get props => [message];
}

class ToggleChat extends PredictionEvent {}

class LoadHistoryData extends PredictionEvent {
  final String predictionId;

  const LoadHistoryData(this.predictionId);

  @override
  List<Object> get props => [predictionId];
}

class ClearPrediction extends PredictionEvent {}
