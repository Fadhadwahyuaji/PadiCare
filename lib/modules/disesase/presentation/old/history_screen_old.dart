// lib/modules/disesase/presentation/history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/presentation/prediction_chat_screen.dart';
import '../../logic/services/api_service.dart';
import '../../logic/models/history_model.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<PredictionHistoryItem> _historyItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMoreData = true;

  // Filter options
  String _selectedFilter = 'all'; // all, healthy, disease
  String _selectedSort = 'newest'; // newest, oldest, confidence

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final Color primaryColor = Colors.green.shade700;
  final Color accentColor = Colors.green.shade300;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Load initial data
    _loadHistory();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreHistory();
      }
    }
  }

  // Update method _loadHistory - simplified tanpa stats
  Future<void> _loadHistory({bool refresh = false}) async {
    print('🔄 Loading history - refresh: $refresh');

    if (refresh) {
      setState(() {
        _currentPage = 0;
        _historyItems.clear();
        _hasMoreData = true;
        _errorMessage = null;
      });
    }

    setState(() => _isLoading = true);

    try {
      print('📞 Calling API getUserHistory...');
      final response = await _apiService.getUserHistory(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      print('📦 API Response received: ${response != null}');
      if (response != null) {
        print('✅ Response success: ${response.success}');
        print('📊 History items count: ${response.history.length}');
      }

      if (response != null && response.success) {
        setState(() {
          if (refresh) {
            _historyItems = response.history;
          } else {
            _historyItems.addAll(response.history);
          }
          _hasMoreData = response.pagination.hasMore;
          _isLoading = false;
          _errorMessage = null;
        });

        print('✅ History loaded successfully: ${_historyItems.length} items');

        // Start animations
        _fadeController.forward();
        Future.delayed(Duration(milliseconds: 200), () {
          _slideController.forward();
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response == null
              ? 'Tidak dapat terhubung ke server'
              : 'Gagal memuat riwayat';
        });
        print('❌ History load failed: $_errorMessage');
      }
    } catch (e, stackTrace) {
      print('❌ History load exception: $e');
      print('📋 Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // FIX: Safe navigation tanpa stack buildup
  void _navigateToNewDiagnosis() {
    print('🆕 Navigating to new diagnosis from history screen...');

    try {
      // Method 1: Simple replacement (PALING AMAN)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PredictionChatScreen(isHistoryMode: false),
        ),
      );
    } catch (e) {
      print('❌ Navigation error: $e');
      // Fallback: just pop
      Navigator.pop(context);
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;
      final response = await _apiService.getUserHistory(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (response != null && response.success) {
        setState(() {
          _historyItems.addAll(response.history);
          _hasMoreData = response.pagination.hasMore;
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
          _currentPage--; // Rollback page increment
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--; // Rollback page increment
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Filter & Urutkan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...['all', 'healthy', 'disease'].map((filter) {
                    String label = filter == 'all'
                        ? 'Semua'
                        : filter == 'healthy'
                        ? 'Sehat'
                        : 'Penyakit';
                    return RadioListTile<String>(
                      title: Text(label),
                      value: filter,
                      groupValue: _selectedFilter,
                      onChanged: (value) {
                        setDialogState(() => _selectedFilter = value!);
                      },
                    );
                  }).toList(),

                  SizedBox(height: 16),
                  Text(
                    'Urutkan:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...['newest', 'oldest', 'confidence'].map((sort) {
                    String label = sort == 'newest'
                        ? 'Terbaru'
                        : sort == 'oldest'
                        ? 'Terlama'
                        : 'Confidence';
                    return RadioListTile<String>(
                      title: Text(label),
                      value: sort,
                      groupValue: _selectedSort,
                      onChanged: (value) {
                        setDialogState(() => _selectedSort = value!);
                      },
                    );
                  }).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Trigger rebuild with new filters
                    Navigator.pop(context);
                  },
                  child: Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Add method untuk delete history item
  Future<void> _deleteHistoryItem(PredictionHistoryItem item) async {
    try {
      print('🗑️ Deleting history item: ${item.id}');

      final success = await _apiService.deleteHistoryItem(item.id);

      if (success) {
        setState(() {
          _historyItems.removeWhere((historyItem) => historyItem.id == item.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Riwayat berhasil dihapus'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus riwayat'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error deleting history item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Update delete confirmation di history screen
  Future<void> _showDeleteConfirmation(PredictionHistoryItem item) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Konfirmasi Hapus'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Anda yakin ingin menghapus riwayat diagnosa ini?'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• Data diagnosa akan dihapus permanen',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                    Text(
                      '• Gambar yang terkait akan dihapus dari server',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                    Text(
                      '• Riwayat chat akan ikut terhapus',
                      style: TextStyle(fontSize: 12, color: Colors.red[700]),
                    ),
                    Text(
                      '• Aksi ini tidak dapat dibatalkan',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Hapus Permanen'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteHistoryItem(item);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Riwayat Diagnosa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter & Urutkan',
          ),

          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: _navigateToNewDiagnosis,
            tooltip: 'Diagnosa Baru',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadHistory(refresh: true),
        color: primaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _historyItems.isEmpty) {
      return _buildLoadingState();
    }

    if (_errorMessage != null && _historyItems.isEmpty) {
      return _buildErrorState();
    }

    if (_historyItems.isEmpty) {
      return _buildEmptyState();
    }

    return _buildHistoryList();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 16),
          Text(
            'Memuat riwayat...',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(
            'Gagal memuat riwayat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Terjadi kesalahan tidak dikenal',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadHistory(refresh: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Belum ada riwayat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Mulai diagnosa tanaman padi untuk melihat riwayat',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Mulai Diagnosa'),
          ),
        ],
      ),
    );
  }

  // Method to filter and sort history based on selected options
  List<PredictionHistoryItem> _getFilteredHistory() {
    // Step 1: Filter the history items based on _selectedFilter
    List<PredictionHistoryItem> filteredList = [];

    if (_selectedFilter == 'all') {
      filteredList = List.from(_historyItems);
    } else if (_selectedFilter == 'healthy') {
      filteredList = _historyItems
          .where((item) => item.diseaseCategory == 'Sehat')
          .toList();
    } else if (_selectedFilter == 'disease') {
      filteredList = _historyItems
          .where((item) => item.diseaseCategory != 'Sehat')
          .toList();
    } else {
      filteredList = List.from(_historyItems);
    }

    // Step 2: Sort the filtered items based on _selectedSort
    if (_selectedSort == 'newest') {
      filteredList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedSort == 'oldest') {
      filteredList.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_selectedSort == 'confidence') {
      filteredList.sort(
        (a, b) => b.confidencePercentage.compareTo(a.confidencePercentage),
      );
    }

    return filteredList;
  }

  Widget _buildHistoryList() {
    final filteredHistory = _getFilteredHistory();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          itemCount: filteredHistory.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == filteredHistory.length) {
              return _buildLoadingMoreIndicator();
            }

            final item = filteredHistory[index];
            return _buildHistoryCard(item, index);
          },
        ),
      ),
    );
  }

  Widget _buildHistoryCard(PredictionHistoryItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(item),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with date, confidence, and delete button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy, HH:mm').format(item.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.confidenceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.confidencePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: item.confidenceColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Delete button
                        InkWell(
                          onTap: () => _showDeleteConfirmation(item),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Disease prediction
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item.diseaseCategory == 'Sehat'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.diseaseCategory == 'Sehat'
                            ? Icons.eco
                            : Icons.warning,
                        color: item.diseaseCategory == 'Sehat'
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.predictedClass,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            item.diseaseCategory,
                            style: TextStyle(
                              fontSize: 12,
                              color: item.diseaseCategory == 'Sehat'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),

                // Chat messages count if any
                if (item.chatMessages.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat, size: 12, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          '${item.chatMessages.length} pesan',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Tap to view indicator
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Tap untuk melihat detail lengkap',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tambahkan method untuk navigation ke detail
  void _navigateToDetail(PredictionHistoryItem item) {
    print('🔍 Navigating to detail for item: ${item.id}');
    print(
      '📄 Item data: ${item.predictedClass} - ${item.confidencePercentage}%',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PredictionChatScreen(historyItem: item, isHistoryMode: true),
      ),
    ).then((_) {
      // Refresh history when returning from detail screen
      print('🔄 Returned from detail, refreshing history...');
      _loadHistory(refresh: true);
    });
  }

  // Tambahkan method helper untuk preview advice
  String _getAdvicePreview(String advice) {
    // Remove formatting dan ambil kalimat pertama yang bermakna
    String cleanAdvice = advice
        .replaceAll(RegExp(r'[🦠🏠💡👁️⚠️🔧💊🛡️🌾🚨]'), '')
        .replaceAll(RegExp(r'\d+\.'), '')
        .trim();

    List<String> sentences = cleanAdvice.split('\n');
    for (String sentence in sentences) {
      if (sentence.trim().isNotEmpty && sentence.length > 20) {
        return sentence.trim();
      }
    }

    return cleanAdvice.length > 100
        ? '${cleanAdvice.substring(0, 100)}...'
        : cleanAdvice;
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(color: primaryColor),
    );
  }
}
