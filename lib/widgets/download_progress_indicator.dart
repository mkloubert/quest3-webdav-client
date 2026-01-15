// quest3_webdav_client - A WebDAV client optimized for Meta Quest 3.
// Copyright (C) 2026  Marcel Joachim Kloubert <marcel@kloubert.dev>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';

import '../constants/app_theme.dart';

/// A circular progress indicator showing download progress.
///
/// Displays a circular progress ring with percentage text
/// and an optional cancel button.
class DownloadProgressIndicator extends StatelessWidget {
  /// Download progress from 0.0 to 1.0.
  final double progress;

  /// Size of the indicator.
  final double size;

  /// Callback when cancel is pressed.
  final VoidCallback? onCancel;

  /// Whether to show the percentage text.
  final bool showPercentage;

  /// Stroke width of the progress ring.
  final double strokeWidth;

  /// Color of the progress ring.
  final Color? color;

  /// Background color of the progress ring.
  final Color? backgroundColor;

  const DownloadProgressIndicator({
    super.key,
    required this.progress,
    this.size = 48.0,
    this.onCancel,
    this.showPercentage = true,
    this.strokeWidth = 3.0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryColor;
    final effectiveBackgroundColor =
        backgroundColor ?? effectiveColor.withValues(alpha: 0.2);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              color: effectiveBackgroundColor,
            ),
          ),
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              color: effectiveColor,
              strokeCap: StrokeCap.round,
            ),
          ),
          // Center content
          if (showPercentage && onCancel == null)
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: size * 0.22,
                fontWeight: FontWeight.w600,
                color: effectiveColor,
              ),
            ),
          if (onCancel != null)
            GestureDetector(
              onTap: onCancel,
              child: Icon(
                Icons.close_rounded,
                size: size * 0.4,
                color: effectiveColor,
              ),
            ),
        ],
      ),
    );
  }
}

/// A linear progress indicator for downloads.
///
/// Shows a horizontal progress bar with optional percentage text.
class LinearDownloadProgress extends StatelessWidget {
  /// Download progress from 0.0 to 1.0.
  final double progress;

  /// Bytes received so far.
  final int bytesReceived;

  /// Total bytes to download.
  final int totalBytes;

  /// Height of the progress bar.
  final double height;

  /// Color of the progress bar.
  final Color? color;

  /// Background color of the progress bar.
  final Color? backgroundColor;

  /// Whether to show the progress text.
  final bool showText;

  /// Callback when cancel is pressed.
  final VoidCallback? onCancel;

  const LinearDownloadProgress({
    super.key,
    required this.progress,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.height = 4.0,
    this.color,
    this.backgroundColor,
    this.showText = true,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primaryColor;
    final effectiveBackgroundColor =
        backgroundColor ?? effectiveColor.withValues(alpha: 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showText)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatProgress(),
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                if (onCancel != null)
                  GestureDetector(
                    onTap: onCancel,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: height,
            color: effectiveColor,
            backgroundColor: effectiveBackgroundColor,
          ),
        ),
      ],
    );
  }

  String _formatProgress() {
    final percent = '${(progress * 100).toInt()}%';
    if (totalBytes <= 0) return percent;

    return '$percent · ${_formatSize(bytesReceived)} / ${_formatSize(totalBytes)}';
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// A download status chip showing current download state.
///
/// Useful for showing download status in list items or cards.
class DownloadStatusChip extends StatelessWidget {
  /// Current download progress (0.0 to 1.0).
  final double? progress;

  /// Whether the download completed successfully.
  final bool isComplete;

  /// Whether the download failed.
  final bool isFailed;

  /// Error message if failed.
  final String? errorMessage;

  /// Callback when cancel is pressed (during download).
  final VoidCallback? onCancel;

  /// Callback when retry is pressed (after failure).
  final VoidCallback? onRetry;

  const DownloadStatusChip({
    super.key,
    this.progress,
    this.isComplete = false,
    this.isFailed = false,
    this.errorMessage,
    this.onCancel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (isComplete) {
      return _buildChip(
        icon: Icons.check_circle_rounded,
        label: 'Downloaded',
        color: AppTheme.successColor,
      );
    }

    if (isFailed) {
      return GestureDetector(
        onTap: onRetry,
        child: _buildChip(
          icon: Icons.error_rounded,
          label: 'Failed',
          color: AppTheme.errorColor,
        ),
      );
    }

    if (progress != null) {
      return _buildProgressChip();
    }

    return const SizedBox.shrink();
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressChip() {
    final percent = '${((progress ?? 0) * 100).toInt()}%';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            percent,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onCancel != null) ...[
            const SizedBox(width: AppTheme.spacingXs),
            GestureDetector(
              onTap: onCancel,
              child: const Icon(
                Icons.close_rounded,
                size: 14,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
