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
import '../models/virtual_folder.dart';

/// A card widget displaying a virtual folder.
///
/// Shows the folder name, server URL, and an icon with customizable color.
/// Supports tap, long press, and provides visual feedback.
class FolderCard extends StatelessWidget {
  /// The virtual folder to display.
  final VirtualFolder folder;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the card is long pressed.
  final VoidCallback? onLongPress;

  /// Callback when the edit button is pressed.
  final VoidCallback? onEdit;

  /// Callback when the delete button is pressed.
  final VoidCallback? onDelete;

  /// Whether to show action buttons.
  final bool showActions;

  const FolderCard({
    super.key,
    required this.folder,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = folder.iconColor != null
        ? Color(folder.iconColor!)
        : AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            children: [
              // Folder icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: iconColor,
                  size: AppTheme.iconSizeLg,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),

              // Folder info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: AppTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      _formatServerUrl(folder.serverUrl),
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Action buttons or arrow
              if (showActions) ...[
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                  tooltip: 'Edit',
                  iconSize: AppTheme.iconSizeMd,
                  color: AppTheme.textSecondary,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_rounded),
                  tooltip: 'Delete',
                  iconSize: AppTheme.iconSizeMd,
                  color: AppTheme.errorColor,
                ),
              ] else ...[
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                  size: AppTheme.iconSizeMd,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Formats the server URL for display (removes protocol, truncates if long).
  String _formatServerUrl(String url) {
    var formatted = url
        .replaceFirst('https://', '')
        .replaceFirst('http://', '');

    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }

    return formatted;
  }
}

/// A dismissible version of FolderCard that supports swipe actions.
class DismissibleFolderCard extends StatelessWidget {
  /// The virtual folder to display.
  final VirtualFolder folder;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when swiped to edit.
  final VoidCallback? onEdit;

  /// Callback when swiped to delete.
  final VoidCallback? onDelete;

  const DismissibleFolderCard({
    super.key,
    required this.folder,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(folder.id),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppTheme.primaryColor,
        icon: Icons.edit_rounded,
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: AppTheme.errorColor,
        icon: Icons.delete_rounded,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onEdit?.call();
          return false;
        } else if (direction == DismissDirection.endToStart) {
          onDelete?.call();
          return false;
        }
        return false;
      },
      child: FolderCard(
        folder: folder,
        onTap: onTap,
        onLongPress: () {
          // Show actions on long press
          _showActionsBottomSheet(context);
        },
      ),
    );
  }

  Widget _buildSwipeBackground({
    required AlignmentGeometry alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Icon(
        icon,
        color: AppTheme.textPrimary,
        size: AppTheme.iconSizeLg,
      ),
    );
  }

  void _showActionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),

                // Folder name
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
                  child: Text(
                    folder.name,
                    style: AppTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                const Divider(),

                // Edit option
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit?.call();
                  },
                ),

                // Delete option
                ListTile(
                  leading: Icon(
                    Icons.delete_rounded,
                    color: AppTheme.errorColor,
                  ),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
