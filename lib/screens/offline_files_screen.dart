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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../constants/app_theme.dart';
import '../models/offline_file.dart' as models;
import '../models/virtual_folder.dart';
import '../providers/providers.dart';
import '../utils/mime_type_helper.dart';

/// Screen for managing offline files.
///
/// Displays all downloaded files grouped by virtual folder,
/// with options to delete individual files or clear all.
class OfflineFilesScreen extends ConsumerWidget {
  const OfflineFilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineFilesAsync = ref.watch(allOfflineFilesProvider);
    final totalSizeAsync = ref.watch(formattedOfflineSizeProvider);
    final foldersAsync = ref.watch(virtualFoldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Files'),
        actions: [
          // Total size indicator
          totalSizeAsync.when(
            data: (size) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storage_rounded,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        size,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          // Clear all button
          offlineFilesAsync.when(
            data: (files) => files.isNotEmpty
                ? IconButton(
                    onPressed: () => _showClearAllDialog(context, ref),
                    icon: const Icon(Icons.delete_sweep_rounded),
                    tooltip: 'Clear All',
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: offlineFilesAsync.when(
        data: (files) {
          if (files.isEmpty) {
            return _buildEmptyState(context);
          }

          // Group files by folder
          return foldersAsync.when(
            data: (folders) => _buildFileList(context, ref, files, folders),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(context, ref, error),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No Offline Files',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Download files from your WebDAV folders '
              'to access them without internet connection.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Error Loading Files',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              error.toString(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(allOfflineFilesProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileList(
    BuildContext context,
    WidgetRef ref,
    List<models.OfflineFile> files,
    List<VirtualFolder> folders,
  ) {
    // Group files by folder
    final groupedFiles = <String, List<models.OfflineFile>>{};
    for (final file in files) {
      groupedFiles.putIfAbsent(file.virtualFolderId, () => []).add(file);
    }

    // Create folder lookup map
    final folderMap = {for (final f in folders) f.id: f};

    // Sort folder IDs by folder name
    final sortedFolderIds = groupedFiles.keys.toList()
      ..sort((a, b) {
        final folderA = folderMap[a];
        final folderB = folderMap[b];
        if (folderA == null && folderB == null) return 0;
        if (folderA == null) return 1;
        if (folderB == null) return -1;
        return folderA.name.toLowerCase().compareTo(folderB.name.toLowerCase());
      });

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allOfflineFilesProvider);
        ref.invalidate(totalOfflineSizeProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppTheme.spacingSm,
          bottom: AppTheme.spacingLg,
        ),
        itemCount: sortedFolderIds.length,
        itemBuilder: (context, index) {
          final folderId = sortedFolderIds[index];
          final folder = folderMap[folderId];
          final folderFiles = groupedFiles[folderId]!;

          return _buildFolderSection(
            context,
            ref,
            folder,
            folderId,
            folderFiles,
          );
        },
      ),
    );
  }

  Widget _buildFolderSection(
    BuildContext context,
    WidgetRef ref,
    VirtualFolder? folder,
    String folderId,
    List<models.OfflineFile> files,
  ) {
    // Calculate total size for this folder
    final totalSize = files.fold<int>(0, (sum, f) => sum + f.fileSize);
    final formattedSize = _formatSize(totalSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Folder header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: folder?.iconColor != null
                      ? Color(folder!.iconColor!).withValues(alpha: 0.15)
                      : AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: folder?.iconColor != null
                      ? Color(folder!.iconColor!)
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder?.name ?? 'Unknown Folder',
                      style: AppTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${files.length} ${files.length == 1 ? 'file' : 'files'} · $formattedSize',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Delete folder offline files
              IconButton(
                onPressed: () => _showDeleteFolderFilesDialog(
                  context,
                  ref,
                  folder,
                  folderId,
                ),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete all files in this folder',
              ),
            ],
          ),
        ),
        // File list
        ...files.map((file) => _buildFileItem(context, ref, file)),
        const Divider(height: AppTheme.spacingLg),
      ],
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    WidgetRef ref,
    models.OfflineFile file,
  ) {
    final fileName = p.basename(file.remotePath);
    final extension = p.extension(fileName).toLowerCase().replaceFirst('.', '');
    final isImage = MimeTypeHelper.isImageExtension(extension);
    final isVideo = MimeTypeHelper.isVideoExtension(extension);

    IconData iconData;
    Color iconColor;
    if (isImage) {
      iconData = Icons.image_rounded;
      iconColor = Colors.green;
    } else if (isVideo) {
      iconData = Icons.video_file_rounded;
      iconColor = Colors.red;
    } else {
      iconData = Icons.insert_drive_file_rounded;
      iconColor = AppTheme.textSecondary;
    }

    return Dismissible(
      key: Key(file.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacingMd),
        color: AppTheme.errorColor,
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteFileDialog(context, fileName);
      },
      onDismissed: (direction) {
        _deleteFile(ref, file);
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            iconData,
            color: iconColor,
          ),
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              _formatSize(file.fileSize),
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              '·',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              _formatDate(file.downloadedAt),
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () async {
            final confirmed = await _showDeleteFileDialog(context, fileName);
            if (confirmed == true) {
              _deleteFile(ref, file);
            }
          },
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Delete',
        ),
      ),
    );
  }

  Future<bool?> _showDeleteFileDialog(BuildContext context, String fileName) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offline File?'),
        content: Text(
          'Delete the local copy of "$fileName"?\n\n'
          'The file will remain on the server.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteFolderFilesDialog(
    BuildContext context,
    WidgetRef ref,
    VirtualFolder? folder,
    String folderId,
  ) async {
    final folderName = folder?.name ?? 'this folder';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Files?'),
        content: Text(
          'Delete all offline files from "$folderName"?\n\n'
          'The files will remain on the server.',
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
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(offlineFilesNotifierProvider.notifier)
          .deleteOfflineFilesForFolder(folderId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline files deleted')),
        );
      }
    }
  }

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Offline Files?'),
        content: const Text(
          'This will delete all downloaded files from your device.\n\n'
          'The files will remain on the server.',
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
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(offlineFilesNotifierProvider.notifier)
          .deleteAllOfflineFiles();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All offline files deleted')),
        );
      }
    }
  }

  void _deleteFile(WidgetRef ref, models.OfflineFile file) {
    ref.read(offlineFilesNotifierProvider.notifier).deleteOfflineFile(file.id);
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
