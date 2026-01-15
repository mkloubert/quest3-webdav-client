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

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../utils/mime_type_helper.dart';

/// A list item widget for displaying a file or directory.
///
/// Shows file icon, name, size, modification date, and offline status.
class FileListItem extends StatelessWidget {
  /// The file item to display.
  final FileItem file;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Callback when the item is long pressed.
  final VoidCallback? onLongPress;

  /// Callback when the download button is pressed.
  final VoidCallback? onDownload;

  const FileListItem({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      leading: _buildIcon(),
      title: Text(
        file.name,
        style: AppTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(),
      trailing: _buildTrailing(),
    );
  }

  Widget _buildIcon() {
    final (icon, color) = _getIconAndColor();

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              color: color,
              size: AppTheme.iconSizeMd,
            ),
          ),
          if (file.isOfflineAvailable)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.offline_pin_rounded,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildSubtitle() {
    if (file.isDirectory) {
      return null;
    }

    final parts = <String>[];

    // File size
    if (file.size > 0) {
      parts.add(file.formattedSize);
    }

    // Modified date
    if (file.modifiedAt != null) {
      parts.add(_formatDate(file.modifiedAt!));
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' • '),
      style: AppTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildTrailing() {
    if (file.isDirectory) {
      return const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textSecondary,
      );
    }

    // Show download button for media files
    if (_isMediaFile() && !file.isOfflineAvailable && onDownload != null) {
      return IconButton(
        onPressed: onDownload,
        icon: const Icon(Icons.download_rounded),
        tooltip: 'Download for offline',
        color: AppTheme.textSecondary,
      );
    }

    return null;
  }

  (IconData, Color) _getIconAndColor() {
    if (file.isDirectory) {
      return (Icons.folder_rounded, AppTheme.primaryColor);
    }

    final mimeType = file.mimeType;
    final extension = file.extension;

    // Images
    if (MimeTypeHelper.isImage(mimeType) ||
        MimeTypeHelper.isImageExtension(extension)) {
      return (Icons.image_rounded, const Color(0xFF22C55E));
    }

    // Videos
    if (MimeTypeHelper.isVideo(mimeType) ||
        MimeTypeHelper.isVideoExtension(extension)) {
      return (Icons.movie_rounded, const Color(0xFFF59E0B));
    }

    // Audio
    if (MimeTypeHelper.isAudio(mimeType)) {
      return (Icons.audiotrack_rounded, const Color(0xFF8B5CF6));
    }

    // Documents
    if (mimeType?.contains('pdf') == true || extension == 'pdf') {
      return (Icons.picture_as_pdf_rounded, const Color(0xFFEF4444));
    }

    if (mimeType?.startsWith('text/') == true ||
        ['txt', 'md', 'json', 'xml', 'html', 'css', 'js'].contains(extension)) {
      return (Icons.description_rounded, const Color(0xFF3B82F6));
    }

    // Archives
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(extension)) {
      return (Icons.archive_rounded, const Color(0xFF64748B));
    }

    // Default
    return (Icons.insert_drive_file_rounded, AppTheme.textSecondary);
  }

  bool _isMediaFile() {
    return MimeTypeHelper.isImage(file.mimeType) ||
        MimeTypeHelper.isVideo(file.mimeType) ||
        MimeTypeHelper.isImageExtension(file.extension) ||
        MimeTypeHelper.isVideoExtension(file.extension);
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
