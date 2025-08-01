import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool isFullScreen;
  final double size;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.isFullScreen = false,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loader = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            strokeWidth: 3,
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              message!,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );

    if (isFullScreen) {
      return Container(
        color: Colors.white.withOpacity(0.8),
        child: Center(child: loader),
      );
    }

    return Center(child: loader);
  }
}