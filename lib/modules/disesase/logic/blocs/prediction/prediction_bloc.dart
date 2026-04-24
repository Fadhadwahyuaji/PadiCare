import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/models/history_model.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/models/prediction_model.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/services/api_service.dart';
import 'prediction_event.dart';
import 'prediction_state.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  final ApiService _apiService;
  final ImagePicker _picker;

  PredictionBloc({ApiService? apiService, ImagePicker? picker})
    : _apiService = apiService ?? ApiService(),
      _picker = picker ?? ImagePicker(),
      super(const PredictionState()) {
    on<InitializePrediction>(_onInitialize);
    on<CheckServerStatus>(_onCheckServerStatus);
    on<PickImageFromCamera>(_onPickImageFromCamera);
    on<PickImageFromGallery>(_onPickImageFromGallery);
    on<AnalyzeImage>(_onAnalyzeImage);
    on<SendChatMessage>(_onSendChatMessage);
    on<ToggleChat>(_onToggleChat);
    on<LoadHistoryData>(_onLoadHistoryData);
    on<ClearPrediction>(_onClearPrediction);
  }

  Future<void> _onInitialize(
    InitializePrediction event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      await _apiService.initializeSession();

      emit(
        state.copyWith(
          isHistoryMode: event.isHistoryMode,
          serverStatus: ServerStatus.checking,
        ),
      );

      // Check server status first
      add(CheckServerStatus());

      // Load history data if in history mode
      if (event.isHistoryMode && event.historyItemId != null) {
        add(LoadHistoryData(event.historyItemId!));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PredictionStatus.failure,
          errorMessage: 'Gagal menginisialisasi: $e',
        ),
      );
    }
  }

  Future<void> _onCheckServerStatus(
    CheckServerStatus event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      emit(state.copyWith(serverStatus: ServerStatus.checking));

      final isReachable = await _apiService.checkServerStatus();

      emit(
        state.copyWith(
          serverStatus: isReachable
              ? ServerStatus.online
              : ServerStatus.offline,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          serverStatus: ServerStatus.offline,
          errorMessage: 'Gagal memeriksa status server',
        ),
      );
    }
  }

  Future<void> _onPickImageFromCamera(
    PickImageFromCamera event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        emit(
          state.copyWith(
            selectedImage: File(pickedFile.path),
            clearResult: true,
            messages: [],
            isChatMinimized: true,
            clearError: true,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PredictionStatus.failure,
          errorMessage: 'Gagal mengambil gambar dari kamera: $e',
        ),
      );
    }
  }

  Future<void> _onPickImageFromGallery(
    PickImageFromGallery event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        emit(
          state.copyWith(
            selectedImage: File(pickedFile.path),
            clearResult: true,
            messages: [],
            isChatMinimized: true,
            clearError: true,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PredictionStatus.failure,
          errorMessage: 'Gagal mengambil gambar dari galeri: $e',
        ),
      );
    }
  }

  Future<void> _onAnalyzeImage(
    AnalyzeImage event,
    Emitter<PredictionState> emit,
  ) async {
    if (state.selectedImage == null) {
      emit(
        state.copyWith(
          status: PredictionStatus.failure,
          errorMessage: 'Silakan pilih gambar terlebih dahulu',
        ),
      );
      return;
    }

    try {
      emit(state.copyWith(status: PredictionStatus.loading, clearError: true));

      final result = await _apiService.predictImage(state.selectedImage!);

      if (result != null) {
        emit(state.copyWith(status: PredictionStatus.success, result: result));
      } else {
        emit(
          state.copyWith(
            status: PredictionStatus.failure,
            errorMessage: 'Gagal menganalisis gambar',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PredictionStatus.failure,
          errorMessage: 'Gagal menganalisis gambar: $e',
        ),
      );
    }
  }

  Future<void> _onSendChatMessage(
    SendChatMessage event,
    Emitter<PredictionState> emit,
  ) async {
    if (event.message.trim().isEmpty || state.result == null) {
      return;
    }

    try {
      final userMessage = ChatMessageItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: event.message,
        isUser: true,
        createdAt: DateTime.now(),
      );

      final updatedMessages = List<ChatMessageItem>.from(state.messages)
        ..add(userMessage);

      emit(
        state.copyWith(
          chatStatus: ChatStatus.sending,
          messages: updatedMessages,
        ),
      );

      final response = await _apiService.chatWithExpert(
        event.message,
        state.result!.predictedClass,
        predictionId: state.result!.predictionId,
      );

      if (response != null) {
        final aiMessage = ChatMessageItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: response.answer,
          isUser: false,
          createdAt: DateTime.now(),
        );

        final finalMessages = List<ChatMessageItem>.from(updatedMessages)
          ..add(aiMessage);

        emit(
          state.copyWith(chatStatus: ChatStatus.sent, messages: finalMessages),
        );
      } else {
        emit(
          state.copyWith(
            chatStatus: ChatStatus.failure,
            errorMessage: 'Gagal mendapat respon dari server',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          chatStatus: ChatStatus.failure,
          errorMessage: 'Gagal mengirim pesan: $e',
        ),
      );
    }
  }

  Future<void> _onToggleChat(
    ToggleChat event,
    Emitter<PredictionState> emit,
  ) async {
    emit(state.copyWith(isChatMinimized: !state.isChatMinimized));
  }

  Future<void> _onLoadHistoryData(
    LoadHistoryData event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: PredictionStatus.loading));

      // Load history from API
      final historyResponse = await _apiService.getUserHistory(limit: 100);

      if (historyResponse != null && historyResponse.history.isNotEmpty) {
        final historyItem = historyResponse.history.firstWhere(
          (item) => item.id == event.predictionId,
          orElse: () => throw Exception('History item tidak ditemukan'),
        );

        // Get image URL
        final imageUrl = await _apiService.getImageUrl(event.predictionId);

        emit(
          state.copyWith(
            status: PredictionStatus.success,
            historyItem: historyItem,
            result: historyItem.toPredictionResult(),
            messages: historyItem.chatMessages ?? [],
            isChatMinimized: historyItem.chatMessages?.isEmpty ?? true,
            imageUrl: imageUrl,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: PredictionStatus.failure,
            errorMessage: 'Data riwayat tidak ditemukan',
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PredictionStatus.failure,
          errorMessage: 'Gagal memuat riwayat: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onClearPrediction(
    ClearPrediction event,
    Emitter<PredictionState> emit,
  ) async {
    emit(const PredictionState());
  }
}

// Extension untuk convert history item ke prediction result
extension PredictionHistoryItemExtension on PredictionHistoryItem {
  PredictionResult toPredictionResult() {
    return PredictionResult(
      predictedClass: predictedClass,
      confidencePercentage: confidencePercentage,
      success: true,
      expertAdvice: expertAdvice,
      predictionId: id,
      topPredictions: topPredictions,
      processingTime: processingTime,
      savedToDatabase: true,
    );
  }
}
