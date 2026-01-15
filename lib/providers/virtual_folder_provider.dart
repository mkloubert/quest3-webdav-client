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

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../models/virtual_folder.dart' as models;
import '../services/credential_service.dart';
import '../services/webdav_service.dart';
import 'credential_provider.dart';
import 'database_provider.dart';

/// Provider for the list of all virtual folders.
///
/// This is a stream provider that watches the database for changes
/// and automatically updates when folders are added, modified, or deleted.
final virtualFoldersProvider =
    StreamProvider<List<models.VirtualFolder>>((ref) {
  final dao = ref.watch(virtualFolderDaoProvider);
  return dao.watchAllFolders().map((folders) {
    return folders
        .map((f) => models.VirtualFolder(
              id: f.id,
              name: f.name,
              serverUrl: f.serverUrl,
              basePath: f.basePath,
              credentialId: f.credentialId,
              iconColor: f.iconColor,
              createdAt: f.createdAt,
              updatedAt: f.updatedAt,
            ))
        .toList();
  });
});

/// Provider for the currently selected virtual folder.
final selectedFolderProvider =
    StateProvider<models.VirtualFolder?>((ref) => null);

/// Provider for the currently selected folder ID.
///
/// This is useful when you only need to track the selected folder's ID
/// without loading the full folder data.
final selectedFolderIdProvider = StateProvider<String?>((ref) => null);

/// Notifier for managing virtual folder CRUD operations.
class VirtualFolderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Nothing to initialize
  }

  /// Creates a new virtual folder.
  ///
  /// [name] - Display name for the folder.
  /// [serverUrl] - WebDAV server URL.
  /// [basePath] - Base path on the server.
  /// [username] - Username for authentication.
  /// [password] - Password for authentication.
  /// [iconColor] - Optional color for the folder icon.
  ///
  /// Returns the ID of the created folder.
  Future<String> createFolder({
    required String name,
    required String serverUrl,
    required String basePath,
    required String username,
    required String password,
    int? iconColor,
  }) async {
    final dao = ref.read(virtualFolderDaoProvider);
    final credentialService = ref.read(credentialServiceProvider);

    // Generate UUIDs
    const uuid = Uuid();
    final folderId = uuid.v4();
    final credentialId = uuid.v4();

    // Save credentials securely
    await credentialService.saveCredentials(credentialId, username, password);

    // Create folder in database
    final now = DateTime.now();
    await dao.insertFolder(VirtualFoldersCompanion.insert(
      id: folderId,
      name: name,
      serverUrl: serverUrl,
      basePath: basePath,
      credentialId: credentialId,
      iconColor: Value(iconColor),
      createdAt: now,
      updatedAt: now,
    ));

    // Invalidate any cached WebDAV service for this folder
    ref.invalidate(webDavServiceProvider(folderId));

    return folderId;
  }

  /// Updates an existing virtual folder.
  ///
  /// [id] - The ID of the folder to update.
  /// [name] - New display name (optional).
  /// [serverUrl] - New server URL (optional).
  /// [basePath] - New base path (optional).
  /// [username] - New username (optional, requires password).
  /// [password] - New password (optional, requires username).
  /// [iconColor] - New icon color (optional).
  Future<void> updateFolder({
    required String id,
    String? name,
    String? serverUrl,
    String? basePath,
    String? username,
    String? password,
    int? iconColor,
  }) async {
    final dao = ref.read(virtualFolderDaoProvider);
    final credentialService = ref.read(credentialServiceProvider);

    // Get existing folder
    final existing = await dao.getFolderById(id);
    if (existing == null) {
      throw Exception('Folder not found: $id');
    }

    // Update credentials if provided
    if (username != null && password != null) {
      await credentialService.saveCredentials(
        existing.credentialId,
        username,
        password,
      );
    }

    // Update folder in database
    await dao.updateFolder(VirtualFoldersCompanion(
      id: Value(id),
      name: Value(name ?? existing.name),
      serverUrl: Value(serverUrl ?? existing.serverUrl),
      basePath: Value(basePath ?? existing.basePath),
      credentialId: Value(existing.credentialId),
      iconColor: Value(iconColor ?? existing.iconColor),
      createdAt: Value(existing.createdAt),
      updatedAt: Value(DateTime.now()),
    ));

    // Invalidate cached WebDAV service for this folder
    ref.invalidate(webDavServiceProvider(id));
  }

  /// Deletes a virtual folder and optionally its offline files.
  ///
  /// [id] - The ID of the folder to delete.
  /// [deleteOfflineFiles] - Whether to delete associated offline files.
  Future<void> deleteFolder(String id, {bool deleteOfflineFiles = true}) async {
    final dao = ref.read(virtualFolderDaoProvider);
    final credentialService = ref.read(credentialServiceProvider);
    final offlineFileDao = ref.read(offlineFileDaoProvider);

    // Get folder to retrieve credential ID
    final folder = await dao.getFolderById(id);
    if (folder == null) return;

    // Delete offline files if requested
    if (deleteOfflineFiles) {
      await offlineFileDao.deleteFilesForFolder(id);
    }

    // Delete credentials
    await credentialService.deleteCredentials(folder.credentialId);

    // Delete folder
    await dao.deleteFolder(id);

    // Clear selection if this folder was selected
    final selectedId = ref.read(selectedFolderIdProvider);
    if (selectedId == id) {
      ref.read(selectedFolderIdProvider.notifier).state = null;
      ref.read(selectedFolderProvider.notifier).state = null;
    }
  }

  /// Tests the connection to a WebDAV server.
  ///
  /// [serverUrl] - The server URL to test.
  /// [basePath] - The base path on the server.
  /// [username] - The username for authentication.
  /// [password] - The password for authentication.
  ///
  /// Returns true if connection is successful.
  Future<bool> testConnection({
    required String serverUrl,
    required String basePath,
    required String username,
    required String password,
  }) async {
    final service = WebDavService.create(
      serverUrl: serverUrl,
      basePath: basePath,
      username: username,
      password: password,
    );
    return service.testConnection();
  }

  /// Gets a folder by ID.
  Future<models.VirtualFolder?> getFolderById(String id) async {
    final dao = ref.read(virtualFolderDaoProvider);
    final folder = await dao.getFolderById(id);
    if (folder == null) return null;

    return models.VirtualFolder(
      id: folder.id,
      name: folder.name,
      serverUrl: folder.serverUrl,
      basePath: folder.basePath,
      credentialId: folder.credentialId,
      iconColor: folder.iconColor,
      createdAt: folder.createdAt,
      updatedAt: folder.updatedAt,
    );
  }
}

/// Provider for the virtual folder notifier.
final virtualFolderNotifierProvider =
    AsyncNotifierProvider<VirtualFolderNotifier, void>(
  VirtualFolderNotifier.new,
);

/// Provider to get a WebDAV service for a specific folder.
///
/// This creates a WebDAV service configured with the folder's credentials.
final webDavServiceProvider =
    FutureProvider.family<WebDavService, String>((ref, folderId) async {
  final dao = ref.watch(virtualFolderDaoProvider);
  final credentialService = ref.watch(credentialServiceProvider);

  final folder = await dao.getFolderById(folderId);
  if (folder == null) {
    throw Exception('Folder not found: $folderId');
  }

  final credentials =
      await credentialService.getCredentials(folder.credentialId);
  if (credentials == null) {
    throw CredentialStorageException(
      'Credentials not found for folder: ${folder.name}',
    );
  }

  return WebDavService.create(
    serverUrl: folder.serverUrl,
    basePath: folder.basePath,
    username: credentials.username,
    password: credentials.password,
  );
});
