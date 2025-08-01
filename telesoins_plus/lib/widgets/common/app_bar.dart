import 'package:flutter/material.dart';
import 'package:telesoins_plus/config/theme.dart';

enum AppBarType { patient, medecin, common }

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final AppBarType type;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double elevation;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.type = AppBarType.common,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.elevation = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (type) {
      case AppBarType.patient:
        backgroundColor = AppTheme.primaryColor;
        textColor = Colors.white;
        break;
      case AppBarType.medecin:
        backgroundColor = AppTheme.medicalBlue;
        textColor = Colors.white;
        break;
      case AppBarType.common:
      default:
        backgroundColor = AppTheme.primaryColor;
        textColor = Colors.white;
    }

    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      leading: showBackButton && Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}