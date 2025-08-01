
import 'package:flutter/material.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onRetry;

  const OfflineBanner({
    Key? key,
    required this.isOffline,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return SizedBox.shrink();

    return Container(
      color: Colors.red.shade700,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.white,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vous êtes hors ligne. Certaines fonctionnalités peuvent être limitées.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade800,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }
}
