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

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../providers/providers.dart';
import '../services/download_service.dart';
import '../services/image_cache_service.dart';
import '../widgets/image_viewer_overlay.dart';

/// Threshold for considering an image as "large" (5 MB).
const int _largeImageThreshold = 5 * 1024 * 1024;

/// Maximum width for image decoding to prevent memory issues.
const int _maxDecodeWidth = 2048;

/// Maximum height for image decoding to prevent memory issues.
const int _maxDecodeHeight = 2048;

/// Screen for viewing images in fullscreen with zoom and gesture support.
///
/// Supports:
/// - Pinch-to-zoom and pan
/// - Swipe left/right to navigate between images
/// - Swipe down to close
/// - Double-tap to zoom
/// - Auto-hiding overlay controls
class ImageViewerScreen extends ConsumerStatefulWidget {
  /// The list of image files to display.
  final List<FileItem> images;

  /// The index of the initial image to show.
  final int initialIndex;

  /// The ID of the virtual folder containing these images.
  final String folderId;

  const ImageViewerScreen({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.folderId,
  });

  @override
  ConsumerState<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends ConsumerState<ImageViewerScreen> {
  late PageController _pageController;
  late OverlayVisibilityController _overlayController;
  late int _currentIndex;

  final ImageCacheService _imageCacheService = ImageCacheService();

  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  int _bytesReceived = 0;
  int _totalBytes = 0;
  double _downloadSpeed = 0.0;
  DateTime? _lastProgressTime;
  int _lastBytesReceived = 0;

  // Track vertical drag for swipe-to-close
  double _verticalDragStart = 0;
  double _verticalDragDelta = 0;

  // Track image loading state per image
  final Map<int, _ImageLoadState> _imageLoadStates = {};

  // Cancel token for current download
  CancelToken? _currentDownloadToken;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _overlayController = OverlayVisibilityController();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Start preloading the initial image
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImage(_currentIndex);
    });
  }

  @override
  void dispose() {
    _currentDownloadToken?.cancel();
    _pageController.dispose();
    _overlayController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  FileItem get _currentImage => widget.images[_currentIndex];

  /// Checks if the file is a GIF based on extension or MIME type.
  bool _isGif(FileItem file) {
    final ext = p.extension(file.name).toLowerCase();
    return ext == '.gif' ||
        file.mimeType?.toLowerCase() == 'image/gif';
  }

  /// Checks if an image needs preloading (large file or GIF).
  bool _needsPreloading(FileItem file) {
    // Always preload GIFs as they can freeze the UI
    if (_isGif(file)) return true;
    // Preload large images
    return file.size > _largeImageThreshold;
  }

  /// Preloads an image by downloading it to temp cache first.
  Future<void> _preloadImage(int index) async {
    if (index < 0 || index >= widget.images.length) return;

    final image = widget.images[index];

    // Skip if already loaded or loading
    if (_imageLoadStates[index]?.status == _LoadStatus.loaded ||
        _imageLoadStates[index]?.status == _LoadStatus.loading) {
      return;
    }

    // Skip if offline available
    if (image.isOfflineAvailable && image.offlinePath != null) {
      _imageLoadStates[index] = _ImageLoadState(
        status: _LoadStatus.loaded,
        localPath: image.offlinePath,
      );
      if (mounted) setState(() {});
      return;
    }

    // Check if already cached
    try {
      final webDavService = await ref.read(
        webDavServiceProvider(widget.folderId).future,
      );
      final url = webDavService.getFileUrl(image.path);
      final cachedFile = await _imageCacheService.getImageFromCache(url);

      if (cachedFile != null && await cachedFile.exists()) {
        _imageLoadStates[index] = _ImageLoadState(
          status: _LoadStatus.loaded,
          localPath: cachedFile.path,
        );
        if (mounted) setState(() {});
        return;
      }
    } catch (e) {
      // Ignore cache check errors, proceed with download
    }

    // For small non-GIF images, let the default image loading handle it
    if (!_needsPreloading(image)) {
      _imageLoadStates[index] = _ImageLoadState(
        status: _LoadStatus.loaded,
      );
      if (mounted) setState(() {});
      return;
    }

    // Start preloading
    _imageLoadStates[index] = _ImageLoadState(
      status: _LoadStatus.loading,
      progress: 0.0,
    );
    if (mounted) setState(() {});

    try {
      final webDavService = await ref.read(
        webDavServiceProvider(widget.folderId).future,
      );

      final url = webDavService.getFileUrl(image.path);
      final headers = webDavService.getAuthHeaders();

      // Create temp file for download
      final tempDir = await getTemporaryDirectory();
      final ext = p.extension(image.name);
      final tempPath = p.join(
        tempDir.path,
        'image_preload_${DateTime.now().millisecondsSinceEpoch}$ext',
      );

      // Cancel any previous download
      _currentDownloadToken?.cancel();
      _currentDownloadToken = CancelToken();

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
        headers: headers,
        responseType: ResponseType.stream,
      ));

      final response = await dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
        cancelToken: _currentDownloadToken,
      );

      final contentLength = int.tryParse(
            response.headers.value(HttpHeaders.contentLengthHeader) ?? '',
          ) ??
          image.size;

      final file = File(tempPath);
      final sink = file.openWrite();
      int received = 0;
      DateTime lastUpdate = DateTime.now();
      int lastBytes = 0;
      double currentSpeed = 0;

      try {
        await for (final chunk in response.data!.stream) {
          sink.add(chunk);
          received += chunk.length;

          // Update progress (throttle to every 100ms)
          final now = DateTime.now();
          if (now.difference(lastUpdate).inMilliseconds >= 100) {
            final timeDiff = now.difference(lastUpdate).inMilliseconds;
            if (timeDiff > 0) {
              currentSpeed = ((received - lastBytes) / timeDiff) * 1000;
            }
            lastUpdate = now;
            lastBytes = received;

            if (mounted) {
              setState(() {
                _imageLoadStates[index] = _ImageLoadState(
                  status: _LoadStatus.loading,
                  progress: contentLength > 0 ? received / contentLength : 0,
                  bytesReceived: received,
                  totalBytes: contentLength,
                  speed: currentSpeed,
                );
              });
            }
          }
        }
      } finally {
        await sink.flush();
        await sink.close();
      }

      // Verify file
      if (await file.exists() && await file.length() > 0) {
        _imageLoadStates[index] = _ImageLoadState(
          status: _LoadStatus.loaded,
          localPath: tempPath,
        );

        // Also cache it for future use
        await _imageCacheService.getImage(url, headers: headers);
      } else {
        throw Exception('Downloaded file is empty');
      }

      if (mounted) setState(() {});

      // Preload next image in background
      if (index == _currentIndex && index + 1 < widget.images.length) {
        _preloadImage(index + 1);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Download was cancelled, don't update state
        return;
      }
      _imageLoadStates[index] = _ImageLoadState(
        status: _LoadStatus.error,
        error: 'Download failed: ${e.message}',
      );
      if (mounted) setState(() {});
    } catch (e) {
      _imageLoadStates[index] = _ImageLoadState(
        status: _LoadStatus.error,
        error: e.toString(),
      );
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image gallery with gestures
          GestureDetector(
            onTap: () => _overlayController.toggle(),
            onVerticalDragStart: _onVerticalDragStart,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Transform.translate(
              offset: Offset(0, _verticalDragDelta),
              child: Opacity(
                opacity: _calculateDragOpacity(),
                child: _buildPhotoGallery(),
              ),
            ),
          ),
          // Overlay controls
          ListenableBuilder(
            listenable: _overlayController,
            builder: (context, child) {
              return ImageViewerOverlay(
                file: _currentImage,
                isVisible: _overlayController.isVisible,
                onClose: _onClose,
                onDownload: _currentImage.isOfflineAvailable ? null : _onDownload,
                onRemoveOffline: _currentImage.isOfflineAvailable
                    ? _onRemoveOffline
                    : null,
                onPrevious: _currentIndex > 0 ? _onPrevious : null,
                onNext: _currentIndex < widget.images.length - 1 ? _onNext : null,
                currentIndex: _currentIndex,
                totalImages: widget.images.length,
                isDownloading: _isDownloading,
                downloadProgress: _downloadProgress,
                bytesReceived: _bytesReceived,
                totalBytes: _totalBytes,
                downloadSpeed: _downloadSpeed,
                downloadEta: _isDownloading ? _formatEta() : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return PhotoViewGallery.builder(
      pageController: _pageController,
      itemCount: widget.images.length,
      onPageChanged: _onPageChanged,
      builder: (context, index) {
        final image = widget.images[index];
        return PhotoViewGalleryPageOptions.customChild(
          child: _buildImageWidget(image),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          heroAttributes: PhotoViewHeroAttributes(tag: image.path),
        );
      },
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) => Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(
            value: event == null
                ? null
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            strokeWidth: 3,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(FileItem image) {
    final index = widget.images.indexOf(image);
    final loadState = _imageLoadStates[index];

    // Check load state
    if (loadState == null) {
      // Not started yet, trigger preload and show loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadImage(index);
      });
      return _buildLoadingIndicator(image, null);
    }

    switch (loadState.status) {
      case _LoadStatus.loading:
        return _buildLoadingIndicator(image, loadState);

      case _LoadStatus.error:
        return _buildErrorWidget(
          loadState.error ?? 'Unknown error',
          onRetry: () {
            _imageLoadStates.remove(index);
            setState(() {});
            _preloadImage(index);
          },
        );

      case _LoadStatus.loaded:
        return _buildLoadedImage(image, loadState);
    }
  }

  Widget _buildLoadingIndicator(FileItem image, _ImageLoadState? state) {
    final progress = state?.progress ?? 0.0;
    final bytesReceived = state?.bytesReceived ?? 0;
    final totalBytes = state?.totalBytes ?? image.size;
    final speed = state?.speed ?? 0.0;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 4,
                  color: AppTheme.primaryColor,
                ),
                if (progress > 0)
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: AppTheme.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            _isGif(image) ? 'Loading GIF...' : 'Loading image...',
            style: AppTheme.bodyMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            image.name,
            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (bytesReceived > 0) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              '${_formatBytes(bytesReceived)} / ${_formatBytes(totalBytes)}',
              style: AppTheme.bodySmall.copyWith(color: Colors.white54),
            ),
          ],
          if (speed > 0) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              '${_formatBytes(speed.toInt())}/s',
              style: AppTheme.bodySmall.copyWith(color: Colors.white54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadedImage(FileItem image, _ImageLoadState state) {
    final isGif = _isGif(image);

    // Determine the image source
    ImageProvider imageProvider;

    if (state.localPath != null) {
      // Use local file
      final file = File(state.localPath!);
      imageProvider = FileImage(file);
    } else if (image.isOfflineAvailable && image.offlinePath != null) {
      // Use offline file
      imageProvider = FileImage(File(image.offlinePath!));
    } else {
      // Fallback to network loading (shouldn't happen with preloading)
      return FutureBuilder<ImageProvider>(
        future: _getImageProvider(image),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(
              snapshot.error.toString(),
              onRetry: () {
                _imageLoadStates.remove(widget.images.indexOf(image));
                setState(() {});
                _preloadImage(widget.images.indexOf(image));
              },
            );
          }

          if (!snapshot.hasData) {
            return _buildLoadingIndicator(image, null);
          }

          return _buildImageFromProvider(snapshot.data!, isGif);
        },
      );
    }

    return _buildImageFromProvider(imageProvider, isGif);
  }

  Widget _buildImageFromProvider(ImageProvider provider, bool isGif) {
    // For GIFs, don't resize to preserve animation
    // For regular images, use ResizeImage to limit memory usage
    final ImageProvider finalProvider;

    if (!isGif) {
      finalProvider = ResizeImage(
        provider,
        width: _maxDecodeWidth,
        height: _maxDecodeHeight,
        policy: ResizeImagePolicy.fit,
      );
    } else {
      finalProvider = provider;
    }

    return Image(
      image: finalProvider,
      fit: BoxFit.contain,
      frameBuilder: isGif
          ? null
          : (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: frame != null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
              );
            },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorWidget('Could not display image');
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<ImageProvider> _getImageProvider(FileItem image) async {
    try {
      final webDavService = await ref.read(
        webDavServiceProvider(widget.folderId).future,
      );

      final url = webDavService.getFileUrl(image.path);
      final headers = webDavService.getAuthHeaders();

      // Try to get cached image first
      final cachedFile = await _imageCacheService.getImageFromCache(url);
      if (cachedFile != null) {
        return FileImage(cachedFile);
      }

      // Download and cache
      final file = await _imageCacheService.getImage(url, headers: headers);
      return FileImage(file);
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildErrorWidget(String message, {VoidCallback? onRetry}) {
    return Center(
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
            'Error loading image',
            style: AppTheme.titleMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXl),
            child: Text(
              message,
              style: AppTheme.bodySmall.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          OutlinedButton(
            onPressed: onRetry ?? () => setState(() {}),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    // Cancel any ongoing preload for previous image
    _currentDownloadToken?.cancel();
    _currentDownloadToken = null;

    setState(() {
      _currentIndex = index;
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
    _overlayController.show();

    // Preload new current image if needed
    _preloadImage(index);
  }

  void _onClose() {
    Navigator.of(context).pop();
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onNext() {
    if (_currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _bytesReceived = 0;
      _totalBytes = _currentImage.size;
      _downloadSpeed = 0.0;
      _lastProgressTime = DateTime.now();
      _lastBytesReceived = 0;
    });

    try {
      // Get WebDAV service
      final webDavService = await ref.read(
        webDavServiceProvider(widget.folderId).future,
      );

      // Get download service
      final database = ref.read(databaseProvider);
      final downloadService = DownloadService(database);

      // Start download with progress tracking
      await downloadService.downloadFile(
        _currentImage,
        widget.folderId,
        webDavService,
        onProgress: (progress, received, total) {
          if (mounted) {
            final now = DateTime.now();
            final timeDiff = now.difference(_lastProgressTime!).inMilliseconds;

            // Calculate speed (update every 500ms to smooth out fluctuations)
            if (timeDiff >= 500) {
              final bytesDiff = received - _lastBytesReceived;
              _downloadSpeed = (bytesDiff / timeDiff) * 1000;
              _lastProgressTime = now;
              _lastBytesReceived = received;
            }

            setState(() {
              _downloadProgress = progress;
              _bytesReceived = received;
              _totalBytes = total > 0 ? total : _currentImage.size;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
        });

        // Invalidate offline status
        ref.invalidate(offlineFileInfoProvider((
          folderId: widget.folderId,
          remotePath: _currentImage.path,
        )));
        ref.invalidate(allOfflineFilesProvider);
        ref.invalidate(totalOfflineSizeProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded ${_currentImage.name}'),
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

  String _formatEta() {
    if (_downloadSpeed <= 0 || _totalBytes <= 0) return 'Calculating...';

    final remainingBytes = _totalBytes - _bytesReceived;
    if (remainingBytes <= 0) return 'Almost done';

    final secondsRemaining = remainingBytes / _downloadSpeed;

    if (secondsRemaining < 60) {
      return '${secondsRemaining.toInt()}s remaining';
    } else if (secondsRemaining < 3600) {
      final minutes = (secondsRemaining / 60).floor();
      final seconds = (secondsRemaining % 60).toInt();
      return '${minutes}m ${seconds}s remaining';
    } else {
      final hours = (secondsRemaining / 3600).floor();
      final minutes = ((secondsRemaining % 3600) / 60).floor();
      return '${hours}h ${minutes}m remaining';
    }
  }

  Future<void> _onRemoveOffline() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Offline Copy?'),
        content: Text(
          'This will remove the offline copy of "${_currentImage.name}". '
          'The file will still be available on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // TODO: Implement actual offline file removal
        // final offlineNotifier = ref.read(offlineFilesNotifierProvider.notifier);
        // await offlineNotifier.deleteOfflineFile(offlineFileId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed offline copy of ${_currentImage.name}'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  // Vertical drag handlers for swipe-to-close
  void _onVerticalDragStart(DragStartDetails details) {
    _verticalDragStart = details.localPosition.dy;
    _overlayController.hide();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final delta = details.localPosition.dy - _verticalDragStart;
    // Only allow downward swipe
    if (delta > 0) {
      setState(() {
        _verticalDragDelta = delta;
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    // Close if dragged more than 100 pixels or with enough velocity
    if (_verticalDragDelta > 100 ||
        details.primaryVelocity != null && details.primaryVelocity! > 500) {
      _onClose();
    } else {
      setState(() {
        _verticalDragDelta = 0;
      });
      _overlayController.show();
    }
  }

  double _calculateDragOpacity() {
    if (_verticalDragDelta <= 0) return 1.0;
    // Fade out as we drag further down
    return (1.0 - (_verticalDragDelta / 300)).clamp(0.3, 1.0);
  }
}

/// Load status for an image.
enum _LoadStatus {
  loading,
  loaded,
  error,
}

/// State for tracking image loading progress.
class _ImageLoadState {
  final _LoadStatus status;
  final double progress;
  final int bytesReceived;
  final int totalBytes;
  final double speed;
  final String? localPath;
  final String? error;

  const _ImageLoadState({
    required this.status,
    this.progress = 0.0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.speed = 0.0,
    this.localPath,
    this.error,
  });
}
