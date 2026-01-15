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
import 'package:video_player/video_player.dart';

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../services/media_type_detector.dart';
import 'video_progress_bar.dart';
import 'viewer_mode_selector.dart';

/// Overlay UI for video player controls.
///
/// Provides play/pause, seek, and navigation controls.
/// Auto-hides after a period of inactivity.
class VideoControlsOverlay extends StatefulWidget {
  /// The video player controller.
  final VideoPlayerController controller;

  /// The current file being played.
  final FileItem file;

  /// Whether the overlay is visible.
  final bool isVisible;

  /// Callback when close is pressed.
  final VoidCallback onClose;

  /// Callback when download is pressed.
  final VoidCallback? onDownload;

  /// Callback to toggle visibility.
  final VoidCallback onToggleVisibility;

  /// Whether the file is available offline.
  final bool isOfflineAvailable;

  /// Whether download is in progress.
  final bool isDownloading;

  /// Download progress (0.0 to 1.0).
  final double downloadProgress;

  /// Current viewer mode.
  final ViewerMode currentMode;

  /// Detected media type info.
  final MediaTypeInfo? mediaTypeInfo;

  /// Callback when viewer mode changes.
  final ValueChanged<ViewerMode>? onModeChanged;

  const VideoControlsOverlay({
    super.key,
    required this.controller,
    required this.file,
    required this.isVisible,
    required this.onClose,
    required this.onToggleVisibility,
    this.onDownload,
    this.isOfflineAvailable = false,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
    this.currentMode = ViewerMode.normal,
    this.mediaTypeInfo,
    this.onModeChanged,
  });

  @override
  State<VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<VideoControlsOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  VideoPlayerController get _controller => widget.controller;

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
  void didUpdateWidget(VideoControlsOverlay oldWidget) {
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
    return GestureDetector(
      onTap: widget.onToggleVisibility,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: IgnorePointer(
          ignoring: !widget.isVisible,
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: Stack(
              children: [
                // Top bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(),
                ),
                // Center controls
                Center(
                  child: _buildCenterControls(),
                ),
                // Bottom bar
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildBottomBar(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
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
              // File name
              Expanded(
                child: Text(
                  widget.file.name,
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Offline indicator
              if (widget.isOfflineAvailable)
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
              // Viewer mode button
              if (widget.onModeChanged != null)
                ViewerModeButton(
                  currentMode: widget.currentMode,
                  mediaTypeInfo: widget.mediaTypeInfo,
                  onModeChanged: widget.onModeChanged!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, child) {
        // Show loading indicator while buffering
        if (value.isBuffering) {
          return const SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Colors.white,
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rewind 10 seconds
            IconButton(
              onPressed: () => _seekRelative(-10),
              icon: const Icon(Icons.replay_10_rounded),
              iconSize: 40,
              color: Colors.white,
              tooltip: 'Rewind 10 seconds',
            ),
            const SizedBox(width: AppTheme.spacingLg),
            // Play/Pause
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingLg),
            // Forward 10 seconds
            IconButton(
              onPressed: () => _seekRelative(10),
              icon: const Icon(Icons.forward_10_rounded),
              iconSize: 40,
              color: Colors.white,
              tooltip: 'Forward 10 seconds',
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar() {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar
              VideoProgressBar(
                controller: _controller,
                onSeekStart: () {
                  // Pause auto-hide while seeking
                },
                onSeekEnd: () {
                  // Resume auto-hide after seeking
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
              // Bottom actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Playback speed
                  _buildSpeedButton(),
                  // Download button
                  if (!widget.isOfflineAvailable && widget.onDownload != null)
                    _buildDownloadButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton() {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, child) {
        return PopupMenuButton<double>(
          onSelected: (speed) {
            _controller.setPlaybackSpeed(speed);
          },
          itemBuilder: (context) => [
            _buildSpeedMenuItem(0.5, value.playbackSpeed),
            _buildSpeedMenuItem(0.75, value.playbackSpeed),
            _buildSpeedMenuItem(1.0, value.playbackSpeed),
            _buildSpeedMenuItem(1.25, value.playbackSpeed),
            _buildSpeedMenuItem(1.5, value.playbackSpeed),
            _buildSpeedMenuItem(2.0, value.playbackSpeed),
          ],
          child: Container(
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
                const Icon(
                  Icons.speed_rounded,
                  size: 18,
                  color: Colors.white70,
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  '${value.playbackSpeed}x',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<double> _buildSpeedMenuItem(double speed, double currentSpeed) {
    final isSelected = speed == currentSpeed;
    return PopupMenuItem(
      value: speed,
      child: Row(
        children: [
          if (isSelected)
            const Padding(
              padding: EdgeInsets.only(right: AppTheme.spacingSm),
              child: Icon(Icons.check_rounded, size: 18),
            )
          else
            const SizedBox(width: 18 + AppTheme.spacingSm),
          Text('${speed}x'),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (widget.isDownloading) {
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
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                value: widget.downloadProgress > 0
                    ? widget.downloadProgress
                    : null,
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Text(
              '${(widget.downloadProgress * 100).toInt()}%',
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return IconButton(
      onPressed: widget.onDownload,
      icon: const Icon(Icons.download_rounded),
      color: Colors.white,
      tooltip: 'Download for offline',
    );
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _seekRelative(int seconds) {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + Duration(seconds: seconds);
    final duration = _controller.value.duration;

    if (newPosition < Duration.zero) {
      _controller.seekTo(Duration.zero);
    } else if (newPosition > duration) {
      _controller.seekTo(duration);
    } else {
      _controller.seekTo(newPosition);
    }
  }
}

/// Controller for managing video controls overlay visibility with auto-hide.
class VideoOverlayController extends ChangeNotifier {
  bool _isVisible = true;
  Timer? _hideTimer;
  bool _isSeeking = false;

  /// Duration of inactivity before auto-hiding.
  final Duration autoHideDuration;

  VideoOverlayController({
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
    if (_isVisible && !_isSeeking) {
      _isVisible = false;
      notifyListeners();
    }
    _cancelHideTimer();
  }

  /// Call when seeking starts to prevent auto-hide.
  void startSeeking() {
    _isSeeking = true;
    _cancelHideTimer();
  }

  /// Call when seeking ends to resume auto-hide.
  void endSeeking() {
    _isSeeking = false;
    _startHideTimer();
  }

  /// Resets the hide timer without changing visibility.
  void resetTimer() {
    if (_isVisible && !_isSeeking) {
      _startHideTimer();
    }
  }

  void _startHideTimer() {
    _cancelHideTimer();
    _hideTimer = Timer(autoHideDuration, () {
      if (_isVisible && !_isSeeking) {
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
