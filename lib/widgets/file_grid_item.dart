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

import '../constants/app_theme.dart';
import '../models/file_item.dart';
import '../utils/mime_type_helper.dart';

/// A grid item widget for displaying a file or directory.
///
/// Shows thumbnail preview for images (if cached), folder icon for directories,
/// and file type icons for other files.
class FileGridItem extends StatelessWidget {
  /// The file item to display.
  final FileItem file;

  /// Callback when the item is tapped.
  final VoidCallback? onTap;

  /// Callback when the item is long pressed.
  final VoidCallback? onLongPress;

  const FileGridItem({
    super.key,
    required this.file,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail/Icon area
            Expanded(
              child: _buildThumbnail(),
            ),
            // File name
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: AppTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!file.isDirectory && file.size > 0)
                    Text(
                      file.formattedSize,
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // Check if we have a cached image to show
    if (file.isOfflineAvailable &&
        file.offlinePath != null &&
        _isImageFile()) {
      return _buildImageThumbnail(file.offlinePath!);
    }

    // Show icon
    return _buildIconThumbnail();
  }

  Widget _buildImageThumbnail(String localPath) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusMd),
          ),
          child: Image.file(
            File(localPath),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildIconThumbnail();
            },
          ),
        ),
        // Offline indicator
        Positioned(
          right: AppTheme.spacingSm,
          top: AppTheme.spacingSm,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.successColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Icon(
              Icons.offline_pin_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconThumbnail() {
    final (icon, color) = _getIconAndColor();

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusMd),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              color: color,
              size: AppTheme.iconSizeXl,
            ),
          ),
          if (file.isOfflineAvailable)
            Positioned(
              right: AppTheme.spacingSm,
              top: AppTheme.spacingSm,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: const Icon(
                  Icons.offline_pin_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isImageFile() {
    return MimeTypeHelper.isImage(file.mimeType) ||
        MimeTypeHelper.isImageExtension(file.extension);
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
}
