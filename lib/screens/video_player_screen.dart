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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../providers/providers.dart';
import '../services/download_service.dart';

/// Screen for playing videos with streaming support and playback controls.
///
/// Uses media_kit for better performance with large files.
/// Supports:
/// - Streaming from WebDAV server with authentication
/// - Offline playback from local files
/// - Playback controls with auto-hide
/// - Seek functionality
/// - Playback speed control
class VideoPlayerScreen extends ConsumerStatefulWidget {
  /// The video file to play.
  final FileItem file;

  /// The ID of the virtual folder containing the video.
  final String folderId;

  const VideoPlayerScreen({
    super.key,
    required this.file,
    required this.folderId,
  });

  @override
  ConsumerState<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;

  bool _isInitializing = true;
  String? _errorMessage;
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;

  // Download state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Create player and video controller
    _player = Player();
    _videoController = VideoController(_player);

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _initializePlayer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _player.dispose();

    // Restore system UI and orientation
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      String videoSource;
      Map<String, String>? headers;

      // Check if offline version is available
      if (widget.file.isOfflineAvailable && widget.file.offlinePath != null) {
        videoSource = widget.file.offlinePath!;
      } else {
        // Stream from WebDAV server
        final webDavService = await ref.read(
          webDavServiceProvider(widget.folderId).future,
        );

        videoSource = webDavService.getFileUrl(widget.file.path);
        headers = webDavService.getAuthHeaders();
      }

      // Open the media
      await _player.open(
        Media(
          videoSource,
          httpHeaders: headers,
        ),
        play: true,
      );

      // Wait for the player to be ready
      await _player.stream.width.first.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Video initialization timed out'),
      );

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });

        _startHideControlsTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = _formatError(e);
        });
      }
    }
  }

  String _formatError(dynamic error) {
    final message = error.toString();
    if (message.contains('HttpException') || message.contains('SocketException')) {
      return 'Network error: Unable to stream video';
    }
    if (message.contains('timed out')) {
      return 'Connection timed out. Please check your network.';
    }
    return 'Error: $message';
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controlsVisible) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _startHideControlsTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show loading state
    if (_isInitializing) {
      return Stack(
        children: [
          _buildLoadingState(),
          _buildCloseButton(),
        ],
      );
    }

    // Show error state
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // Show player
    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          Center(
            child: Video(
              controller: _videoController,
              controls: NoVideoControls,
            ),
          ),
          // Custom controls overlay
          if (_controlsVisible) _buildControlsOverlay(),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        child: IconButton(
          onPressed: _onClose,
          icon: const Icon(Icons.close_rounded),
          color: Colors.white,
          tooltip: 'Close',
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Loading video...',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              widget.file.name,
              style: AppTheme.bodySmall.copyWith(
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Unable to play video',
              style: AppTheme.titleLarge.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _onClose,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                  child: const Text('Close'),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                ElevatedButton(
                  onPressed: _initializePlayer,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
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
              IconButton(
                onPressed: _onClose,
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                tooltip: 'Close',
              ),
              const SizedBox(width: AppTheme.spacingSm),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_pin_rounded, size: 16, color: Colors.white),
                      SizedBox(width: AppTheme.spacingXs),
                      Text('Offline', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return StreamBuilder<bool>(
      stream: _player.stream.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rewind 10 seconds
            IconButton(
              onPressed: () => _seekRelative(-10),
              icon: const Icon(Icons.replay_10_rounded),
              iconSize: 40,
              color: Colors.white,
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
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
              _buildProgressBar(),
              const SizedBox(height: AppTheme.spacingSm),
              // Bottom actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSpeedButton(),
                  if (!widget.file.isOfflineAvailable) _buildDownloadButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _player.stream.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: _player.stream.duration,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.primaryColor,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: duration.inMilliseconds > 0
                        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: (value) {
                      final newPosition = Duration(
                        milliseconds: (value * duration.inMilliseconds).round(),
                      );
                      _player.seek(newPosition);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSpeedButton() {
    return StreamBuilder<double>(
      stream: _player.stream.rate,
      builder: (context, snapshot) {
        final rate = snapshot.data ?? 1.0;

        return PopupMenuButton<double>(
          onSelected: (speed) => _player.setRate(speed),
          itemBuilder: (context) => [
            _buildSpeedMenuItem(0.5, rate),
            _buildSpeedMenuItem(0.75, rate),
            _buildSpeedMenuItem(1.0, rate),
            _buildSpeedMenuItem(1.25, rate),
            _buildSpeedMenuItem(1.5, rate),
            _buildSpeedMenuItem(2.0, rate),
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
                const Icon(Icons.speed_rounded, size: 18, color: Colors.white70),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  '${rate}x',
                  style: AppTheme.bodySmall.copyWith(color: Colors.white),
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
    if (_isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                value: _downloadProgress > 0 ? _downloadProgress : null,
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              '${(_downloadProgress * 100).toInt()}%',
              style: AppTheme.bodyMedium.copyWith(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return IconButton(
      onPressed: _onDownload,
      icon: const Icon(Icons.download_rounded),
      color: Colors.white,
      tooltip: 'Download for offline',
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _togglePlayPause() {
    _player.playOrPause();
    _startHideControlsTimer();
  }

  void _seekRelative(int seconds) {
    final currentPosition = _player.state.position;
    final duration = _player.state.duration;
    final newPosition = currentPosition + Duration(seconds: seconds);

    if (newPosition < Duration.zero) {
      _player.seek(Duration.zero);
    } else if (newPosition > duration) {
      _player.seek(duration);
    } else {
      _player.seek(newPosition);
    }
    _startHideControlsTimer();
  }

  void _onClose() {
    Navigator.of(context).pop();
  }

  Future<void> _onDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final webDavService = await ref.read(
        webDavServiceProvider(widget.folderId).future,
      );

      final database = ref.read(databaseProvider);
      final downloadService = DownloadService(database);

      await downloadService.downloadFile(
        widget.file,
        widget.folderId,
        webDavService,
        onProgress: (progress, received, total) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        ref.invalidate(offlineFileInfoProvider((
          folderId: widget.folderId,
          remotePath: widget.file.path,
        )));
        ref.invalidate(allOfflineFilesProvider);
        ref.invalidate(totalOfflineSizeProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded ${widget.file.name}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
