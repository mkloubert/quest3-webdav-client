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

/// Represents a file or directory item from a WebDAV server.
///
/// This class is used to display directory contents in the file browser
/// and to track whether offline copies are available.
class FileItem {
  /// Display name of the file or directory.
  final String name;

  /// Full remote path on the WebDAV server.
  final String path;

  /// True if this item is a directory, false if it is a file.
  final bool isDirectory;

  /// File size in bytes (0 for directories).
  final int size;

  /// MIME type of the file (null for directories).
  final String? mimeType;

  /// Last modification date on the server.
  final DateTime? modifiedAt;

  /// True if an offline copy of this file is available locally.
  final bool isOfflineAvailable;

  /// Local file path if offline copy exists.
  final String? offlinePath;

  const FileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size = 0,
    this.mimeType,
    this.modifiedAt,
    this.isOfflineAvailable = false,
    this.offlinePath,
  });

  /// Creates a copy of this item with the given fields replaced.
  FileItem copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    int? size,
    String? mimeType,
    DateTime? modifiedAt,
    bool? isOfflineAvailable,
    String? offlinePath,
  }) {
    return FileItem(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isOfflineAvailable: isOfflineAvailable ?? this.isOfflineAvailable,
      offlinePath: offlinePath ?? this.offlinePath,
    );
  }

  /// Returns the file extension without the leading dot.
  String? get extension {
    if (isDirectory) return null;
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == name.length - 1) return null;
    return name.substring(lastDot + 1).toLowerCase();
  }

  /// Returns the parent directory path.
  String get parentPath {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return '/';
    return path.substring(0, lastSlash);
  }

  /// Returns a human-readable file size string.
  String get formattedSize {
    if (isDirectory) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileItem && other.path == path;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() {
    return 'FileItem(name: $name, path: $path, isDirectory: $isDirectory)';
  }
}
