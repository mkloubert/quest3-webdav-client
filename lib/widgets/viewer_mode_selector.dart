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
import '../services/media_type_detector.dart';

/// Bottom sheet for selecting video viewer mode.
///
/// Allows users to choose between Normal, Cinema, 360° Panorama,
/// and VR 3D modes for video playback.
class ViewerModeSelector extends StatelessWidget {
  /// Currently selected mode.
  final ViewerMode currentMode;

  /// Detected media type info (for recommendations).
  final MediaTypeInfo? mediaTypeInfo;

  /// Callback when a mode is selected.
  final ValueChanged<ViewerMode> onModeSelected;

  const ViewerModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
    this.mediaTypeInfo,
  });

  /// Shows the viewer mode selector as a bottom sheet.
  static Future<ViewerMode?> show(
    BuildContext context, {
    required ViewerMode currentMode,
    MediaTypeInfo? mediaTypeInfo,
  }) {
    return showModalBottomSheet<ViewerMode>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => ViewerModeSelector(
        currentMode: currentMode,
        mediaTypeInfo: mediaTypeInfo,
        onModeSelected: (mode) => Navigator.of(context).pop(mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendedMode = mediaTypeInfo != null
        ? MediaTypeDetector.getRecommendedViewerMode(mediaTypeInfo!)
        : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Title
            Text(
              'Viewer Mode',
              style: AppTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXs),

            // Subtitle with detected info
            if (mediaTypeInfo != null && mediaTypeInfo!.isImmersive)
              Text(
                'Detected: ${mediaTypeInfo!.summary} content',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppTheme.spacingLg),

            // Mode options
            _buildModeOption(
              context,
              mode: ViewerMode.normal,
              icon: Icons.tv_rounded,
              isRecommended: recommendedMode == ViewerMode.normal,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildModeOption(
              context,
              mode: ViewerMode.cinema,
              icon: Icons.theaters_rounded,
              isRecommended: recommendedMode == ViewerMode.cinema,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildModeOption(
              context,
              mode: ViewerMode.panorama360,
              icon: Icons.panorama_horizontal_rounded,
              isRecommended: recommendedMode == ViewerMode.panorama360,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _buildModeOption(
              context,
              mode: ViewerMode.vr3d,
              icon: Icons.view_in_ar_rounded,
              isRecommended: recommendedMode == ViewerMode.vr3d,
            ),
            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context, {
    required ViewerMode mode,
    required IconData icon,
    bool isRecommended = false,
  }) {
    final isSelected = currentMode == mode;

    return Material(
      color: isSelected
          ? AppTheme.primaryColor.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        onTap: () => onModeSelected(mode),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mode.displayName,
                          style: AppTheme.titleMedium.copyWith(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textPrimary,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: AppTheme.spacingSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              'Recommended',
                              style: AppTheme.bodySmall.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.description,
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              // Selected indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact button for switching viewer modes.
///
/// Shows current mode and opens selector when tapped.
class ViewerModeButton extends StatelessWidget {
  /// Current viewer mode.
  final ViewerMode currentMode;

  /// Detected media type info.
  final MediaTypeInfo? mediaTypeInfo;

  /// Callback when mode changes.
  final ValueChanged<ViewerMode> onModeChanged;

  const ViewerModeButton({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
    this.mediaTypeInfo,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final selectedMode = await ViewerModeSelector.show(
          context,
          currentMode: currentMode,
          mediaTypeInfo: mediaTypeInfo,
        );
        if (selectedMode != null) {
          onModeChanged(selectedMode);
        }
      },
      icon: Icon(_getIconForMode(currentMode)),
      color: Colors.white,
      tooltip: 'Change viewer mode (${currentMode.displayName})',
    );
  }

  IconData _getIconForMode(ViewerMode mode) {
    switch (mode) {
      case ViewerMode.normal:
        return Icons.tv_rounded;
      case ViewerMode.cinema:
        return Icons.theaters_rounded;
      case ViewerMode.panorama360:
        return Icons.panorama_horizontal_rounded;
      case ViewerMode.vr3d:
        return Icons.view_in_ar_rounded;
    }
  }
}

/// Dialog for confirming mode switch with preview.
class ViewerModeConfirmDialog extends StatelessWidget {
  /// The mode to switch to.
  final ViewerMode targetMode;

  const ViewerModeConfirmDialog({
    super.key,
    required this.targetMode,
  });

  /// Shows the confirmation dialog.
  static Future<bool?> show(BuildContext context, ViewerMode targetMode) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ViewerModeConfirmDialog(targetMode: targetMode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Switch to ${targetMode.displayName}?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForMode(targetMode),
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            targetMode.description,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium,
          ),
          if (targetMode == ViewerMode.panorama360 ||
              targetMode == ViewerMode.vr3d) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'This mode works best with 360° or VR content.',
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Switch'),
        ),
      ],
    );
  }

  IconData _getIconForMode(ViewerMode mode) {
    switch (mode) {
      case ViewerMode.normal:
        return Icons.tv_rounded;
      case ViewerMode.cinema:
        return Icons.theaters_rounded;
      case ViewerMode.panorama360:
        return Icons.panorama_horizontal_rounded;
      case ViewerMode.vr3d:
        return Icons.view_in_ar_rounded;
    }
  }
}
