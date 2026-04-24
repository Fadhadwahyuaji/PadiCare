import 'package:flutter/material.dart';

class AnalyzeButton extends StatelessWidget {
  final bool hasImage;
  final bool isLoading;
  final VoidCallback onPressed;
  final Color primaryColor;

  const AnalyzeButton({
    Key? key,
    required this.hasImage,
    required this.isLoading,
    required this.onPressed,
    required this.primaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!hasImage) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: isLoading
                ? primaryColor.withOpacity(0.7)
                : primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
            disabledForegroundColor: Colors.grey[600],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: isLoading ? 0 : 2,
            minimumSize: Size(double.infinity, 48),
          ),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 200),
            child: isLoading
                ? Row(
                    key: ValueKey('loading'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Menganalisis...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: ValueKey('analyze'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.science_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Analisis Penyakit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
