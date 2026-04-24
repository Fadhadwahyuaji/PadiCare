import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/blocs/prediction/prediction_bloc.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/blocs/prediction/prediction_event.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/blocs/prediction/prediction_state.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/prediction/analyze_button.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/prediction/chat_section.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/prediction/image_section.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/prediction/prediction_result_card.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/widgets/prediction/server_status_dialog.dart';

import '../logic/services/api_service.dart';
import 'history_screen.dart';

class PredictionChatScreen extends StatelessWidget {
  final String? historyItemId;
  final bool isHistoryMode;
  // final dynamic historyItem;

  const PredictionChatScreen({
    Key? key,
    this.historyItemId,
    this.isHistoryMode = false,
    // this.historyItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PredictionBloc()
        ..add(
          InitializePrediction(
            isHistoryMode: isHistoryMode,
            historyItemId: historyItemId,
          ),
        ),
      child: PredictionChatView(),
    );
  }
}

class PredictionChatView extends StatefulWidget {
  const PredictionChatView({Key? key}) : super(key: key);

  @override
  State<PredictionChatView> createState() => _PredictionChatViewState();
}

class _PredictionChatViewState extends State<PredictionChatView>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final ScrollController _mainScrollController = ScrollController();

  late AnimationController _chatAnimationController;
  late Animation<double> _chatAnimation;

  final Color primaryColor = Colors.green.shade700;
  final Color accentColor = Colors.green.shade300;
  final Color backgroundColor = Colors.grey.shade50;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _chatAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _chatAnimation = CurvedAnimation(
      parent: _chatAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    _mainScrollController.dispose();
    _chatAnimationController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mainScrollController.hasClients) {
        _mainScrollController.animateTo(
          _mainScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PredictionBloc, PredictionState>(
      listener: (context, state) {
        // Handle server status
        if (state.serverStatus == ServerStatus.offline) {
          ServerStatusDialog.showOfflineDialog(
            context,
            () => context.read<PredictionBloc>().add(CheckServerStatus()),
          );
        }

        // Handle errors
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Handle success
        // if (state.status == PredictionStatus.success && state.result != null) {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text('Analisis berhasil!'),
        //       backgroundColor: primaryColor,
        //       behavior: SnackBarBehavior.floating,
        //     ),
        //   );
        //   _scrollToResult();
        // }

        // Handle chat animations
        // if (state.isChatMinimized) {
        //   _chatAnimationController.reverse();
        // } else {
        //   _chatAnimationController.forward();
        //   _scrollToBottom();
        // }

        // Clear message controller after sending
        if (state.chatStatus == ChatStatus.sent) {
          _messageController.clear();
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        if (state.isHistoryMode && state.status == PredictionStatus.loading) {
          return Scaffold(
            appBar: _buildAppBar(context, state),
            backgroundColor: backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text(
                    'Memuat data riwayat...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          appBar: _buildAppBar(context, state),
          backgroundColor: backgroundColor,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _mainScrollController,
                      child: Column(
                        children: [
                          ImageSection(
                            isHistoryMode: state.isHistoryMode,
                            selectedImage:
                                state.selectedImage, // local image file
                            historyImageFilename:
                                state.historyItem?.imageFilename,
                            historyImageUrlFuture:
                                state.isHistoryMode && state.historyItem != null
                                ? Future.value(state.imageUrl)
                                : null,
                            historyDate: state.historyItem?.createdAt,
                            primaryColor: primaryColor,
                            accentColor: accentColor,
                            onCameraTap: () => context
                                .read<PredictionBloc>()
                                .add(PickImageFromCamera()),
                            onGalleryTap: () => context
                                .read<PredictionBloc>()
                                .add(PickImageFromGallery()),
                            onImageTap: state.isHistoryMode
                                ? () => _showFullScreenHistoryImage(
                                    context,
                                    state.imageUrl ?? '',
                                  )
                                : () => _showFullScreenImage(
                                    context,
                                    state.selectedImage,
                                  ),
                          ),
                          if (!state.isHistoryMode)
                            AnalyzeButton(
                              hasImage: state.selectedImage != null,
                              isLoading:
                                  state.status == PredictionStatus.loading,
                              onPressed: () => context
                                  .read<PredictionBloc>()
                                  .add(AnalyzeImage()),
                              primaryColor: primaryColor,
                            ),
                          if (state.result != null)
                            PredictionResultCard(
                              result: state.result!,
                              isHistoryMode: state.isHistoryMode,
                              primaryColor: primaryColor,
                              accentColor: accentColor,
                            ),
                          if (state.result != null && state.isChatMinimized)
                            SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                  if (state.result != null)
                    ChatSection(
                      animation: _chatAnimation,
                      isChatMinimized: state.isChatMinimized,
                      isHistoryMode: state.isHistoryMode,
                      messages: state.messages,
                      scrollController: _chatScrollController,
                      textController: _messageController,
                      isSending: state.chatStatus == ChatStatus.sending,
                      onToggleChat: () =>
                          context.read<PredictionBloc>().add(ToggleChat()),
                      onSendMessage: () {
                        final message = _messageController.text.trim();
                        if (message.isNotEmpty) {
                          context.read<PredictionBloc>().add(
                            SendChatMessage(message),
                          );
                        }
                      },
                      primaryColor: primaryColor,
                      accentColor: accentColor,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    PredictionState state,
  ) {
    return AppBar(
      backgroundColor: primaryColor,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            state.isHistoryMode ? 'Detail Riwayat' : 'Diagnosa & Konsultasi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          ServerStatusIndicator(
            isServerReachable: state.serverStatus == ServerStatus.online,
          ),
        ],
      ),
      centerTitle: true,
      elevation: 2,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      iconTheme: IconThemeData(color: Colors.white),
      actions: [
        if (state.serverStatus == ServerStatus.offline)
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () =>
                context.read<PredictionBloc>().add(CheckServerStatus()),
            tooltip: 'Periksa Koneksi Server',
          ),
        if (state.isHistoryMode) ...[
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () => _navigateToNewDiagnosis(context),
            tooltip: 'Diagnosa Baru',
          ),
          SizedBox(width: 8),
        ],
        if (!state.isHistoryMode) ...[
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => _navigateToHistory(context),
            tooltip: 'Lihat Riwayat',
          ),
        ],
      ],
    );
  }

  void _navigateToNewDiagnosis(BuildContext context) {
    if (context.read<PredictionBloc>().state.isHistoryMode) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PredictionChatScreen(isHistoryMode: false),
        ),
        (route) => route.isFirst,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PredictionChatScreen(isHistoryMode: false),
        ),
      );
    }
  }

  void _navigateToHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen()),
    );
  }

  void _showFullScreenImage(BuildContext context, dynamic selectedImage) {
    if (selectedImage == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(selectedImage),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullScreenHistoryImage(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;

    final fullImageUrl = '${ApiService.baseUrl}$imageUrl';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(fullImageUrl),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
