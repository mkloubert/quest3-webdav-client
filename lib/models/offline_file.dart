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

/// Represents a file that has been downloaded for offline access.
///
/// This class tracks locally stored copies of remote files, allowing
/// the app to play media without network access and to manage storage.
class OfflineFile {
  /// Unique identifier for this offline file record (UUID).
  final String id;

  /// Reference to the virtual folder this file belongs to.
  final String virtualFolderId;

  /// Full remote path on the WebDAV server.
  final String remotePath;

  /// Local file system path where the file is stored.
  final String localPath;

  /// File size in bytes.
  final int fileSize;

  /// MIME type of the file.
  final String mimeType;

  /// Timestamp when the file was downloaded.
  final DateTime downloadedAt;

  const OfflineFile({
    required this.id,
    required this.virtualFolderId,
    required this.remotePath,
    required this.localPath,
    required this.fileSize,
    required this.mimeType,
    required this.downloadedAt,
  });

  /// Creates a copy of this offline file with the given fields replaced.
  OfflineFile copyWith({
    String? id,
    String? virtualFolderId,
    String? remotePath,
    String? localPath,
    int? fileSize,
    String? mimeType,
    DateTime? downloadedAt,
  }) {
    return OfflineFile(
      id: id ?? this.id,
      virtualFolderId: virtualFolderId ?? this.virtualFolderId,
      remotePath: remotePath ?? this.remotePath,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  /// Returns the file name from the remote path.
  String get fileName {
    final lastSlash = remotePath.lastIndexOf('/');
    if (lastSlash == -1) return remotePath;
    return remotePath.substring(lastSlash + 1);
  }

  /// Returns a human-readable file size string.
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineFile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OfflineFile(id: $id, remotePath: $remotePath, localPath: $localPath)';
  }
}
