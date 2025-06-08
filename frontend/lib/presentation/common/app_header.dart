import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? titleColor;
  final Color? subtitleColor;
  final double? titleSize;
  final double? subtitleSize;
  final bool showDivider;
  final Widget? rightWidget;

  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.subtitleColor,
    this.titleSize,
    this.subtitleSize,
    this.showDivider = false,
    this.rightWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleSize ?? 24,
                      fontWeight: FontWeight.bold,
                      color: titleColor ?? AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: subtitleSize ?? 16,
                      color: subtitleColor ?? AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (rightWidget != null) rightWidget!,
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 16),
          Divider(
            color: AppTheme.dividerColor,
            thickness: 1,
          ),
        ],
      ],
    );
  }
}
