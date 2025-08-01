import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final String? details;
  final IconData icon;
  final VoidCallback? onRetry;
  final bool isFullScreen;

  const ErrorDisplay({
    Key? key,
    required this.message,
    this.details,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.isFullScreen = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorWidget = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: AppTheme.errorColor,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        if (details != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              details!,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (onRetry != null)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ),
      ],
    );

    if (isFullScreen) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: errorWidget,
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: errorWidget,
      ),
    );
  }
}