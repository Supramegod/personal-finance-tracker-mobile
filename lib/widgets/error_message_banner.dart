/// Widget banner error — muncul di bagian atas layar.
///
/// Menampilkan pesan error dengan opsi "Coba Lagi" jika disediakan.
library;

import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';

class ErrorMessageBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessageBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      color: AppColors.error.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Coba Lagi', style: TextStyle(fontSize: 13)),
            ),
          ],
        ],
      ),
    );
  }
}
