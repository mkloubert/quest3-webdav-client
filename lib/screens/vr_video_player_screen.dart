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
import 'package:vr_player/vr_player.dart';

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../providers/providers.dart';
import '../services/media_type_detector.dart';
import '../widgets/viewer_mode_selector.dart';
import 'video_player_screen.dart';

/// Screen for playing 360°/VR videos with immersive viewing.
///
/// Uses VrPlayer for equirectangular video playback with:
/// - Device motion controls for looking around
/// - Touch controls as fallback
/// - Support for mono and stereoscopic content
class VrVideoPlayerScreen extends ConsumerStatefulWidget {
  /// The video file to play.
  final FileItem file;

  /// The ID of the virtual folder containing the video.
  final String folderId;

  /// Detected media type information.
  final MediaTypeInfo? mediaTypeInfo;

  const VrVideoPlayerScreen({
    super.key,
    required this.file,
    required this.folderId,
    this.mediaTypeInfo,
  });

  @override
  ConsumerState<VrVideoPlayerScreen> createState() =>
      _VrVideoPlayerScreenState();
}

class _VrVideoPlayerScreenState extends ConsumerState<VrVideoPlayerScreen> {
  VrPlayerController? _vrController;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _isPlaying = false;
  bool _controlsVisible = true;
  Timer? _hideControlsTimer;

  // Playback state
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _startHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();

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

  void _onVrPlayerCreated(
    VrPlayerController controller,
    VrPlayerObserver observer,
  ) {
    _vrController = controller;

    // Set up observer callbacks
    observer.onStateChange = (state) {
      if (mounted) {
        setState(() {
          // VrState has: loading, ready, buffering, idle
          // Track buffering state
          _isBuffering = state == VrState.loading || state == VrState.buffering;
        });
      }
    };

    observer.onDurationChange = (duration) {
      if (mounted) {
        setState(() {
          _duration = Duration(milliseconds: duration);
        });
      }
    };

    observer.onPositionChange = (position) {
      if (mounted) {
        setState(() {
          _position = Duration(milliseconds: position);
        });
      }
    };

    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      String videoUrl;

      // Check if offline version is available
      if (widget.file.isOfflineAvailable && widget.file.offlinePath != null) {
        // Load from local file
        await _vrController?.loadVideo(
          videoPath: widget.file.offlinePath,
        );
      } else {
        // Stream from WebDAV server
        final webDavService = await ref.read(
          webDavServiceProvider(widget.folderId).future,
        );

        videoUrl = webDavService.getFileUrl(widget.file.path);
        // Note: vr_player may not support custom headers for authentication
        // This might require downloading the file first for authenticated content
        await _vrController?.loadVideo(
          videoUrl: videoUrl,
        );
      }

      // Start playback
      await _vrController?.play();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _isPlaying = true;
        });
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
    if (message.contains('HttpException')) {
      return 'Network error: Unable to stream video';
    }
    if (message.contains('PlatformException')) {
      return 'Playback error: Video format not supported';
    }
    return 'Error: $message';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // VR Player
          VrPlayer(
            x: 0,
            y: 0,
            width: size.width,
            height: size.height,
            onCreated: _onVrPlayerCreated,
          ),

          // Loading overlay
          if (_isInitializing) _buildLoadingOverlay(),

          // Error overlay
          if (_errorMessage != null) _buildErrorOverlay(),

          // Buffering indicator
          if (_isBuffering && !_isInitializing)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // Controls overlay
          GestureDetector(
            onTap: _toggleControls,
            behavior: HitTestBehavior.translucent,
            child: AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: _buildControlsOverlay(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
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
              'Loading 360° video...',
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

  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
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
                'Unable to play VR video',
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
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withValues(alpha: 0.5),
          ],
          stops: const [0.0, 0.2, 0.8, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),
            const Spacer(),
            // Center controls
            _buildCenterControls(),
            const Spacer(),
            // Bottom bar
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.file.name,
                  style: AppTheme.titleMedium.copyWith(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '360° Video',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // View mode button
          ViewerModeButton(
            currentMode: ViewerMode.panorama360,
            mediaTypeInfo: widget.mediaTypeInfo,
            onModeChanged: _onModeChanged,
          ),
          // VR mode toggle
          IconButton(
            onPressed: _toggleVrMode,
            icon: const Icon(Icons.vrpano_rounded),
            color: Colors.white,
            tooltip: 'Toggle VR mode',
          ),
        ],
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Rewind
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
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingLg),
        // Forward
        IconButton(
          onPressed: () => _seekRelative(10),
          icon: const Icon(Icons.forward_10_rounded),
          iconSize: 40,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: AppTheme.primaryColor,
              inactiveTrackColor: Colors.white30,
              thumbColor: Colors.white,
              overlayColor: Colors.white.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _duration.inMilliseconds > 0
                  ? _position.inMilliseconds / _duration.inMilliseconds
                  : 0.0,
              onChanged: (value) {
                final seekPosition = Duration(
                  milliseconds: (value * _duration.inMilliseconds).round(),
                );
                _vrController?.seekTo(seekPosition.inMilliseconds);
              },
            ),
          ),
          // Time display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  _formatDuration(_duration),
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
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

  Future<void> _togglePlayPause() async {
    final isCurrentlyPlaying = await _vrController?.isPlaying() ?? false;
    if (isCurrentlyPlaying) {
      await _vrController?.pause();
      setState(() => _isPlaying = false);
    } else {
      await _vrController?.play();
      setState(() => _isPlaying = true);
    }
    _startHideControlsTimer();
  }

  void _seekRelative(int seconds) {
    final newPosition = _position + Duration(seconds: seconds);
    final clampedPosition = Duration(
      milliseconds: newPosition.inMilliseconds.clamp(
        0,
        _duration.inMilliseconds,
      ),
    );
    _vrController?.seekTo(clampedPosition.inMilliseconds);
    _startHideControlsTimer();
  }

  void _toggleVrMode() {
    _vrController?.toggleVRMode();
    _startHideControlsTimer();
  }

  void _onClose() {
    Navigator.of(context).pop();
  }

  void _onModeChanged(ViewerMode newMode) {
    // If switching to normal or cinema mode, navigate to standard player
    if (newMode == ViewerMode.normal || newMode == ViewerMode.cinema) {
      // Stop current video before switching
      _vrController?.pause();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            file: widget.file,
            folderId: widget.folderId,
          ),
        ),
      );
    }
    // panorama360 and vr3d modes stay in VR player
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
