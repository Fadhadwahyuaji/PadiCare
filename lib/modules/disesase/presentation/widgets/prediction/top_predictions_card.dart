import 'package:flutter/material.dart';
import 'package:klasifikasi_penyakit_padi/modules/disesase/logic/models/prediction_model.dart';

class TopPredictionsCard extends StatelessWidget {
  final List<TopPrediction> predictions;
  final bool isHistoryMode;
  final Color primaryColor;

  const TopPredictionsCard({
    Key? key,
    required this.predictions,
    required this.isHistoryMode,
    required this.primaryColor,
  }) : super(key: key);

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  isHistoryMode
                      ? 'Top 3 Hasil Diagnosa (Riwayat)'
                      : 'Top 3 Kemungkinan Penyakit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
              if (isHistoryMode)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${predictions.length}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          ...predictions.asMap().entries.map((entry) {
            int index = entry.key;
            TopPrediction prediction = entry.value;

            return Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: index == 0
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: index == 0
                      ? primaryColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: index == 0 ? primaryColor : Colors.grey[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      prediction.className,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: index == 0
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getConfidenceColor(
                        prediction.confidence,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${prediction.confidence.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getConfidenceColor(prediction.confidence),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
