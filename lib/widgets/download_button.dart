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

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../providers/providers.dart';
import '../services/download_service.dart';

/// A button for downloading files for offline access.
///
/// Shows different states:
/// - Download icon when file is not downloaded
/// - Progress indicator during download
/// - Checkmark when file is available offline
class DownloadButton extends ConsumerStatefulWidget {
  /// The file to download.
  final FileItem file;

  /// The virtual folder ID.
  final String folderId;

  /// Size of the button icon.
  final double iconSize;

  /// Optional callback when download starts.
  final VoidCallback? onDownloadStart;

  /// Optional callback when download completes.
  final VoidCallback? onDownloadComplete;

  /// Optional callback when download fails.
  final void Function(String error)? onDownloadError;

  const DownloadButton({
    super.key,
    required this.file,
    required this.folderId,
    this.iconSize = 24.0,
    this.onDownloadStart,
    this.onDownloadComplete,
    this.onDownloadError,
  });

  @override
  ConsumerState<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends ConsumerState<DownloadButton> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _error;

  @override
  Widget build(BuildContext context) {
    // Check if file is already offline
    final offlineInfoAsync = ref.watch(
      offlineFileInfoProvider((
        folderId: widget.folderId,
        remotePath: widget.file.path,
      )),
    );

    return offlineInfoAsync.when(
      data: (offlineInfo) {
        if (offlineInfo != null) {
          // File is available offline
          return _buildOfflineIndicator();
        }

        if (_isDownloading) {
          return _buildProgressIndicator();
        }

        if (_error != null) {
          return _buildErrorIndicator();
        }

        return _buildDownloadButton();
      },
      loading: () => _buildLoadingIndicator(),
      error: (_, _) => _buildDownloadButton(),
    );
  }

  Widget _buildDownloadButton() {
    return IconButton(
      onPressed: _startDownload,
      icon: Icon(
        Icons.download_rounded,
        size: widget.iconSize,
      ),
      tooltip: 'Download for offline',
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: widget.iconSize + 16,
      height: widget.iconSize + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.iconSize,
            height: widget.iconSize,
            child: CircularProgressIndicator(
              value: _progress > 0 ? _progress : null,
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
          if (_progress > 0)
            Text(
              '${(_progress * 100).toInt()}',
              style: TextStyle(
                fontSize: widget.iconSize * 0.35,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return IconButton(
      onPressed: _showOfflineMenu,
      icon: Icon(
        Icons.offline_pin_rounded,
        size: widget.iconSize,
        color: AppTheme.successColor,
      ),
      tooltip: 'Available offline',
    );
  }

  Widget _buildErrorIndicator() {
    return IconButton(
      onPressed: _startDownload,
      icon: Icon(
        Icons.error_outline_rounded,
        size: widget.iconSize,
        color: AppTheme.errorColor,
      ),
      tooltip: 'Download failed. Tap to retry.',
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: widget.iconSize + 16,
      height: widget.iconSize + 16,
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Future<void> _startDownload() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _error = null;
    });

    widget.onDownloadStart?.call();

    try {
      // Get WebDAV service
      final webDavService = await ref.read(
        webDavServiceProvider(widget.folderId).future,
      );

      // Get download service
      final database = ref.read(databaseProvider);
      final downloadService = DownloadService(database);

      // Start download
      await downloadService.downloadFile(
        widget.file,
        widget.folderId,
        webDavService,
        onProgress: (progress, received, total) {
          if (mounted) {
            setState(() {
              _progress = progress;
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
          remotePath: widget.file.path,
        )));
        ref.invalidate(allOfflineFilesProvider);
        ref.invalidate(totalOfflineSizeProvider);

        widget.onDownloadComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = e.toString();
        });

        widget.onDownloadError?.call(e.toString());
      }
    }
  }

  void _showOfflineMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.successColor),
              title: const Text('Available Offline'),
              subtitle: Text(widget.file.formattedSize),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.errorColor),
              title: const Text('Remove Offline Copy'),
              onTap: () {
                Navigator.of(context).pop();
                _removeOfflineCopy();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeOfflineCopy() async {
    final offlineInfo = await ref.read(
      offlineFileInfoProvider((
        folderId: widget.folderId,
        remotePath: widget.file.path,
      )).future,
    );

    if (offlineInfo != null) {
      await ref
          .read(offlineFilesNotifierProvider.notifier)
          .deleteOfflineFile(offlineInfo.id);

      // Invalidate providers
      ref.invalidate(offlineFileInfoProvider((
        folderId: widget.folderId,
        remotePath: widget.file.path,
      )));
      ref.invalidate(allOfflineFilesProvider);
      ref.invalidate(totalOfflineSizeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline copy removed')),
        );
      }
    }
  }
}

/// A compact download button for use in list items.
class CompactDownloadButton extends ConsumerWidget {
  /// The file to download.
  final FileItem file;

  /// The virtual folder ID.
  final String folderId;

  const CompactDownloadButton({
    super.key,
    required this.file,
    required this.folderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DownloadButton(
      file: file,
      folderId: folderId,
      iconSize: 20.0,
    );
  }
}

/// An inline indicator showing if a file is available offline.
class OfflineIndicator extends ConsumerWidget {
  /// The remote path of the file.
  final String remotePath;

  /// The virtual folder ID.
  final String folderId;

  /// Size of the indicator icon.
  final double size;

  const OfflineIndicator({
    super.key,
    required this.remotePath,
    required this.folderId,
    this.size = 16.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOfflineAsync = ref.watch(
      isFileOfflineProvider((folderId: folderId, remotePath: remotePath)),
    );

    return isOfflineAsync.when(
      data: (isOffline) {
        if (!isOffline) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Icon(
            Icons.offline_pin_rounded,
            size: size,
            color: AppTheme.successColor,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
