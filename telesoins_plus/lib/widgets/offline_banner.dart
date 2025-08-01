import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';

class OfflineBanner extends StatelessWidget {
  final VoidCallback? onReconnect;

  const OfflineBanner({Key? key, this.onReconnect}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppTheme.warningColor,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Vous êtes en mode hors-ligne. Certaines fonctionnalités peuvent être limitées.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          if (onReconnect != null)
            TextButton(
              onPressed: onReconnect,
              child: const Text(
                'Reconnecter',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}