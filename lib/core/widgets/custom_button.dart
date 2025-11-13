import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? color;
  final bool isActive;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      elevation: 8,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: AppConstants.buttonSize,
          height: AppConstants.buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
                ? (color ?? theme.colorScheme.primary)
                : theme.colorScheme.surface,
            border: Border.all(
              color: color ?? theme.colorScheme.primary,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: AppConstants.iconSize,
            color: isActive 
                ? theme.colorScheme.onPrimary
                : (color ?? theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

