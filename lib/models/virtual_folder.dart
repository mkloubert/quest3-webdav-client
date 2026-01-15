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

/// Represents a virtual folder that connects to a WebDAV server.
///
/// Each virtual folder stores the connection details for a remote WebDAV
/// directory, including server URL, base path, and a reference to securely
/// stored credentials.
class VirtualFolder {
  /// Unique identifier for this folder (UUID).
  final String id;

  /// Display name for this folder.
  final String name;

  /// WebDAV server URL (e.g., "https://cloud.example.com").
  final String serverUrl;

  /// Base path on the remote server (e.g., "/remote.php/dav/files/user").
  final String basePath;

  /// Reference ID to credentials stored in secure storage.
  final String credentialId;

  /// Optional color for the folder icon in UI (as ARGB integer).
  final int? iconColor;

  /// Timestamp when this folder was created.
  final DateTime createdAt;

  /// Timestamp when this folder was last updated.
  final DateTime updatedAt;

  const VirtualFolder({
    required this.id,
    required this.name,
    required this.serverUrl,
    required this.basePath,
    required this.credentialId,
    this.iconColor,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a copy of this folder with the given fields replaced.
  VirtualFolder copyWith({
    String? id,
    String? name,
    String? serverUrl,
    String? basePath,
    String? credentialId,
    int? iconColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VirtualFolder(
      id: id ?? this.id,
      name: name ?? this.name,
      serverUrl: serverUrl ?? this.serverUrl,
      basePath: basePath ?? this.basePath,
      credentialId: credentialId ?? this.credentialId,
      iconColor: iconColor ?? this.iconColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the full WebDAV URL including the base path.
  String get fullUrl {
    final baseUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    final path = basePath.startsWith('/') ? basePath : '/$basePath';
    return '$baseUrl$path';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VirtualFolder && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'VirtualFolder(id: $id, name: $name, serverUrl: $serverUrl)';
  }
}
