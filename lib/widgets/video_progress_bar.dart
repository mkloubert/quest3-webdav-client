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
import 'package:video_player/video_player.dart';

import '../constants/app_theme.dart';

/// A seekable video progress bar with buffered progress visualization.
///
/// Shows the current playback position, buffered amount, and total duration.
/// Supports drag-to-seek functionality for precise navigation.
class VideoProgressBar extends StatefulWidget {
  /// The video player controller.
  final VideoPlayerController controller;

  /// Callback when seeking starts.
  final VoidCallback? onSeekStart;

  /// Callback when seeking ends.
  final VoidCallback? onSeekEnd;

  /// The height of the progress bar.
  final double barHeight;

  /// The color of the played portion.
  final Color playedColor;

  /// The color of the buffered portion.
  final Color bufferedColor;

  /// The color of the background.
  final Color backgroundColor;

  /// The color of the seek handle.
  final Color handleColor;

  const VideoProgressBar({
    super.key,
    required this.controller,
    this.onSeekStart,
    this.onSeekEnd,
    this.barHeight = 4.0,
    this.playedColor = AppTheme.primaryColor,
    this.bufferedColor = Colors.white30,
    this.backgroundColor = Colors.white12,
    this.handleColor = Colors.white,
  });

  @override
  State<VideoProgressBar> createState() => _VideoProgressBarState();
}

class _VideoProgressBarState extends State<VideoProgressBar> {
  bool _isDragging = false;
  double _dragPosition = 0.0;

  VideoPlayerController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, child) {
        final duration = value.duration;
        final position = _isDragging
            ? Duration(
                milliseconds:
                    (_dragPosition * duration.inMilliseconds).round())
            : value.position;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time display
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white70,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // Progress bar
            GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onTapDown: _onTapDown,
              child: Container(
                height: 32, // Larger touch target
                alignment: Alignment.center,
                child: SizedBox(
                  height: widget.barHeight,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildProgressBar(
                        constraints.maxWidth,
                        value,
                        duration,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(
    double width,
    VideoPlayerValue value,
    Duration duration,
  ) {
    final durationMs = duration.inMilliseconds;
    if (durationMs == 0) {
      return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(widget.barHeight / 2),
        ),
      );
    }

    final positionPercent = _isDragging
        ? _dragPosition
        : value.position.inMilliseconds / durationMs;

    // Calculate buffered percentage
    double bufferedPercent = 0.0;
    for (final range in value.buffered) {
      if (range.start <= value.position && range.end >= value.position) {
        bufferedPercent = range.end.inMilliseconds / durationMs;
        break;
      }
      if (range.end.inMilliseconds / durationMs > bufferedPercent) {
        bufferedPercent = range.end.inMilliseconds / durationMs;
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background
        Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.barHeight / 2),
          ),
        ),
        // Buffered
        FractionallySizedBox(
          widthFactor: bufferedPercent.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: widget.bufferedColor,
              borderRadius: BorderRadius.circular(widget.barHeight / 2),
            ),
          ),
        ),
        // Played
        FractionallySizedBox(
          widthFactor: positionPercent.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: widget.playedColor,
              borderRadius: BorderRadius.circular(widget.barHeight / 2),
            ),
          ),
        ),
        // Handle
        Positioned(
          left: (width * positionPercent.clamp(0.0, 1.0)) - 8,
          top: -6,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: widget.handleColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragPosition = _calculatePosition(details.localPosition.dx);
    });
    widget.onSeekStart?.call();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition = _calculatePosition(details.localPosition.dx);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final duration = _controller.value.duration;
    final seekPosition = Duration(
      milliseconds: (_dragPosition * duration.inMilliseconds).round(),
    );
    _controller.seekTo(seekPosition);
    setState(() {
      _isDragging = false;
    });
    widget.onSeekEnd?.call();
  }

  void _onTapDown(TapDownDetails details) {
    final position = _calculatePosition(details.localPosition.dx);
    final duration = _controller.value.duration;
    final seekPosition = Duration(
      milliseconds: (position * duration.inMilliseconds).round(),
    );
    _controller.seekTo(seekPosition);
  }

  double _calculatePosition(double localX) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return 0.0;
    return (localX / box.size.width).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

/// A compact progress indicator without seek functionality.
///
/// Useful for showing progress in a minimal space.
class VideoProgressIndicator extends StatelessWidget {
  /// The video player controller.
  final VideoPlayerController controller;

  /// The height of the progress bar.
  final double height;

  /// The color of the played portion.
  final Color playedColor;

  /// The color of the background.
  final Color backgroundColor;

  const VideoProgressIndicator({
    super.key,
    required this.controller,
    this.height = 2.0,
    this.playedColor = AppTheme.primaryColor,
    this.backgroundColor = Colors.white24,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final duration = value.duration.inMilliseconds;
        final position = value.position.inMilliseconds;
        final progress = duration > 0 ? position / duration : 0.0;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: playedColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        );
      },
    );
  }
}
