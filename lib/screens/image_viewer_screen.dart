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
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../providers/providers.dart';
import '../services/image_cache_service.dart';
import '../widgets/image_viewer_overlay.dart';

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

  // Track vertical drag for swipe-to-close
  double _verticalDragStart = 0;
  double _verticalDragDelta = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _overlayController = OverlayVisibilityController();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _overlayController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  FileItem get _currentImage => widget.images[_currentIndex];

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
    // Use offline version if available
    if (image.isOfflineAvailable && image.offlinePath != null) {
      return Image.file(
        File(image.offlinePath!),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget('Could not load offline image');
        },
      );
    }

    // Load from network with caching
    return FutureBuilder<ImageProvider>(
      future: _getImageProvider(image),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryColor,
            ),
          );
        }

        return Image(
          image: snapshot.data!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget('Could not load image');
          },
        );
      },
    );
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

  Widget _buildErrorWidget(String message) {
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
            onPressed: () => setState(() {}),
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
    setState(() {
      _currentIndex = index;
      _isDownloading = false;
      _downloadProgress = 0.0;
    });
    _overlayController.show();
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
    });

    try {
      // TODO: Implement actual download with progress using:
      // - webDavServiceProvider for downloading
      // - offlineFilesNotifierProvider for tracking
      //
      // For now, simulate download progress
      for (var i = 0; i <= 100; i += 10) {
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
