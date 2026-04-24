import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/prediction_chat_screen.dart';
import '../logic/blocs/history/history_bloc.dart';
import '../logic/blocs/history/history_event.dart';
import '../logic/blocs/history/history_state.dart';
import '../logic/models/history_model.dart';
import '../logic/services/api_service.dart';
import 'widgets/history/history_card.dart';
import 'widgets/history/history_empty.dart';
import 'widgets/history/history_error.dart';
import 'widgets/history/history_filter.dart';
import 'widgets/history/history_loading.dart';
import 'widgets/history/delete_confirmation.dart';

class HistoryScreen extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();
  final Color primaryColor = Colors.green.shade700;

  HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HistoryBloc(apiService: ApiService())..add(const LoadHistory()),
      child: _HistoryScreenContent(
        scrollController: _scrollController,
        primaryColor: primaryColor,
      ),
    );
  }
}

class _HistoryScreenContent extends StatefulWidget {
  final ScrollController scrollController;
  final Color primaryColor;

  const _HistoryScreenContent({
    required this.scrollController,
    required this.primaryColor,
  });

  @override
  State<_HistoryScreenContent> createState() => _HistoryScreenContentState();
}

class _HistoryScreenContentState extends State<_HistoryScreenContent>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );
  }

  void _onScroll() {
    if (widget.scrollController.position.pixels >=
        widget.scrollController.position.maxScrollExtent - 200) {
      context.read<HistoryBloc>().add(const LoadMoreHistory());
    }
  }

  void _showFilterDialog(HistoryLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => HistoryFilterDialog(
        selectedFilter: state.selectedFilter,
        selectedSort: state.selectedSort,
        onApply: (filter, sort) {
          context.read<HistoryBloc>().add(
            ApplyFilterAndSort(filter: filter, sort: sort),
          );
        },
      ),
    );
  }

  void _navigateToNewDiagnosis() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PredictionChatScreen(isHistoryMode: false),
      ),
    );
  }

  void _showDeleteConfirmation(PredictionHistoryItem item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => DeleteConfirmationDialog(
        item: item,
        onConfirm: () {
          context.read<HistoryBloc>().add(DeleteHistoryItem(item.id));
        },
      ),
    );
  }

  void _navigateToDetail(PredictionHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PredictionChatScreen(historyItemId: item.id, isHistoryMode: true),
      ),
    ).then((_) {
      context.read<HistoryBloc>().add(const LoadHistory(refresh: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listener: (context, state) {
          if (state is HistoryLoaded) {
            _fadeController.forward();
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) _slideController.forward();
            });
          } else if (state is HistoryDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: widget.primaryColor,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is HistoryDeleteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<HistoryBloc>().add(const LoadHistory(refresh: true));
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: widget.primaryColor,
            child: _buildBody(state),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: widget.primaryColor,
      title: const Text(
        'Riwayat Diagnosa',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            return IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: state is HistoryLoaded
                  ? () => _showFilterDialog(state)
                  : null,
              tooltip: 'Filter & Urutkan',
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: _navigateToNewDiagnosis,
          tooltip: 'Diagnosa Baru',
        ),
      ],
    );
  }

  Widget _buildBody(HistoryState state) {
    if (state is HistoryLoading) {
      return HistoryLoadingState(primaryColor: widget.primaryColor);
    }

    if (state is HistoryError) {
      return HistoryErrorState(
        errorMessage: state.message,
        onRetry: () {
          context.read<HistoryBloc>().add(const LoadHistory(refresh: true));
        },
        primaryColor: widget.primaryColor,
      );
    }

    if (state is HistoryEmpty) {
      return HistoryEmptyState(
        onStartDiagnosis: () => Navigator.pop(context),
        primaryColor: widget.primaryColor,
      );
    }

    if (state is HistoryLoaded) {
      return _buildHistoryList(state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildHistoryList(HistoryLoaded state) {
    final filteredHistory = state.filteredHistory;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: filteredHistory.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredHistory.length) {
              return Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: CircularProgressIndicator(color: widget.primaryColor),
              );
            }

            final item = filteredHistory[index];
            return HistoryCard(
              item: item,
              index: index,
              onTap: () => _navigateToDetail(item),
              onDelete: () => _showDeleteConfirmation(item),
            );
          },
        ),
      ),
    );
  }
}
