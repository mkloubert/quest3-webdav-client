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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/offline_file.dart' as models;
import 'database_provider.dart';

/// State for tracking download progress.
class DownloadProgress {
  /// The remote path of the file being downloaded.
  final String remotePath;

  /// Bytes received so far.
  final int received;

  /// Total bytes to download (-1 if unknown).
  final int total;

  /// Whether the download is complete.
  final bool isComplete;

  /// Error message if download failed.
  final String? error;

  const DownloadProgress({
    required this.remotePath,
    this.received = 0,
    this.total = -1,
    this.isComplete = false,
    this.error,
  });

  /// Returns the progress as a percentage (0.0 to 1.0).
  double get progress {
    if (total <= 0) return 0.0;
    return (received / total).clamp(0.0, 1.0);
  }

  /// Returns the progress as a percentage string.
  String get progressPercent => '${(progress * 100).toStringAsFixed(1)}%';

  DownloadProgress copyWith({
    String? remotePath,
    int? received,
    int? total,
    bool? isComplete,
    String? error,
  }) {
    return DownloadProgress(
      remotePath: remotePath ?? this.remotePath,
      received: received ?? this.received,
      total: total ?? this.total,
      isComplete: isComplete ?? this.isComplete,
      error: error,
    );
  }
}

/// Provider for all offline files.
final allOfflineFilesProvider =
    FutureProvider<List<models.OfflineFile>>((ref) async {
  final dao = ref.watch(offlineFileDaoProvider);
  final files = await dao.getAllFiles();

  return files
      .map((f) => models.OfflineFile(
            id: f.id,
            virtualFolderId: f.virtualFolderId,
            remotePath: f.remotePath,
            localPath: f.localPath,
            fileSize: f.fileSize,
            mimeType: f.mimeType,
            downloadedAt: f.downloadedAt,
          ))
      .toList();
});

/// Provider for offline files for a specific folder.
final offlineFilesForFolderProvider =
    FutureProvider.family<List<models.OfflineFile>, String>(
        (ref, folderId) async {
  final dao = ref.watch(offlineFileDaoProvider);
  final files = await dao.getFilesForFolder(folderId);

  return files
      .map((f) => models.OfflineFile(
            id: f.id,
            virtualFolderId: f.virtualFolderId,
            remotePath: f.remotePath,
            localPath: f.localPath,
            fileSize: f.fileSize,
            mimeType: f.mimeType,
            downloadedAt: f.downloadedAt,
          ))
      .toList();
});

/// Provider for the total size of all offline files.
final totalOfflineSizeProvider = FutureProvider<int>((ref) async {
  final dao = ref.watch(offlineFileDaoProvider);
  return dao.getTotalSize();
});

/// Provider for formatted total offline size.
final formattedOfflineSizeProvider = FutureProvider<String>((ref) async {
  final size = await ref.watch(totalOfflineSizeProvider.future);
  return _formatSize(size);
});

/// Provider for current download progress.
final downloadProgressProvider =
    StateProvider<Map<String, DownloadProgress>>((ref) => {});

/// Notifier for managing offline files.
class OfflineFilesNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Nothing to initialize
  }

  /// Checks if a file is available offline.
  Future<bool> isOfflineAvailable(String folderId, String remotePath) async {
    final dao = ref.read(offlineFileDaoProvider);
    final file = await dao.getFileByRemotePath(folderId, remotePath);
    return file != null;
  }

  /// Gets the local path for an offline file.
  Future<String?> getOfflinePath(String folderId, String remotePath) async {
    final dao = ref.read(offlineFileDaoProvider);
    final file = await dao.getFileByRemotePath(folderId, remotePath);
    return file?.localPath;
  }

  /// Deletes an offline file by ID.
  ///
  /// This only deletes the local file, NOT the remote file.
  Future<void> deleteOfflineFile(String offlineFileId) async {
    final dao = ref.read(offlineFileDaoProvider);

    // Get file info first
    final files = await dao.getAllFiles();
    final file = files.where((f) => f.id == offlineFileId).firstOrNull;

    if (file != null) {
      // Delete local file
      final localFile = File(file.localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }

      // Delete from database
      await dao.deleteFile(offlineFileId);

      // Invalidate providers
      ref.invalidate(allOfflineFilesProvider);
      ref.invalidate(totalOfflineSizeProvider);
      ref.invalidate(offlineFilesForFolderProvider(file.virtualFolderId));
    }
  }

  /// Deletes all offline files for a folder.
  ///
  /// This only deletes local files, NOT remote files.
  Future<void> deleteOfflineFilesForFolder(String folderId) async {
    final dao = ref.read(offlineFileDaoProvider);

    // Get all files for this folder
    final files = await dao.getFilesForFolder(folderId);

    // Delete local files
    for (final file in files) {
      final localFile = File(file.localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }
    }

    // Delete from database
    await dao.deleteFilesForFolder(folderId);

    // Invalidate providers
    ref.invalidate(allOfflineFilesProvider);
    ref.invalidate(totalOfflineSizeProvider);
    ref.invalidate(offlineFilesForFolderProvider(folderId));
  }

  /// Deletes all offline files.
  ///
  /// This only deletes local files, NOT remote files.
  Future<void> deleteAllOfflineFiles() async {
    final dao = ref.read(offlineFileDaoProvider);

    // Get all files
    final files = await dao.getAllFiles();

    // Delete local files
    for (final file in files) {
      final localFile = File(file.localPath);
      if (await localFile.exists()) {
        await localFile.delete();
      }
    }

    // Delete all from database
    final database = ref.read(databaseProvider);
    await database.delete(database.offlineFiles).go();

    // Invalidate providers
    ref.invalidate(allOfflineFilesProvider);
    ref.invalidate(totalOfflineSizeProvider);
  }

  /// Updates download progress for a file.
  void updateProgress(String remotePath, int received, int total) {
    final progressMap = ref.read(downloadProgressProvider);
    ref.read(downloadProgressProvider.notifier).state = {
      ...progressMap,
      remotePath: DownloadProgress(
        remotePath: remotePath,
        received: received,
        total: total,
      ),
    };
  }

  /// Marks a download as complete.
  void completeDownload(String remotePath) {
    final progressMap = ref.read(downloadProgressProvider);
    ref.read(downloadProgressProvider.notifier).state = {
      ...progressMap,
      remotePath: DownloadProgress(
        remotePath: remotePath,
        isComplete: true,
      ),
    };

    // Remove from progress after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      final currentMap = ref.read(downloadProgressProvider);
      final newMap = Map<String, DownloadProgress>.from(currentMap);
      newMap.remove(remotePath);
      ref.read(downloadProgressProvider.notifier).state = newMap;
    });
  }

  /// Marks a download as failed.
  void failDownload(String remotePath, String error) {
    final progressMap = ref.read(downloadProgressProvider);
    ref.read(downloadProgressProvider.notifier).state = {
      ...progressMap,
      remotePath: DownloadProgress(
        remotePath: remotePath,
        error: error,
      ),
    };
  }

  /// Clears download progress for a file.
  void clearProgress(String remotePath) {
    final progressMap = ref.read(downloadProgressProvider);
    final newMap = Map<String, DownloadProgress>.from(progressMap);
    newMap.remove(remotePath);
    ref.read(downloadProgressProvider.notifier).state = newMap;
  }
}

/// Provider for the offline files notifier.
final offlineFilesNotifierProvider =
    AsyncNotifierProvider<OfflineFilesNotifier, void>(
  OfflineFilesNotifier.new,
);

/// Provider to check if a specific file is offline available.
final isFileOfflineProvider =
    FutureProvider.family<bool, ({String folderId, String remotePath})>(
        (ref, params) async {
  final dao = ref.watch(offlineFileDaoProvider);
  final file =
      await dao.getFileByRemotePath(params.folderId, params.remotePath);
  return file != null;
});

/// Provider to get offline file info.
final offlineFileInfoProvider = FutureProvider.family<models.OfflineFile?,
    ({String folderId, String remotePath})>((ref, params) async {
  final dao = ref.watch(offlineFileDaoProvider);
  final file =
      await dao.getFileByRemotePath(params.folderId, params.remotePath);

  if (file == null) return null;

  return models.OfflineFile(
    id: file.id,
    virtualFolderId: file.virtualFolderId,
    remotePath: file.remotePath,
    localPath: file.localPath,
    fileSize: file.fileSize,
    mimeType: file.mimeType,
    downloadedAt: file.downloadedAt,
  );
});

/// Formats a file size in bytes to a human-readable string.
String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
