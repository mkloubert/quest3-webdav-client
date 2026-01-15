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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../models/virtual_folder.dart';
import '../providers/providers.dart';
import '../utils/mime_type_helper.dart';
import '../widgets/breadcrumb_navigation.dart';
import '../widgets/empty_directory.dart';
import '../widgets/file_grid_item.dart';
import '../widgets/file_list_item.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';

/// View mode for file display.
enum FileViewMode {
  list,
  grid,
}

/// Screen for browsing files in a virtual folder.
///
/// Displays files in either list or grid view with navigation
/// support via breadcrumbs and back button. Handles loading,
/// error, and empty states appropriately.
class FileBrowserScreen extends ConsumerStatefulWidget {
  /// The folder to browse.
  final VirtualFolder folder;

  const FileBrowserScreen({
    super.key,
    required this.folder,
  });

  @override
  ConsumerState<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends ConsumerState<FileBrowserScreen> {
  FileViewMode _viewMode = FileViewMode.list;
  FileFilterType _filterType = FileFilterType.all;

  @override
  void initState() {
    super.initState();
    // Open the folder when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fileBrowserProvider.notifier).openFolder(widget.folder.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final browserState = ref.watch(fileBrowserProvider);
    final canGoBack = browserState.canGoBack;

    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && canGoBack) {
          _onBackPressed();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _onBackOrClose,
            icon: Icon(
              canGoBack ? Icons.arrow_back_rounded : Icons.close_rounded,
            ),
            tooltip: canGoBack ? 'Go back' : 'Close',
          ),
          title: Text(widget.folder.name),
          actions: [
            // Filter dropdown
            PopupMenuButton<FileFilterType>(
              icon: const Icon(Icons.filter_list_rounded),
              tooltip: 'Filter files',
              onSelected: (type) {
                setState(() {
                  _filterType = type;
                });
              },
              itemBuilder: (context) => [
                _buildFilterMenuItem(FileFilterType.all, 'All Files'),
                _buildFilterMenuItem(FileFilterType.images, 'Images'),
                _buildFilterMenuItem(FileFilterType.videos, 'Videos'),
                _buildFilterMenuItem(FileFilterType.media, 'Media'),
                _buildFilterMenuItem(FileFilterType.offline, 'Offline'),
              ],
            ),
            // View mode toggle
            IconButton(
              onPressed: _toggleViewMode,
              icon: Icon(
                _viewMode == FileViewMode.list
                    ? Icons.grid_view_rounded
                    : Icons.view_list_rounded,
              ),
              tooltip: _viewMode == FileViewMode.list
                  ? 'Switch to grid view'
                  : 'Switch to list view',
            ),
            // Refresh button
            IconButton(
              onPressed: browserState.isLoading
                  ? null
                  : () => ref.read(fileBrowserProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Column(
          children: [
            // Breadcrumb navigation
            BreadcrumbNavigation(
              segments: browserState.breadcrumbs,
              onSegmentTap: (index) {
                ref.read(fileBrowserProvider.notifier).navigateToBreadcrumb(index);
              },
            ),
            // File list
            Expanded(
              child: _buildContent(browserState),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<FileFilterType> _buildFilterMenuItem(
    FileFilterType type,
    String label,
  ) {
    return PopupMenuItem(
      value: type,
      child: Row(
        children: [
          if (_filterType == type)
            const Padding(
              padding: EdgeInsets.only(right: AppTheme.spacingSm),
              child: Icon(Icons.check_rounded, size: 20),
            )
          else
            const SizedBox(width: 20 + AppTheme.spacingSm),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildContent(FileBrowserState browserState) {
    // Loading state
    if (browserState.isLoading) {
      return const DirectoryLoading(
        message: 'Loading directory...',
      );
    }

    // Error state
    if (browserState.error != null) {
      return DirectoryError(
        error: browserState.error!,
        onRetry: () => ref.read(fileBrowserProvider.notifier).refresh(),
      );
    }

    // Get filtered files
    final files = ref.watch(filteredFilesProvider(_filterType));

    // Empty state
    if (files.isEmpty) {
      return EmptyDirectory(
        isRoot: browserState.currentPath == '/',
        onAction: () => ref.read(fileBrowserProvider.notifier).refresh(),
        actionLabel: 'Refresh',
      );
    }

    // File list/grid
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(fileBrowserProvider.notifier).refresh();
      },
      child: _viewMode == FileViewMode.list
          ? _buildListView(files)
          : _buildGridView(files),
    );
  }

  Widget _buildListView(List<FileItem> files) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      itemCount: files.length,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: AppTheme.spacingMd + 48 + AppTheme.spacingMd,
      ),
      itemBuilder: (context, index) {
        final file = files[index];
        return FileListItem(
          file: file,
          onTap: () => _onFileTap(file),
          onLongPress: () => _onFileLongPress(file),
          onDownload: file.isDirectory ? null : () => _onDownload(file),
        );
      },
    );
  }

  Widget _buildGridView(List<FileItem> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: AppTheme.spacingMd,
        crossAxisSpacing: AppTheme.spacingMd,
        childAspectRatio: 0.85,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return FileGridItem(
          file: file,
          onTap: () => _onFileTap(file),
          onLongPress: () => _onFileLongPress(file),
        );
      },
    );
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == FileViewMode.list
          ? FileViewMode.grid
          : FileViewMode.list;
    });
  }

  void _onBackPressed() {
    ref.read(fileBrowserProvider.notifier).goBack();
  }

  void _onBackOrClose() {
    final canGoBack = ref.read(fileBrowserProvider).canGoBack;
    if (canGoBack) {
      _onBackPressed();
    } else {
      _closeScreen();
    }
  }

  void _closeScreen() {
    ref.read(fileBrowserProvider.notifier).closeFolder();
    ref.read(selectedFolderProvider.notifier).state = null;
    ref.read(selectedFolderIdProvider.notifier).state = null;
    Navigator.of(context).pop();
  }

  void _onFileTap(FileItem file) {
    if (file.isDirectory) {
      ref.read(fileBrowserProvider.notifier).navigateTo(file.path);
    } else if (_isImageFile(file)) {
      _openImageViewer(file);
    } else if (_isVideoFile(file)) {
      _openVideoPlayer(file);
    } else {
      _showFileInfo(file);
    }
  }

  bool _isImageFile(FileItem file) {
    return MimeTypeHelper.isImage(file.mimeType) ||
        MimeTypeHelper.isImageExtension(file.extension);
  }

  bool _isVideoFile(FileItem file) {
    return MimeTypeHelper.isVideo(file.mimeType) ||
        MimeTypeHelper.isVideoExtension(file.extension);
  }

  void _openVideoPlayer(FileItem file) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(
          file: file,
          folderId: widget.folder.id,
        ),
      ),
    );
  }

  void _openImageViewer(FileItem file) {
    // Get all image files from the current directory for navigation
    final allFiles = ref.read(fileListProvider);
    final imageFiles = allFiles
        .where((f) => !f.isDirectory && _isImageFile(f))
        .toList();

    final initialIndex = imageFiles.indexWhere((f) => f.path == file.path);
    if (initialIndex == -1) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImageViewerScreen(
          images: imageFiles,
          initialIndex: initialIndex,
          folderId: widget.folder.id,
        ),
      ),
    );
  }

  void _onFileLongPress(FileItem file) {
    _showFileOptions(file);
  }

  void _onDownload(FileItem file) {
    // TODO: Implement download with progress tracking
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${file.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFileInfo(FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Type', file.isDirectory ? 'Folder' : 'File'),
            if (!file.isDirectory) ...[
              _buildInfoRow('Size', file.formattedSize),
              if (file.mimeType != null)
                _buildInfoRow('MIME Type', file.mimeType!),
            ],
            _buildInfoRow('Path', file.path),
            if (file.modifiedAt != null)
              _buildInfoRow(
                'Modified',
                _formatDateTime(file.modifiedAt!),
              ),
            if (file.isOfflineAvailable)
              _buildInfoRow('Offline', 'Available'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showFileOptions(FileItem file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('File Info'),
              onTap: () {
                Navigator.of(context).pop();
                _showFileInfo(file);
              },
            ),
            if (!file.isDirectory && !file.isOfflineAvailable)
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Download for Offline'),
                onTap: () {
                  Navigator.of(context).pop();
                  _onDownload(file);
                },
              ),
            if (file.isOfflineAvailable)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Remove Offline Copy'),
                onTap: () {
                  Navigator.of(context).pop();
                  _removeOfflineCopy(file);
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Path'),
              onTap: () {
                Navigator.of(context).pop();
                _copyPath(file);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeOfflineCopy(FileItem file) {
    // TODO: Implement offline file removal
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removing offline copy of ${file.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyPath(FileItem file) {
    Clipboard.setData(ClipboardData(text: file.path));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Path copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
