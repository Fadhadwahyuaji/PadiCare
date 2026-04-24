import 'package:flutter/material.dart';

class ServerStatusIndicator extends StatelessWidget {
  final bool isServerReachable;

  const ServerStatusIndicator({Key? key, required this.isServerReachable})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isServerReachable) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Server Offline',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ServerStatusDialog {
  static void showOfflineDialog(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud_off, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Server Tidak Tersedia'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tidak dapat terhubung ke server.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Silakan periksa:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            _buildCheckItem('Koneksi internet Anda'),
            _buildCheckItem('Status server'),
            _buildCheckItem('Firewall atau VPN'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            icon: Icon(Icons.refresh, size: 18),
            label: Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCheckItem(String text) {
    return Padding(
      padding: EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
