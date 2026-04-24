import 'package:flutter/material.dart';

class ExpertAdviceCard extends StatelessWidget {
  final String advice;
  final Color primaryColor;
  final Color accentColor;

  const ExpertAdviceCard({
    Key? key,
    required this.advice,
    required this.primaryColor,
    required this.accentColor,
  }) : super(key: key);

  Widget _buildFormattedExpertAdvice(String advice) {
    List<Widget> widgets = [];
    List<String> lines = advice.split('\n');

    for (String line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: 8));
        continue;
      }

      Widget textWidget;

      if (RegExp(r'^[🦠🏠💡👁️⚠️🔧💊🛡️🌾🚨].*:$').hasMatch(line.trim())) {
        textWidget = Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border(left: BorderSide(width: 4, color: primaryColor)),
          ),
          child: Text(
            line.trim(),
            style: TextStyle(
              color: primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        );
      } else if (RegExp(r'^\d+\.').hasMatch(line.trim())) {
        textWidget = Container(
          padding: EdgeInsets.only(left: 16, right: 8, top: 2, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: EdgeInsets.only(top: 6, right: 8),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  line.trim().replaceFirst(RegExp(r'^\d+\.\s*'), ''),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      } else if (RegExp(r'^[📉⏱️🏪📖🕐💰]').hasMatch(line.trim())) {
        textWidget = Container(
          padding: EdgeInsets.only(left: 16, right: 8, top: 2, bottom: 2),
          child: Text(
            line.trim(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      } else {
        textWidget = Container(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            line.trim(),
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        );
      }

      widgets.add(textWidget);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Saran Ahli Penyuluhan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildFormattedExpertAdvice(advice),
        ],
      ),
    );
  }
}
