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

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import '../models/file_item.dart';
import '../models/webdav_exception.dart';
import '../utils/mime_type_helper.dart';

/// Callback for tracking download progress.
///
/// [received] - Bytes received so far.
/// [total] - Total bytes to receive (-1 if unknown).
typedef ProgressCallback = void Function(int received, int total);

/// Service for WebDAV server communication.
///
/// Provides methods for connecting to WebDAV servers, listing directories,
/// downloading files, and checking file existence.
class WebDavService {
  /// Connection timeout duration.
  static const Duration connectionTimeout = Duration(seconds: 10);

  /// Read timeout duration.
  static const Duration readTimeout = Duration(seconds: 30);

  /// Download timeout duration for large files.
  static const Duration downloadTimeout = Duration(minutes: 10);

  /// The WebDAV client instance.
  final webdav.Client _client;

  /// The base URL of the WebDAV server.
  final String serverUrl;

  /// The base path on the server.
  final String basePath;

  /// The username for authentication.
  final String _username;

  /// The password for authentication.
  final String _password;

  WebDavService._({
    required webdav.Client client,
    required this.serverUrl,
    required this.basePath,
    required String username,
    required String password,
  })  : _client = client,
        _username = username,
        _password = password;

  /// Creates a new WebDAV service instance.
  ///
  /// [serverUrl] - The WebDAV server URL (e.g., "https://cloud.example.com").
  /// [basePath] - The base path on the server (e.g., "/remote.php/dav/files/user").
  /// [username] - The username for authentication.
  /// [password] - The password for authentication.
  factory WebDavService.create({
    required String serverUrl,
    required String basePath,
    required String username,
    required String password,
  }) {
    // Normalize URLs
    final normalizedServerUrl = serverUrl.endsWith('/')
        ? serverUrl.substring(0, serverUrl.length - 1)
        : serverUrl;
    final normalizedBasePath =
        basePath.startsWith('/') ? basePath : '/$basePath';

    final fullUrl = '$normalizedServerUrl$normalizedBasePath';

    final client = webdav.newClient(
      fullUrl,
      user: username,
      password: password,
      debug: false,
    );

    // Configure timeouts
    client.setConnectTimeout(connectionTimeout.inMilliseconds);
    client.setSendTimeout(readTimeout.inMilliseconds);
    client.setReceiveTimeout(readTimeout.inMilliseconds);

    return WebDavService._(
      client: client,
      serverUrl: normalizedServerUrl,
      basePath: normalizedBasePath,
      username: username,
      password: password,
    );
  }

  /// Returns the full WebDAV URL.
  String get fullUrl => '$serverUrl$basePath';

  /// Tests the connection to the WebDAV server.
  ///
  /// Returns true if the connection is successful.
  /// Throws appropriate [WebDavException] on failure.
  Future<bool> testConnection() async {
    try {
      await _client.ping();
      return true;
    } on DioException catch (e) {
      throw _handleDioException(e, 'Connection test failed');
    } catch (e) {
      throw WebDavConnectionException(
        'Connection test failed: ${e.toString()}',
        cause: e,
      );
    }
  }

  /// Lists the contents of a directory.
  ///
  /// [path] - The path relative to the base path. Use "/" for root.
  /// Returns a list of [FileItem] objects.
  /// Throws [WebDavException] on failure.
  Future<List<FileItem>> listDirectory(String path) async {
    try {
      final normalizedPath = _normalizePath(path);
      final files = await _client.readDir(normalizedPath);

      return files
          .map((file) => _convertToFileItem(file, normalizedPath))
          .toList()
        ..sort((a, b) {
          // Directories first, then by name
          if (a.isDirectory != b.isDirectory) {
            return a.isDirectory ? -1 : 1;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to list directory: $path');
    } catch (e) {
      throw WebDavConnectionException(
        'Failed to list directory: $path',
        cause: e,
      );
    }
  }

  /// Gets information about a specific file or directory.
  ///
  /// [path] - The path relative to the base path.
  /// Returns a [FileItem] with the file information.
  /// Throws [WebDavNotFoundException] if the file does not exist.
  /// Throws [WebDavException] on other failures.
  Future<FileItem> getFileInfo(String path) async {
    try {
      final normalizedPath = _normalizePath(path);
      final parentPath = _getParentPath(normalizedPath);
      final fileName = _getFileName(normalizedPath);

      final files = await _client.readDir(parentPath);
      final file = files.firstWhere(
        (f) => f.name == fileName,
        orElse: () => throw WebDavNotFoundException(
          'File not found: $path',
          path: path,
          statusCode: 404,
        ),
      );

      return _convertToFileItem(file, parentPath);
    } on WebDavNotFoundException {
      rethrow;
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to get file info: $path');
    } catch (e) {
      if (e is WebDavException) rethrow;
      throw WebDavConnectionException(
        'Failed to get file info: $path',
        cause: e,
      );
    }
  }

  /// Downloads a file from the server.
  ///
  /// [remotePath] - The path of the file on the server.
  /// [localPath] - The local file path to save to.
  /// [onProgress] - Optional callback for download progress.
  /// Throws [WebDavException] on failure.
  Future<void> downloadFile(
    String remotePath,
    String localPath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      final normalizedPath = _normalizePath(remotePath);
      final fileUrl = getFileUrl(normalizedPath);

      // Create parent directory if needed
      final localFile = File(localPath);
      await localFile.parent.create(recursive: true);

      // Use Dio directly for better control over timeouts and progress
      final dio = Dio(BaseOptions(
        connectTimeout: connectionTimeout,
        receiveTimeout: downloadTimeout,
        headers: getAuthHeaders(),
        responseType: ResponseType.stream,
      ));

      final response = await dio.get<ResponseBody>(
        fileUrl,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );

      final contentLength = int.tryParse(
            response.headers.value(HttpHeaders.contentLengthHeader) ?? '',
          ) ??
          -1;

      // Write to file with progress tracking
      final sink = localFile.openWrite();
      int received = 0;

      try {
        await for (final chunk in response.data!.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, contentLength);
        }
      } finally {
        await sink.flush();
        await sink.close();
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'Failed to download file: $remotePath');
    } catch (e) {
      if (e is WebDavException) rethrow;
      throw WebDavFileException(
        'Failed to download file: $remotePath',
        filePath: remotePath,
        cause: e,
      );
    }
  }

  /// Checks if a file exists on the server.
  ///
  /// [path] - The path to check.
  /// Returns true if the file exists.
  Future<bool> fileExists(String path) async {
    try {
      await getFileInfo(path);
      return true;
    } on WebDavNotFoundException {
      return false;
    }
  }

  /// Returns the authentication headers for direct HTTP requests.
  ///
  /// Useful for streaming video content directly via HTTP.
  Map<String, String> getAuthHeaders() {
    final credentials = base64Encode(utf8.encode('$_username:$_password'));
    return {
      'Authorization': 'Basic $credentials',
    };
  }

  /// Returns the full URL for a file path.
  ///
  /// [path] - The relative path on the server.
  /// Returns the complete URL including server and base path.
  String getFileUrl(String path) {
    final normalizedPath = _normalizePath(path);
    return '$fullUrl$normalizedPath';
  }

  /// Normalizes a path by ensuring it starts with a slash.
  String _normalizePath(String path) {
    if (path.isEmpty || path == '/') return '/';
    final normalized = path.startsWith('/') ? path : '/$path';
    return normalized.endsWith('/') && normalized.length > 1
        ? normalized.substring(0, normalized.length - 1)
        : normalized;
  }

  /// Gets the parent path of a given path.
  String _getParentPath(String path) {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return '/';
    return path.substring(0, lastSlash);
  }

  /// Gets the file name from a path.
  String _getFileName(String path) {
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash == -1) return path;
    return path.substring(lastSlash + 1);
  }

  /// Converts a webdav.File to a FileItem.
  FileItem _convertToFileItem(webdav.File file, String parentPath) {
    final isDir = file.isDir ?? false;
    final name = file.name ?? '';
    final path = parentPath == '/' ? '/$name' : '$parentPath/$name';

    String? mimeType;
    if (!isDir && file.mimeType != null) {
      mimeType = file.mimeType;
    } else if (!isDir) {
      mimeType = MimeTypeHelper.getMimeTypeFromFileName(name);
    }

    return FileItem(
      name: name,
      path: path,
      isDirectory: isDir,
      size: file.size ?? 0,
      mimeType: mimeType,
      modifiedAt: file.mTime,
    );
  }

  /// Handles DioException and converts to appropriate WebDavException.
  WebDavException _handleDioException(DioException e, String message) {
    final statusCode = e.response?.statusCode;

    // Check for timeout
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return WebDavTimeoutException(
        message,
        cause: e,
      );
    }

    // Check for connection errors
    if (e.type == DioExceptionType.connectionError) {
      return WebDavConnectionException(
        message,
        cause: e,
      );
    }

    // Handle HTTP status codes
    if (statusCode != null) {
      if (statusCode == 401 || statusCode == 403) {
        return WebDavAuthException(
          message,
          cause: e,
          statusCode: statusCode,
        );
      }
      if (statusCode == 404) {
        return WebDavNotFoundException(
          message,
          cause: e,
          statusCode: statusCode,
        );
      }
      if (statusCode >= 500) {
        return WebDavServerException(
          message,
          cause: e,
          statusCode: statusCode,
        );
      }
    }

    return WebDavConnectionException(
      message,
      cause: e,
      statusCode: statusCode,
    );
  }
}
