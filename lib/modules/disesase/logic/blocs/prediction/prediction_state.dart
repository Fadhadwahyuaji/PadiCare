import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/models/history_model.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/models/prediction_model.dart'
    show PredictionResult;

enum PredictionStatus { initial, loading, success, failure }

enum ChatStatus { initial, sending, sent, failure }

enum ServerStatus { checking, online, offline }

class PredictionState extends Equatable {
  final PredictionStatus status;
  final ChatStatus chatStatus;
  final ServerStatus serverStatus;
  final File? selectedImage;
  final PredictionResult? result;
  final List<ChatMessageItem> messages;
  final bool isChatMinimized;
  final bool isHistoryMode;
  final PredictionHistoryItem? historyItem;
  final String? errorMessage;
  final String? imageUrl;

  const PredictionState({
    this.status = PredictionStatus.initial,
    this.chatStatus = ChatStatus.initial,
    this.serverStatus = ServerStatus.checking,
    this.selectedImage,
    this.result,
    this.messages = const [],
    this.isChatMinimized = true,
    this.isHistoryMode = false,
    this.historyItem,
    this.errorMessage,
    this.imageUrl,
  });

  PredictionState copyWith({
    PredictionStatus? status,
    ChatStatus? chatStatus,
    ServerStatus? serverStatus,
    File? selectedImage,
    PredictionResult? result,
    List<ChatMessageItem>? messages,
    bool? isChatMinimized,
    bool? isHistoryMode,
    PredictionHistoryItem? historyItem,
    String? errorMessage,
    String? imageUrl,
    bool clearImage = false,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return PredictionState(
      status: status ?? this.status,
      chatStatus: chatStatus ?? this.chatStatus,
      serverStatus: serverStatus ?? this.serverStatus,
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      result: clearResult ? null : (result ?? this.result),
      messages: messages ?? this.messages,
      isChatMinimized: isChatMinimized ?? this.isChatMinimized,
      isHistoryMode: isHistoryMode ?? this.isHistoryMode,
      historyItem: historyItem ?? this.historyItem,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
    status,
    chatStatus,
    serverStatus,
    selectedImage,
    result,
    messages,
    isChatMinimized,
    isHistoryMode,
    historyItem,
    errorMessage,
    imageUrl,
  ];
}
