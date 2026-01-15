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
import 'database_provider.dart';
import 'virtual_folder_provider.dart';

/// State for file browser navigation.
class FileBrowserState {
  /// The current folder ID being browsed.
  final String? folderId;

  /// The current path within the folder.
  final String currentPath;

  /// The navigation history stack for back navigation.
  final List<String> history;

  /// Whether the file list is currently loading.
  final bool isLoading;

  /// Error message if loading failed.
  final String? error;

  /// The current directory contents.
  final List<FileItem> files;

  const FileBrowserState({
    this.folderId,
    this.currentPath = '/',
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.files = const [],
  });

  FileBrowserState copyWith({
    String? folderId,
    String? currentPath,
    List<String>? history,
    bool? isLoading,
    String? error,
    List<FileItem>? files,
  }) {
    return FileBrowserState(
      folderId: folderId ?? this.folderId,
      currentPath: currentPath ?? this.currentPath,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      files: files ?? this.files,
    );
  }

  /// Returns true if we can navigate back.
  bool get canGoBack => history.isNotEmpty;

  /// Returns the breadcrumb segments for the current path.
  List<String> get breadcrumbs {
    if (currentPath == '/') return ['/'];
    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();
    return ['/', ...segments];
  }

  /// Returns the path for a specific breadcrumb index.
  String pathAtBreadcrumb(int index) {
    if (index == 0) return '/';
    final segments = breadcrumbs.skip(1).take(index).toList();
    return '/${segments.join('/')}';
  }
}

/// Notifier for file browser state management.
class FileBrowserNotifier extends StateNotifier<FileBrowserState> {
  final Ref _ref;

  FileBrowserNotifier(this._ref) : super(const FileBrowserState());

  /// Opens a folder and loads its root directory.
  Future<void> openFolder(String folderId) async {
    state = FileBrowserState(
      folderId: folderId,
      currentPath: '/',
      history: [],
      isLoading: true,
    );

    await _loadCurrentDirectory();
  }

  /// Navigates to a directory within the current folder.
  Future<void> navigateTo(String path) async {
    if (state.folderId == null) return;

    // Add current path to history before navigating
    final newHistory = [...state.history, state.currentPath];

    state = state.copyWith(
      currentPath: path,
      history: newHistory,
      isLoading: true,
      error: null,
    );

    await _loadCurrentDirectory();
  }

  /// Navigates to a breadcrumb path.
  Future<void> navigateToBreadcrumb(int index) async {
    final path = state.pathAtBreadcrumb(index);
    if (path == state.currentPath) return;

    // Clear history after the target breadcrumb
    final newHistory = <String>[];
    for (var i = 0; i < index && i < state.history.length; i++) {
      newHistory.add(state.history[i]);
    }

    state = state.copyWith(
      currentPath: path,
      history: newHistory,
      isLoading: true,
      error: null,
    );

    await _loadCurrentDirectory();
  }

  /// Navigates back to the previous directory.
  Future<void> goBack() async {
    if (!state.canGoBack) return;

    final newHistory = [...state.history];
    final previousPath = newHistory.removeLast();

    state = state.copyWith(
      currentPath: previousPath,
      history: newHistory,
      isLoading: true,
      error: null,
    );

    await _loadCurrentDirectory();
  }

  /// Refreshes the current directory listing.
  Future<void> refresh() async {
    if (state.folderId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    await _loadCurrentDirectory();
  }

  /// Loads the current directory contents.
  Future<void> _loadCurrentDirectory() async {
    if (state.folderId == null) {
      state = state.copyWith(
        isLoading: false,
        error: 'No folder selected',
        files: [],
      );
      return;
    }

    try {
      final webDavService =
          await _ref.read(webDavServiceProvider(state.folderId!).future);
      final offlineFileDao = _ref.read(offlineFileDaoProvider);

      // Fetch directory contents
      final files = await webDavService.listDirectory(state.currentPath);

      // Check offline availability for each file
      final filesWithOfflineStatus = await Future.wait(
        files.map((file) async {
          if (file.isDirectory) return file;

          final offlineFile = await offlineFileDao.getFileByRemotePath(
            state.folderId!,
            file.path,
          );

          if (offlineFile != null) {
            return file.copyWith(
              isOfflineAvailable: true,
              offlinePath: offlineFile.localPath,
            );
          }
          return file;
        }),
      );

      state = state.copyWith(
        isLoading: false,
        error: null,
        files: filesWithOfflineStatus,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        files: [],
      );
    }
  }

  /// Closes the current folder browser session.
  void closeFolder() {
    state = const FileBrowserState();
  }
}

/// Provider for the file browser state.
final fileBrowserProvider =
    StateNotifierProvider<FileBrowserNotifier, FileBrowserState>((ref) {
  return FileBrowserNotifier(ref);
});

/// Provider for the current path within the file browser.
final currentPathProvider = Provider<String>((ref) {
  return ref.watch(fileBrowserProvider).currentPath;
});

/// Provider for whether we can navigate back.
final canGoBackProvider = Provider<bool>((ref) {
  return ref.watch(fileBrowserProvider).canGoBack;
});

/// Provider for the current file list.
final fileListProvider = Provider<List<FileItem>>((ref) {
  return ref.watch(fileBrowserProvider).files;
});

/// Provider for file browser loading state.
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(fileBrowserProvider).isLoading;
});

/// Provider for file browser error state.
final fileBrowserErrorProvider = Provider<String?>((ref) {
  return ref.watch(fileBrowserProvider).error;
});

/// Provider for breadcrumb segments.
final breadcrumbsProvider = Provider<List<String>>((ref) {
  return ref.watch(fileBrowserProvider).breadcrumbs;
});

/// Provider to filter files by type.
final filteredFilesProvider =
    Provider.family<List<FileItem>, FileFilterType>((ref, filterType) {
  final files = ref.watch(fileListProvider);

  switch (filterType) {
    case FileFilterType.all:
      return files;
    case FileFilterType.images:
      return files.where((f) => f.isDirectory || _isImage(f)).toList();
    case FileFilterType.videos:
      return files.where((f) => f.isDirectory || _isVideo(f)).toList();
    case FileFilterType.media:
      return files
          .where((f) => f.isDirectory || _isImage(f) || _isVideo(f))
          .toList();
    case FileFilterType.offline:
      return files.where((f) => f.isDirectory || f.isOfflineAvailable).toList();
  }
});

/// Filter types for file listing.
enum FileFilterType {
  all,
  images,
  videos,
  media,
  offline,
}

bool _isImage(FileItem file) {
  if (file.mimeType?.startsWith('image/') == true) return true;
  final ext = file.extension?.toLowerCase();
  return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif']
      .contains(ext);
}

bool _isVideo(FileItem file) {
  if (file.mimeType?.startsWith('video/') == true) return true;
  final ext = file.extension?.toLowerCase();
  return ['mp4', 'mkv', 'webm', 'mov', 'avi', 'm4v', '3gp', 'ts'].contains(ext);
}
