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

/// Result of the delete folder dialog.
class DeleteFolderResult {
  /// Whether the user confirmed deletion.
  final bool confirmed;

  /// Whether to also delete offline files.
  final bool deleteOfflineFiles;

  const DeleteFolderResult({
    required this.confirmed,
    required this.deleteOfflineFiles,
  });
}

/// A dialog for confirming folder deletion.
///
/// Shows the folder name and allows the user to optionally
/// delete associated offline files.
class DeleteFolderDialog extends StatefulWidget {
  /// The folder to delete.
  final VirtualFolder folder;

  /// Whether this folder has offline files.
  final bool hasOfflineFiles;

  const DeleteFolderDialog({
    super.key,
    required this.folder,
    this.hasOfflineFiles = false,
  });

  /// Shows the dialog and returns the result.
  static Future<DeleteFolderResult?> show(
    BuildContext context, {
    required VirtualFolder folder,
    bool hasOfflineFiles = false,
  }) {
    return showDialog<DeleteFolderResult>(
      context: context,
      builder: (context) => DeleteFolderDialog(
        folder: folder,
        hasOfflineFiles: hasOfflineFiles,
      ),
    );
  }

  @override
  State<DeleteFolderDialog> createState() => _DeleteFolderDialogState();
}

class _DeleteFolderDialogState extends State<DeleteFolderDialog> {
  bool _deleteOfflineFiles = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: AppTheme.bodyLarge,
              children: [
                const TextSpan(text: 'Are you sure you want to delete '),
                TextSpan(
                  text: widget.folder.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            'This will remove the folder configuration and stored credentials. '
            'Files on the server will NOT be affected.',
            style: AppTheme.bodySmall,
          ),
          if (widget.hasOfflineFiles) ...[
            const SizedBox(height: AppTheme.spacingMd),
            CheckboxListTile(
              value: _deleteOfflineFiles,
              onChanged: (value) {
                setState(() {
                  _deleteOfflineFiles = value ?? true;
                });
              },
              title: const Text('Delete offline files'),
              subtitle: const Text(
                'Remove downloaded files from this device',
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(DeleteFolderResult(
              confirmed: true,
              deleteOfflineFiles: _deleteOfflineFiles,
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
