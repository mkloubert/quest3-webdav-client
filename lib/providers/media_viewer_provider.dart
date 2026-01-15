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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/file_item.dart';
import '../services/media_type_detector.dart';
import '../utils/mime_type_helper.dart';

/// State for the current media being viewed.
class MediaViewerState {
  /// The file item being viewed.
  final FileItem? currentMedia;

  /// The folder ID containing the media.
  final String? folderId;

  /// The current viewer mode.
  final ViewerMode viewerMode;

  /// All media files in the current directory (for navigation).
  final List<FileItem> mediaFiles;

  /// The index of the current media in the mediaFiles list.
  final int currentIndex;

  /// Whether the UI overlay is visible.
  final bool isOverlayVisible;

  /// Whether the viewer is in fullscreen mode.
  final bool isFullscreen;

  const MediaViewerState({
    this.currentMedia,
    this.folderId,
    this.viewerMode = ViewerMode.normal,
    this.mediaFiles = const [],
    this.currentIndex = 0,
    this.isOverlayVisible = true,
    this.isFullscreen = true,
  });

  MediaViewerState copyWith({
    FileItem? currentMedia,
    String? folderId,
    ViewerMode? viewerMode,
    List<FileItem>? mediaFiles,
    int? currentIndex,
    bool? isOverlayVisible,
    bool? isFullscreen,
  }) {
    return MediaViewerState(
      currentMedia: currentMedia ?? this.currentMedia,
      folderId: folderId ?? this.folderId,
      viewerMode: viewerMode ?? this.viewerMode,
      mediaFiles: mediaFiles ?? this.mediaFiles,
      currentIndex: currentIndex ?? this.currentIndex,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isFullscreen: isFullscreen ?? this.isFullscreen,
    );
  }

  /// Returns true if there's a previous media file.
  bool get hasPrevious => currentIndex > 0;

  /// Returns true if there's a next media file.
  bool get hasNext => currentIndex < mediaFiles.length - 1;

  /// Returns true if the current media is an image.
  bool get isImage {
    if (currentMedia == null) return false;
    return MimeTypeHelper.isImage(currentMedia!.mimeType) ||
        MimeTypeHelper.isImageExtension(currentMedia!.extension);
  }

  /// Returns true if the current media is a video.
  bool get isVideo {
    if (currentMedia == null) return false;
    return MimeTypeHelper.isVideo(currentMedia!.mimeType) ||
        MimeTypeHelper.isVideoExtension(currentMedia!.extension);
  }
}

/// Notifier for media viewer state.
class MediaViewerNotifier extends StateNotifier<MediaViewerState> {
  MediaViewerNotifier() : super(const MediaViewerState());

  /// Opens a media file for viewing.
  ///
  /// [file] - The file to view.
  /// [folderId] - The folder ID containing the file.
  /// [allFiles] - All files in the directory for navigation.
  void openMedia(FileItem file, String folderId, List<FileItem> allFiles) {
    // Filter to only media files
    final mediaFiles = allFiles
        .where((f) =>
            !f.isDirectory &&
            (MimeTypeHelper.isImage(f.mimeType) ||
                MimeTypeHelper.isVideo(f.mimeType) ||
                MimeTypeHelper.isImageExtension(f.extension) ||
                MimeTypeHelper.isVideoExtension(f.extension)))
        .toList();

    // Find current file index
    final currentIndex = mediaFiles.indexWhere((f) => f.path == file.path);

    // Detect if this might be a 360° video
    ViewerMode initialMode = ViewerMode.normal;
    if (_is360Video(file)) {
      initialMode = ViewerMode.panorama360;
    }

    state = MediaViewerState(
      currentMedia: file,
      folderId: folderId,
      viewerMode: initialMode,
      mediaFiles: mediaFiles,
      currentIndex: currentIndex >= 0 ? currentIndex : 0,
      isOverlayVisible: true,
      isFullscreen: true,
    );
  }

  /// Navigates to the previous media file.
  void previousMedia() {
    if (!state.hasPrevious) return;

    final newIndex = state.currentIndex - 1;
    final newMedia = state.mediaFiles[newIndex];

    state = state.copyWith(
      currentMedia: newMedia,
      currentIndex: newIndex,
      viewerMode: _is360Video(newMedia) ? ViewerMode.panorama360 : ViewerMode.normal,
    );
  }

  /// Navigates to the next media file.
  void nextMedia() {
    if (!state.hasNext) return;

    final newIndex = state.currentIndex + 1;
    final newMedia = state.mediaFiles[newIndex];

    state = state.copyWith(
      currentMedia: newMedia,
      currentIndex: newIndex,
      viewerMode: _is360Video(newMedia) ? ViewerMode.panorama360 : ViewerMode.normal,
    );
  }

  /// Sets the viewer mode.
  void setViewerMode(ViewerMode mode) {
    state = state.copyWith(viewerMode: mode);
  }

  /// Toggles the UI overlay visibility.
  void toggleOverlay() {
    state = state.copyWith(isOverlayVisible: !state.isOverlayVisible);
  }

  /// Shows the UI overlay.
  void showOverlay() {
    state = state.copyWith(isOverlayVisible: true);
  }

  /// Hides the UI overlay.
  void hideOverlay() {
    state = state.copyWith(isOverlayVisible: false);
  }

  /// Toggles fullscreen mode.
  void toggleFullscreen() {
    state = state.copyWith(isFullscreen: !state.isFullscreen);
  }

  /// Closes the media viewer.
  void closeViewer() {
    state = const MediaViewerState();
  }

  /// Detects if a file is likely a 360° video based on naming patterns.
  bool _is360Video(FileItem file) {
    final name = file.name.toLowerCase();
    return name.contains('360') ||
        name.contains('vr') ||
        name.contains('spherical') ||
        name.contains('equirectangular');
  }
}

/// Provider for media viewer state.
final mediaViewerProvider =
    StateNotifierProvider<MediaViewerNotifier, MediaViewerState>((ref) {
  return MediaViewerNotifier();
});

/// Provider for the currently viewed media.
final currentMediaProvider = Provider<FileItem?>((ref) {
  return ref.watch(mediaViewerProvider).currentMedia;
});

/// Provider for the current viewer mode.
final viewerModeProvider = Provider<ViewerMode>((ref) {
  return ref.watch(mediaViewerProvider).viewerMode;
});

/// Provider for overlay visibility.
final isOverlayVisibleProvider = Provider<bool>((ref) {
  return ref.watch(mediaViewerProvider).isOverlayVisible;
});

/// Provider for whether the current media is an image.
final isCurrentMediaImageProvider = Provider<bool>((ref) {
  return ref.watch(mediaViewerProvider).isImage;
});

/// Provider for whether the current media is a video.
final isCurrentMediaVideoProvider = Provider<bool>((ref) {
  return ref.watch(mediaViewerProvider).isVideo;
});

/// Provider for navigation availability.
final canNavigateMediaProvider =
    Provider<({bool hasPrevious, bool hasNext})>((ref) {
  final state = ref.watch(mediaViewerProvider);
  return (hasPrevious: state.hasPrevious, hasNext: state.hasNext);
});
