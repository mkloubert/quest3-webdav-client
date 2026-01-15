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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../providers/providers.dart';
import '../services/media_type_detector.dart';
import '../widgets/video_controls_overlay.dart';
import 'vr_video_player_screen.dart';

/// Screen for playing videos with streaming support and playback controls.
///
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
  VideoPlayerController? _controller;
  late VideoOverlayController _overlayController;

  bool _isInitializing = true;
  String? _errorMessage;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  // Viewer mode state
  ViewerMode _currentMode = ViewerMode.normal;
  MediaTypeInfo? _mediaTypeInfo;

  @override
  void initState() {
    super.initState();
    _overlayController = VideoOverlayController();

    // Detect media type from file name
    _mediaTypeInfo = MediaTypeDetector.detectMediaType(widget.file);
    _currentMode = MediaTypeDetector.getRecommendedViewerMode(_mediaTypeInfo!);

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
    _controller?.dispose();
    _overlayController.dispose();

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
      VideoPlayerController controller;

      // Check if offline version is available
      if (widget.file.isOfflineAvailable && widget.file.offlinePath != null) {
        controller = VideoPlayerController.file(
          File(widget.file.offlinePath!),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else {
        // Stream from WebDAV server
        final webDavService = await ref.read(
          webDavServiceProvider(widget.folderId).future,
        );

        final videoUrl = webDavService.getFileUrl(widget.file.path);
        final headers = webDavService.getAuthHeaders();

        controller = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
          httpHeaders: headers,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      }

      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitializing = false;
        });

        // Start playback automatically
        controller.play();

        // Listen for errors during playback
        controller.addListener(_onPlayerStateChanged);
      } else {
        controller.dispose();
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

  void _onPlayerStateChanged() {
    final controller = _controller;
    if (controller == null) return;

    // Check for errors
    if (controller.value.hasError) {
      setState(() {
        _errorMessage = controller.value.errorDescription ?? 'Playback error';
      });
    }

    // Show controls when video completes
    if (controller.value.position >= controller.value.duration &&
        controller.value.duration > Duration.zero) {
      _overlayController.show();
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Show loading state
    if (_isInitializing) {
      return _buildLoadingState();
    }

    // Show error state
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // Show player
    final controller = _controller;
    if (controller == null) {
      return _buildErrorState();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video player
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        // Controls overlay
        ListenableBuilder(
          listenable: _overlayController,
          builder: (context, child) {
            return VideoControlsOverlay(
              controller: controller,
              file: widget.file,
              isVisible: _overlayController.isVisible,
              onClose: _onClose,
              onToggleVisibility: () => _overlayController.toggle(),
              onDownload: widget.file.isOfflineAvailable ? null : _onDownload,
              isOfflineAvailable: widget.file.isOfflineAvailable,
              isDownloading: _isDownloading,
              downloadProgress: _downloadProgress,
              currentMode: _currentMode,
              mediaTypeInfo: _mediaTypeInfo,
              onModeChanged: _onModeChanged,
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
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

  void _onClose() {
    Navigator.of(context).pop();
  }

  void _onModeChanged(ViewerMode newMode) {
    // If switching to panorama or VR mode, navigate to VR player
    if (newMode == ViewerMode.panorama360 || newMode == ViewerMode.vr3d) {
      // Pause current video before switching
      _controller?.pause();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => VrVideoPlayerScreen(
            file: widget.file,
            folderId: widget.folderId,
            mediaTypeInfo: _mediaTypeInfo,
          ),
        ),
      );
    } else {
      // For normal and cinema modes, update state
      setState(() {
        _currentMode = newMode;
      });
    }
  }

  Future<void> _onDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // TODO: Implement actual download with progress
      // For now, simulate download progress
      for (var i = 0; i <= 100; i += 5) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {
            _downloadProgress = i / 100;
          });
        }
      }

      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

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
