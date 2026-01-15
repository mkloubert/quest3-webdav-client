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

/// Connection status states.
enum ConnectionStatus {
  /// Not tested yet.
  unknown,

  /// Currently testing connection.
  testing,

  /// Connection successful.
  connected,

  /// Connection failed.
  failed,
}

/// A visual indicator for connection status.
///
/// Shows an icon and color based on the current connection state.
class ConnectionStatusIndicator extends StatelessWidget {
  /// The current connection status.
  final ConnectionStatus status;

  /// Optional error message for failed status.
  final String? errorMessage;

  /// Size of the indicator.
  final double size;

  /// Whether to show a label next to the icon.
  final bool showLabel;

  const ConnectionStatusIndicator({
    super.key,
    required this.status,
    this.errorMessage,
    this.size = 24.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _getStatusDetails();

    if (showLabel) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(icon, color),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            label,
            style: AppTheme.bodyMedium.copyWith(color: color),
          ),
        ],
      );
    }

    return _buildIcon(icon, color);
  }

  Widget _buildIcon(IconData icon, Color color) {
    if (status == ConnectionStatus.testing) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }

    return Icon(
      icon,
      size: size,
      color: color,
    );
  }

  (IconData, Color, String) _getStatusDetails() {
    switch (status) {
      case ConnectionStatus.unknown:
        return (
          Icons.help_outline_rounded,
          AppTheme.textSecondary,
          'Not tested',
        );
      case ConnectionStatus.testing:
        return (
          Icons.sync_rounded,
          AppTheme.primaryColor,
          'Testing...',
        );
      case ConnectionStatus.connected:
        return (
          Icons.check_circle_rounded,
          AppTheme.successColor,
          'Connected',
        );
      case ConnectionStatus.failed:
        return (
          Icons.error_rounded,
          AppTheme.errorColor,
          errorMessage ?? 'Connection failed',
        );
    }
  }
}

/// A banner widget showing connection status with more details.
class ConnectionStatusBanner extends StatelessWidget {
  /// The current connection status.
  final ConnectionStatus status;

  /// Optional error message for failed status.
  final String? errorMessage;

  /// Callback when retry is pressed.
  final VoidCallback? onRetry;

  const ConnectionStatusBanner({
    super.key,
    required this.status,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ConnectionStatus.unknown) {
      return const SizedBox.shrink();
    }

    final (icon, color, title, subtitle) = _getStatusDetails();

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (status == ConnectionStatus.testing)
            SizedBox(
              width: AppTheme.iconSizeMd,
              height: AppTheme.iconSizeMd,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(icon, color: color, size: AppTheme.iconSizeMd),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTheme.titleMedium.copyWith(color: color),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (status == ConnectionStatus.failed && onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  (IconData, Color, String, String?) _getStatusDetails() {
    switch (status) {
      case ConnectionStatus.unknown:
        return (
          Icons.help_outline_rounded,
          AppTheme.textSecondary,
          'Unknown',
          null,
        );
      case ConnectionStatus.testing:
        return (
          Icons.sync_rounded,
          AppTheme.primaryColor,
          'Testing connection...',
          'Please wait while we verify the server.',
        );
      case ConnectionStatus.connected:
        return (
          Icons.check_circle_rounded,
          AppTheme.successColor,
          'Connection successful',
          'The server is reachable and credentials are valid.',
        );
      case ConnectionStatus.failed:
        return (
          Icons.error_rounded,
          AppTheme.errorColor,
          'Connection failed',
          errorMessage,
        );
    }
  }
}
