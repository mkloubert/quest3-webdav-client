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
import '../dialogs/delete_folder_dialog.dart';
import '../dialogs/template_selection_dialog.dart';
import '../models/virtual_folder.dart';
import '../providers/providers.dart';
import '../widgets/folder_card.dart';
import 'file_browser_screen.dart';
import 'offline_files_screen.dart';
import 'virtual_folder_form_screen.dart';

/// The home screen displaying all virtual folders.
///
/// Shows a grid/list of virtual folders with options to create,
/// edit, and delete folders. Also provides navigation to the
/// file browser when a folder is tapped.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(virtualFoldersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebDAV Folders'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OfflineFilesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.offline_pin_rounded),
            tooltip: 'Offline Files',
          ),
        ],
      ),
      body: foldersAsync.when(
        data: (folders) {
          if (folders.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildFolderList(context, ref, folders);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => _buildErrorState(context, ref, error),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddFolder(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Folder'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
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
                Icons.folder_open_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No Folders Yet',
              style: AppTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Add a virtual folder to connect to your WebDAV server '
              'and browse your files.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton.icon(
              onPressed: () => _onAddFolder(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Your First Folder'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderList(
    BuildContext context,
    WidgetRef ref,
    List<VirtualFolder> folders,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(virtualFoldersProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: AppTheme.spacingSm,
          bottom: 100, // Space for FAB
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return DismissibleFolderCard(
            folder: folder,
            onTap: () => _onFolderTap(context, ref, folder),
            onEdit: () => _onEditFolder(context, ref, folder),
            onDelete: () => _onDeleteFolder(context, ref, folder),
          );
        },
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
              'Error Loading Folders',
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
                ref.invalidate(virtualFoldersProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onAddFolder(BuildContext context, WidgetRef ref) async {
    // Get existing folders for template selection
    final foldersAsync = ref.read(virtualFoldersProvider);
    final folders = foldersAsync.valueOrNull ?? [];

    VirtualFolder? template;

    // Show template selection if there are existing folders
    if (folders.isNotEmpty) {
      template = await TemplateSelectionBottomSheet.show(
        context,
        folders: folders,
      );

      // User cancelled
      if (!context.mounted) return;
    }

    // Navigate to form screen
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VirtualFolderFormScreen(
          templateFolder: template,
        ),
      ),
    );
  }

  void _onFolderTap(BuildContext context, WidgetRef ref, VirtualFolder folder) {
    // Set the selected folder
    ref.read(selectedFolderProvider.notifier).state = folder;
    ref.read(selectedFolderIdProvider.notifier).state = folder.id;

    // Navigate to file browser screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FileBrowserScreen(folder: folder),
      ),
    );
  }

  Future<void> _onEditFolder(
    BuildContext context,
    WidgetRef ref,
    VirtualFolder folder,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VirtualFolderFormScreen(
          editFolder: folder,
        ),
      ),
    );
  }

  Future<void> _onDeleteFolder(
    BuildContext context,
    WidgetRef ref,
    VirtualFolder folder,
  ) async {
    // Check if folder has offline files
    final offlineFiles =
        await ref.read(offlineFilesForFolderProvider(folder.id).future);
    final hasOfflineFiles = offlineFiles.isNotEmpty;

    if (!context.mounted) return;

    final result = await DeleteFolderDialog.show(
      context,
      folder: folder,
      hasOfflineFiles: hasOfflineFiles,
    );

    if (result == null || !result.confirmed) return;

    try {
      await ref.read(virtualFolderNotifierProvider.notifier).deleteFolder(
            folder.id,
            deleteOfflineFiles: result.deleteOfflineFiles,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${folder.name} deleted'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting folder: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
