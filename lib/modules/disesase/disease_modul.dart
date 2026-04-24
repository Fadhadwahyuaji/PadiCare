import 'package:flutter_modular/flutter_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'logic/services/api_service.dart';
import 'logic/controllers/prediction_controller.dart';
import 'logic/controllers/chat_controller.dart';
import 'presentation/prediction_chat_screen.dart';
import 'presentation/history_screen.dart';

class DiseaseModule extends Module {
  static const String homeRoute = '/';
  static const String predictionRoute = '/prediction';
  static const String historyRoute = '/history';
  static const String predictionChatRoute = '/prediction-chat';

  @override
  List<Bind> get binds => [
    // Services
    Bind.lazySingleton((i) => ApiService()),

    // Controllers
    Bind.lazySingleton((i) => PredictionController()),
    Bind.lazySingleton((i) => ChatController()),

    // External dependencies
    Bind.lazySingleton((i) => ImagePicker()),
  ];

  @override
  List<ModularRoute> get routes => [
    // Main screen adalah prediction chat screen
    ChildRoute(homeRoute, child: (_, __) => const PredictionChatScreen()),

    // Route untuk history
    ChildRoute(historyRoute, child: (_, __) => HistoryScreen()),

    // Route untuk prediction chat (dengan parameter)
    ChildRoute(
      predictionChatRoute,
      child: (_, args) => PredictionChatScreen(
        historyItemId: args.data?['historyItem'],
        isHistoryMode: args.data?['isHistoryMode'] ?? false,
      ),
    ),
  ];
}
