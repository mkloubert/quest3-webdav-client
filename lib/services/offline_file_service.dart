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

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../database/database.dart';
import '../models/file_item.dart';

/// Information about an offline file.
class OfflineFileInfo {
  /// The database record.
  final OfflineFile record;

  /// The associated file item.
  final FileItem fileItem;

  /// Whether the local file actually exists.
  final bool localFileExists;

  const OfflineFileInfo({
    required this.record,
    required this.fileItem,
    required this.localFileExists,
  });

  /// Returns the file name.
  String get name => p.basename(record.remotePath);

  /// Returns a human-readable file size.
  String get formattedSize {
    final size = record.fileSize;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Service for managing offline file copies.
///
/// Provides methods to check offline availability, retrieve local paths,
/// delete offline files, and manage storage.
class OfflineFileService {
  final AppDatabase _database;

  OfflineFileService(this._database);

  /// Checks if an offline copy is available for a file.
  ///
  /// [remotePath] - The remote path of the file.
  /// [virtualFolderId] - The ID of the virtual folder.
  /// Returns true if an offline copy exists and the local file is present.
  Future<bool> isOfflineAvailable(
    String remotePath,
    String virtualFolderId,
  ) async {
    final record = await _database.offlineFileDao.getFileByRemotePath(
      virtualFolderId,
      remotePath,
    );
    if (record == null) return false;

    // Verify file still exists on disk
    final file = File(record.localPath);
    if (!file.existsSync()) {
      // Clean up stale database entry
      await _database.offlineFileDao.deleteFile(record.id);
      return false;
    }

    return true;
  }

  /// Gets the local path for an offline file.
  ///
  /// [remotePath] - The remote path of the file.
  /// [virtualFolderId] - The ID of the virtual folder.
  /// Returns the local path if available, null otherwise.
  Future<String?> getOfflinePath(
    String remotePath,
    String virtualFolderId,
  ) async {
    final record = await _database.offlineFileDao.getFileByRemotePath(
      virtualFolderId,
      remotePath,
    );
    if (record == null) return null;

    // Verify file still exists on disk
    final file = File(record.localPath);
    if (!file.existsSync()) {
      // Clean up stale database entry
      await _database.offlineFileDao.deleteFile(record.id);
      return null;
    }

    return record.localPath;
  }

  /// Gets the offline file record if available.
  ///
  /// [remotePath] - The remote path of the file.
  /// [virtualFolderId] - The ID of the virtual folder.
  /// Returns the database record if available, null otherwise.
  Future<OfflineFile?> getOfflineRecord(
    String remotePath,
    String virtualFolderId,
  ) async {
    final record = await _database.offlineFileDao.getFileByRemotePath(
      virtualFolderId,
      remotePath,
    );
    if (record == null) return null;

    // Verify file still exists on disk
    final file = File(record.localPath);
    if (!file.existsSync()) {
      // Clean up stale database entry
      await _database.offlineFileDao.deleteFile(record.id);
      return null;
    }

    return record;
  }

  /// Gets all offline files for a virtual folder.
  ///
  /// [virtualFolderId] - The ID of the virtual folder.
  /// Returns a list of offline file info with verification status.
  Future<List<OfflineFileInfo>> getOfflineFilesForFolder(
    String virtualFolderId,
  ) async {
    final records = await _database.offlineFileDao.getFilesForFolder(
      virtualFolderId,
    );

    final results = <OfflineFileInfo>[];
    for (final record in records) {
      final localFile = File(record.localPath);
      final exists = localFile.existsSync();

      results.add(OfflineFileInfo(
        record: record,
        fileItem: FileItem(
          name: p.basename(record.remotePath),
          path: record.remotePath,
          isDirectory: false,
          size: record.fileSize,
          mimeType: record.mimeType,
          modifiedAt: record.downloadedAt,
          isOfflineAvailable: exists,
          offlinePath: exists ? record.localPath : null,
        ),
        localFileExists: exists,
      ));
    }

    return results;
  }

  /// Gets all offline files across all folders.
  ///
  /// Returns a list of offline file info.
  Future<List<OfflineFileInfo>> getAllOfflineFiles() async {
    final records = await _database.offlineFileDao.getAllFiles();

    final results = <OfflineFileInfo>[];
    for (final record in records) {
      final localFile = File(record.localPath);
      final exists = localFile.existsSync();

      results.add(OfflineFileInfo(
        record: record,
        fileItem: FileItem(
          name: p.basename(record.remotePath),
          path: record.remotePath,
          isDirectory: false,
          size: record.fileSize,
          mimeType: record.mimeType,
          modifiedAt: record.downloadedAt,
          isOfflineAvailable: exists,
          offlinePath: exists ? record.localPath : null,
        ),
        localFileExists: exists,
      ));
    }

    return results;
  }

  /// Gets offline files grouped by virtual folder.
  ///
  /// Returns a map of folder ID to list of offline files.
  Future<Map<String, List<OfflineFileInfo>>> getOfflineFilesGroupedByFolder() async {
    final allFiles = await getAllOfflineFiles();
    final grouped = <String, List<OfflineFileInfo>>{};

    for (final file in allFiles) {
      final folderId = file.record.virtualFolderId;
      grouped.putIfAbsent(folderId, () => []).add(file);
    }

    return grouped;
  }

  /// Deletes an offline file by its ID.
  ///
  /// [offlineFileId] - The ID of the offline file record.
  /// Deletes both the local file and the database record.
  Future<void> deleteOfflineFile(String offlineFileId) async {
    // Get the record first to find the local path
    final records = await _database.offlineFileDao.getAllFiles();
    final record = records.where((r) => r.id == offlineFileId).firstOrNull;

    if (record != null) {
      // Delete local file
      try {
        final localFile = File(record.localPath);
        if (localFile.existsSync()) {
          await localFile.delete();
        }

        // Try to clean up empty parent directories
        await _cleanupEmptyDirectories(record.localPath);
      } catch (_) {
        // Ignore file deletion errors
      }
    }

    // Delete database record
    await _database.offlineFileDao.deleteFile(offlineFileId);
  }

  /// Deletes an offline file by its remote path.
  ///
  /// [remotePath] - The remote path of the file.
  /// [virtualFolderId] - The ID of the virtual folder.
  Future<void> deleteOfflineFileByPath(
    String remotePath,
    String virtualFolderId,
  ) async {
    final record = await _database.offlineFileDao.getFileByRemotePath(
      virtualFolderId,
      remotePath,
    );
    if (record == null) return;

    await deleteOfflineFile(record.id);
  }

  /// Deletes all offline files for a virtual folder.
  ///
  /// [virtualFolderId] - The ID of the virtual folder.
  Future<void> deleteOfflineFilesForFolder(String virtualFolderId) async {
    final records = await _database.offlineFileDao.getFilesForFolder(
      virtualFolderId,
    );

    // Delete local files
    for (final record in records) {
      try {
        final localFile = File(record.localPath);
        if (localFile.existsSync()) {
          await localFile.delete();
        }
      } catch (_) {
        // Ignore individual file deletion errors
      }
    }

    // Delete folder directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final folderDir = Directory(
        p.join(appDir.path, 'offline', virtualFolderId),
      );
      if (folderDir.existsSync()) {
        await folderDir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore directory deletion errors
    }

    // Delete database records
    await _database.offlineFileDao.deleteFilesForFolder(virtualFolderId);
  }

  /// Clears all offline files.
  ///
  /// Deletes all local files and database records.
  Future<void> clearAllOfflineFiles() async {
    final records = await _database.offlineFileDao.getAllFiles();

    // Delete local files
    for (final record in records) {
      try {
        final localFile = File(record.localPath);
        if (localFile.existsSync()) {
          await localFile.delete();
        }
      } catch (_) {
        // Ignore individual file deletion errors
      }
    }

    // Delete offline directory
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final offlineDir = Directory(p.join(appDir.path, 'offline'));
      if (offlineDir.existsSync()) {
        await offlineDir.delete(recursive: true);
      }
    } catch (_) {
      // Ignore directory deletion errors
    }

    // Delete all database records
    for (final record in records) {
      await _database.offlineFileDao.deleteFile(record.id);
    }
  }

  /// Gets the total size of all offline files in bytes.
  Future<int> getTotalOfflineSize() async {
    return await _database.offlineFileDao.getTotalSize();
  }

  /// Gets the total size of offline files for a folder in bytes.
  Future<int> getOfflineSizeForFolder(String virtualFolderId) async {
    final records = await _database.offlineFileDao.getFilesForFolder(
      virtualFolderId,
    );
    return records.fold<int>(0, (sum, record) => sum + record.fileSize);
  }

  /// Returns a formatted string of the total offline storage used.
  Future<String> getFormattedTotalSize() async {
    final size = await getTotalOfflineSize();
    return _formatSize(size);
  }

  /// Cleans up stale database entries where local files no longer exist.
  Future<int> cleanupStaleEntries() async {
    final records = await _database.offlineFileDao.getAllFiles();
    int cleaned = 0;

    for (final record in records) {
      final localFile = File(record.localPath);
      if (!localFile.existsSync()) {
        await _database.offlineFileDao.deleteFile(record.id);
        cleaned++;
      }
    }

    return cleaned;
  }

  /// Enriches a list of file items with offline availability info.
  ///
  /// [files] - The list of file items to enrich.
  /// [virtualFolderId] - The ID of the virtual folder.
  /// Returns a new list with isOfflineAvailable and offlinePath set.
  Future<List<FileItem>> enrichWithOfflineInfo(
    List<FileItem> files,
    String virtualFolderId,
  ) async {
    final offlineRecords = await _database.offlineFileDao.getFilesForFolder(
      virtualFolderId,
    );

    // Create a map for quick lookup
    final offlineMap = <String, OfflineFile>{};
    for (final record in offlineRecords) {
      offlineMap[record.remotePath] = record;
    }

    return files.map((file) {
      final record = offlineMap[file.path];
      if (record == null) return file;

      // Verify file still exists
      final localFile = File(record.localPath);
      if (!localFile.existsSync()) {
        // Mark for cleanup but don't block
        _database.offlineFileDao.deleteFile(record.id);
        return file;
      }

      return file.copyWith(
        isOfflineAvailable: true,
        offlinePath: record.localPath,
      );
    }).toList();
  }

  /// Cleans up empty parent directories after file deletion.
  Future<void> _cleanupEmptyDirectories(String filePath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final offlineDir = p.join(appDir.path, 'offline');

      var dir = Directory(p.dirname(filePath));
      while (dir.path.startsWith(offlineDir) && dir.path != offlineDir) {
        final contents = dir.listSync();
        if (contents.isEmpty) {
          await dir.delete();
          dir = dir.parent;
        } else {
          break;
        }
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }

  /// Formats a size in bytes to a human-readable string.
  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
