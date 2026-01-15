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

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../models/file_item.dart';
import '../utils/mime_type_helper.dart';
import 'webdav_service.dart';

/// Callback for tracking download progress.
///
/// [progress] - Download progress from 0.0 to 1.0.
/// [bytesReceived] - Total bytes received so far.
/// [totalBytes] - Total file size in bytes (-1 if unknown).
typedef DownloadProgressCallback = void Function(
  double progress,
  int bytesReceived,
  int totalBytes,
);

/// Status of a download operation.
enum DownloadStatus {
  /// Download is pending, waiting to start.
  pending,

  /// Download is currently in progress.
  inProgress,

  /// Download completed successfully.
  completed,

  /// Download failed with an error.
  failed,

  /// Download was cancelled by the user.
  cancelled,
}

/// Information about a download operation.
class DownloadInfo {
  /// The file being downloaded.
  final FileItem file;

  /// The virtual folder ID.
  final String virtualFolderId;

  /// Current status of the download.
  final DownloadStatus status;

  /// Download progress from 0.0 to 1.0.
  final double progress;

  /// Bytes received so far.
  final int bytesReceived;

  /// Total file size in bytes.
  final int totalBytes;

  /// Error message if download failed.
  final String? errorMessage;

  /// Local path where the file will be saved.
  final String? localPath;

  const DownloadInfo({
    required this.file,
    required this.virtualFolderId,
    this.status = DownloadStatus.pending,
    this.progress = 0.0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.errorMessage,
    this.localPath,
  });

  DownloadInfo copyWith({
    DownloadStatus? status,
    double? progress,
    int? bytesReceived,
    int? totalBytes,
    String? errorMessage,
    String? localPath,
  }) {
    return DownloadInfo(
      file: file,
      virtualFolderId: virtualFolderId,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      localPath: localPath ?? this.localPath,
    );
  }

  /// Returns true if the download is complete or failed.
  bool get isFinished =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.failed ||
      status == DownloadStatus.cancelled;
}

/// Service for downloading files from WebDAV server.
///
/// Manages file downloads with progress tracking, interruption handling,
/// and registration in the offline files database.
class DownloadService {
  final AppDatabase _database;
  final Uuid _uuid = const Uuid();

  /// Active downloads by remote path.
  final Map<String, _DownloadTask> _activeDownloads = {};

  /// Stream controller for download updates.
  final _downloadUpdates = StreamController<DownloadInfo>.broadcast();

  DownloadService(this._database);

  /// Stream of download updates.
  Stream<DownloadInfo> get downloadUpdates => _downloadUpdates.stream;

  /// Returns the number of active downloads.
  int get activeDownloadCount => _activeDownloads.length;

  /// Checks if a file is currently being downloaded.
  bool isDownloading(String remotePath) {
    return _activeDownloads.containsKey(remotePath);
  }

  /// Gets the current download info for a file, if any.
  DownloadInfo? getDownloadInfo(String remotePath) {
    return _activeDownloads[remotePath]?.info;
  }

  /// Downloads a file from the WebDAV server.
  ///
  /// [file] - The file item to download.
  /// [virtualFolderId] - The ID of the virtual folder.
  /// [webDavService] - The WebDAV service to use for downloading.
  /// [onProgress] - Optional callback for progress updates.
  ///
  /// Returns the local path where the file was saved.
  /// Throws an exception if the download fails.
  Future<String> downloadFile(
    FileItem file,
    String virtualFolderId,
    WebDavService webDavService, {
    DownloadProgressCallback? onProgress,
  }) async {
    // Check if already downloading
    if (_activeDownloads.containsKey(file.path)) {
      throw DownloadException('File is already being downloaded: ${file.name}');
    }

    // Check if already downloaded
    final existing = await _database.offlineFileDao.getFileByRemotePath(
      virtualFolderId,
      file.path,
    );
    if (existing != null) {
      // Verify file still exists
      if (File(existing.localPath).existsSync()) {
        return existing.localPath;
      }
      // Clean up stale database entry
      await _database.offlineFileDao.deleteFile(existing.id);
    }

    // Create local file path
    final localPath = await _createLocalPath(virtualFolderId, file.path);

    // Create download task
    final task = _DownloadTask(
      info: DownloadInfo(
        file: file,
        virtualFolderId: virtualFolderId,
        status: DownloadStatus.pending,
        totalBytes: file.size,
        localPath: localPath,
      ),
    );
    _activeDownloads[file.path] = task;

    try {
      // Update status to in progress
      task.info = task.info.copyWith(status: DownloadStatus.inProgress);
      _downloadUpdates.add(task.info);
      onProgress?.call(0.0, 0, file.size);

      // Download the file
      await webDavService.downloadFile(
        file.path,
        localPath,
        onProgress: (received, total) {
          final progress = total > 0 ? received / total : 0.0;
          task.info = task.info.copyWith(
            progress: progress,
            bytesReceived: received,
            totalBytes: total > 0 ? total : file.size,
          );
          _downloadUpdates.add(task.info);
          onProgress?.call(progress, received, total > 0 ? total : file.size);
        },
      );

      // Check if cancelled during download
      if (task.isCancelled) {
        await _cleanupFailedDownload(localPath);
        throw DownloadCancelledException('Download was cancelled: ${file.name}');
      }

      // Verify downloaded file exists and has content
      final downloadedFile = File(localPath);
      if (!downloadedFile.existsSync()) {
        throw DownloadException('Downloaded file not found: ${file.name}');
      }

      final fileSize = await downloadedFile.length();
      if (fileSize == 0) {
        await _cleanupFailedDownload(localPath);
        throw DownloadException('Downloaded file is empty: ${file.name}');
      }

      // Register in database
      final mimeType = file.mimeType ??
          MimeTypeHelper.getMimeTypeFromFileName(file.name);

      await _database.offlineFileDao.insertFile(
        OfflineFilesCompanion(
          id: Value(_uuid.v4()),
          virtualFolderId: Value(virtualFolderId),
          remotePath: Value(file.path),
          localPath: Value(localPath),
          fileSize: Value(fileSize),
          mimeType: Value(mimeType),
          downloadedAt: Value(DateTime.now()),
        ),
      );

      // Update status to completed
      task.info = task.info.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        bytesReceived: fileSize,
        totalBytes: fileSize,
      );
      _downloadUpdates.add(task.info);

      return localPath;
    } catch (e) {
      // Update status to failed
      final errorMessage = e is DownloadCancelledException
          ? 'Cancelled'
          : 'Download failed: ${e.toString()}';
      task.info = task.info.copyWith(
        status: e is DownloadCancelledException
            ? DownloadStatus.cancelled
            : DownloadStatus.failed,
        errorMessage: errorMessage,
      );
      _downloadUpdates.add(task.info);

      // Clean up partial download
      await _cleanupFailedDownload(localPath);

      rethrow;
    } finally {
      _activeDownloads.remove(file.path);
    }
  }

  /// Cancels an active download.
  ///
  /// [remotePath] - The remote path of the file being downloaded.
  /// Returns true if a download was cancelled, false if no active download found.
  bool cancelDownload(String remotePath) {
    final task = _activeDownloads[remotePath];
    if (task == null) return false;

    task.isCancelled = true;
    return true;
  }

  /// Cancels all active downloads.
  void cancelAllDownloads() {
    for (final task in _activeDownloads.values) {
      task.isCancelled = true;
    }
  }

  /// Creates the local file path for storing a downloaded file.
  Future<String> _createLocalPath(
      String virtualFolderId, String remotePath) async {
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory(p.join(appDir.path, 'offline', virtualFolderId));

    // Create directory structure if needed
    if (!offlineDir.existsSync()) {
      await offlineDir.create(recursive: true);
    }

    // Create subdirectories based on remote path
    final relativePath = remotePath.startsWith('/')
        ? remotePath.substring(1)
        : remotePath;
    final localPath = p.join(offlineDir.path, relativePath);

    // Ensure parent directory exists
    final parentDir = Directory(p.dirname(localPath));
    if (!parentDir.existsSync()) {
      await parentDir.create(recursive: true);
    }

    return localPath;
  }

  /// Cleans up a failed or cancelled download.
  Future<void> _cleanupFailedDownload(String localPath) async {
    try {
      final file = File(localPath);
      if (file.existsSync()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore cleanup errors
    }
  }

  /// Closes the download service and releases resources.
  void dispose() {
    cancelAllDownloads();
    _downloadUpdates.close();
  }
}

/// Internal class for tracking download state.
class _DownloadTask {
  DownloadInfo info;
  bool isCancelled = false;

  _DownloadTask({required this.info});
}

/// Exception thrown when a download operation fails.
class DownloadException implements Exception {
  final String message;
  final dynamic cause;

  DownloadException(this.message, {this.cause});

  @override
  String toString() => message;
}

/// Exception thrown when a download is cancelled.
class DownloadCancelledException extends DownloadException {
  DownloadCancelledException(super.message);
}
