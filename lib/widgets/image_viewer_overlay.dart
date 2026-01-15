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

import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../models/file_item.dart';

/// Overlay UI for the image viewer.
///
/// Shows top and bottom bars with controls and file information.
/// Auto-hides after a period of inactivity.
class ImageViewerOverlay extends StatefulWidget {
  /// The current file being viewed.
  final FileItem file;

  /// Whether the overlay is visible.
  final bool isVisible;

  /// Callback when close is pressed.
  final VoidCallback onClose;

  /// Callback when download is pressed.
  final VoidCallback? onDownload;

  /// Callback when remove offline is pressed.
  final VoidCallback? onRemoveOffline;

  /// Callback when previous is pressed.
  final VoidCallback? onPrevious;

  /// Callback when next is pressed.
  final VoidCallback? onNext;

  /// Current index in the image list.
  final int currentIndex;

  /// Total number of images.
  final int totalImages;

  /// Whether download is in progress.
  final bool isDownloading;

  /// Download progress (0.0 to 1.0).
  final double downloadProgress;

  const ImageViewerOverlay({
    super.key,
    required this.file,
    required this.isVisible,
    required this.onClose,
    this.onDownload,
    this.onRemoveOffline,
    this.onPrevious,
    this.onNext,
    required this.currentIndex,
    required this.totalImages,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });

  @override
  State<ImageViewerOverlay> createState() => _ImageViewerOverlayState();
}

class _ImageViewerOverlayState extends State<ImageViewerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ImageViewerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: IgnorePointer(
        ignoring: !widget.isVisible,
        child: Stack(
          children: [
            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(context),
            ),
            // Bottom bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomBar(context),
            ),
            // Navigation arrows
            if (widget.onPrevious != null || widget.onNext != null)
              _buildNavigationArrows(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              // Close button
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                tooltip: 'Close',
              ),
              const SizedBox(width: AppTheme.spacingSm),
              // File name and index
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.file.name,
                      style: AppTheme.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.totalImages > 1)
                      Text(
                        '${widget.currentIndex + 1} of ${widget.totalImages}',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              // Offline indicator
              if (widget.file.isOfflineAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.offline_pin_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        'Offline',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Download button
              if (!widget.file.isOfflineAvailable && widget.onDownload != null)
                _buildActionButton(
                  icon: widget.isDownloading
                      ? null
                      : Icons.download_rounded,
                  label: widget.isDownloading
                      ? '${(widget.downloadProgress * 100).toInt()}%'
                      : 'Download',
                  onPressed: widget.isDownloading ? null : widget.onDownload,
                  isLoading: widget.isDownloading,
                  progress: widget.downloadProgress,
                ),
              // Remove offline button
              if (widget.file.isOfflineAvailable &&
                  widget.onRemoveOffline != null)
                _buildActionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove Offline',
                  onPressed: widget.onRemoveOffline,
                ),
              const SizedBox(width: AppTheme.spacingMd),
              // File info
              _buildInfoChip(
                icon: Icons.photo_size_select_actual_rounded,
                label: widget.file.formattedSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    required String label,
    VoidCallback? onPressed,
    bool isLoading = false,
    double progress = 0.0,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress > 0 ? progress : null,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 20),
      label: Text(label),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: AppTheme.spacingXs),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationArrows() {
    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous button
            if (widget.onPrevious != null)
              _buildNavButton(
                icon: Icons.chevron_left_rounded,
                onPressed: widget.onPrevious,
                tooltip: 'Previous',
              )
            else
              const SizedBox(width: 48),
            // Next button
            if (widget.onNext != null)
              _buildNavButton(
                icon: Icons.chevron_right_rounded,
                onPressed: widget.onNext,
                tooltip: 'Next',
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 32),
        color: Colors.white,
        tooltip: tooltip,
      ),
    );
  }
}

/// Controller for managing overlay visibility with auto-hide.
class OverlayVisibilityController extends ChangeNotifier {
  bool _isVisible = true;
  Timer? _hideTimer;

  /// Duration of inactivity before auto-hiding.
  final Duration autoHideDuration;

  OverlayVisibilityController({
    this.autoHideDuration = const Duration(seconds: 3),
  }) {
    _startHideTimer();
  }

  /// Whether the overlay is currently visible.
  bool get isVisible => _isVisible;

  /// Toggles overlay visibility.
  void toggle() {
    _isVisible = !_isVisible;
    notifyListeners();
    if (_isVisible) {
      _startHideTimer();
    } else {
      _cancelHideTimer();
    }
  }

  /// Shows the overlay and resets the hide timer.
  void show() {
    if (!_isVisible) {
      _isVisible = true;
      notifyListeners();
    }
    _startHideTimer();
  }

  /// Hides the overlay.
  void hide() {
    if (_isVisible) {
      _isVisible = false;
      notifyListeners();
    }
    _cancelHideTimer();
  }

  /// Resets the hide timer without changing visibility.
  void resetTimer() {
    if (_isVisible) {
      _startHideTimer();
    }
  }

  void _startHideTimer() {
    _cancelHideTimer();
    _hideTimer = Timer(autoHideDuration, () {
      if (_isVisible) {
        _isVisible = false;
        notifyListeners();
      }
    });
  }

  void _cancelHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  @override
  void dispose() {
    _cancelHideTimer();
    super.dispose();
  }
}
