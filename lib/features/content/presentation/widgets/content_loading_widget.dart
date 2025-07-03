import 'package:flutter/material.dart';
import 'package:qvise/core/theme/app_spacing.dart';
import 'package:qvise/core/theme/theme_extensions.dart';

class ContentLoadingWidget extends StatelessWidget {
  final String message;
  
  const ContentLoadingWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: context.primaryColor,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: context.textTheme.bodyLarge?.copyWith(
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}