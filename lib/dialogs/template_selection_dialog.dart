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

/// A dialog for selecting an existing folder as a template.
///
/// When selected, the server URL and credentials from the template
/// folder can be copied to a new folder.
class TemplateSelectionDialog extends StatelessWidget {
  /// List of available folders to use as templates.
  final List<VirtualFolder> folders;

  const TemplateSelectionDialog({
    super.key,
    required this.folders,
  });

  /// Shows the dialog and returns the selected folder.
  static Future<VirtualFolder?> show(
    BuildContext context, {
    required List<VirtualFolder> folders,
  }) {
    if (folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No existing folders available as templates'),
        ),
      );
      return Future.value(null);
    }

    return showDialog<VirtualFolder>(
      context: context,
      builder: (context) => TemplateSelectionDialog(folders: folders),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Use Template'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a folder to copy its server URL and credentials:',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: folders.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final iconColor = folder.iconColor != null
                      ? Color(folder.iconColor!)
                      : AppTheme.primaryColor;

                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        color: iconColor,
                        size: AppTheme.iconSizeMd,
                      ),
                    ),
                    title: Text(
                      folder.name,
                      style: AppTheme.titleMedium,
                    ),
                    subtitle: Text(
                      _formatServerUrl(folder.serverUrl),
                      style: AppTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.of(context).pop(folder),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

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

/// A bottom sheet for selecting a template or starting fresh.
class TemplateSelectionBottomSheet extends StatelessWidget {
  /// List of available folders to use as templates.
  final List<VirtualFolder> folders;

  /// Callback when a template is selected.
  final ValueChanged<VirtualFolder?>? onSelected;

  const TemplateSelectionBottomSheet({
    super.key,
    required this.folders,
    this.onSelected,
  });

  /// Shows the bottom sheet and returns the selected folder.
  static Future<VirtualFolder?> show(
    BuildContext context, {
    required List<VirtualFolder> folders,
  }) {
    return showModalBottomSheet<VirtualFolder?>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (context) => TemplateSelectionBottomSheet(folders: folders),
    );
  }

  @override
  Widget build(BuildContext context) {
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

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
              ),
              child: Text(
                'Create New Folder',
                style: AppTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
              ),
              child: Text(
                'Start from scratch or use an existing folder as a template',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Start fresh option
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppTheme.primaryColor,
                  size: AppTheme.iconSizeLg,
                ),
              ),
              title: Text(
                'Start Fresh',
                style: AppTheme.titleMedium,
              ),
              subtitle: const Text('Enter all details manually'),
              onTap: () => Navigator.of(context).pop(null),
            ),

            if (folders.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                  vertical: AppTheme.spacingSm,
                ),
                child: Divider(),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Use Template',
                    style: AppTheme.labelLarge.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),

              // Template options
              ...folders.take(5).map((folder) {
                final iconColor = folder.iconColor != null
                    ? Color(folder.iconColor!)
                    : AppTheme.primaryColor;

                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      color: iconColor,
                      size: AppTheme.iconSizeMd,
                    ),
                  ),
                  title: Text(
                    folder.name,
                    style: AppTheme.titleMedium,
                  ),
                  subtitle: Text(
                    _formatServerUrl(folder.serverUrl),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(
                    Icons.copy_rounded,
                    color: AppTheme.textSecondary,
                  ),
                  onTap: () => Navigator.of(context).pop(folder),
                );
              }),

              if (folders.length > 5)
                ListTile(
                  leading: const SizedBox(width: 48),
                  title: Text(
                    'View all ${folders.length} folders...',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  onTap: () async {
                    final selected = await TemplateSelectionDialog.show(
                      context,
                      folders: folders,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(selected);
                    }
                  },
                ),
            ],

            const SizedBox(height: AppTheme.spacingMd),
          ],
        ),
      ),
    );
  }

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
