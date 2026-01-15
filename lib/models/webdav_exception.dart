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

/// Base exception for all WebDAV-related errors.
abstract class WebDavException implements Exception {
  /// Description of the error.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  /// HTTP status code, if applicable.
  final int? statusCode;

  const WebDavException(this.message, {this.cause, this.statusCode});

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType: $message');
    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }
    if (cause != null) {
      buffer.write(' [caused by: $cause]');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a connection to the WebDAV server fails.
///
/// This includes network errors, DNS resolution failures, and timeouts.
class WebDavConnectionException extends WebDavException {
  const WebDavConnectionException(
    super.message, {
    super.cause,
    super.statusCode,
  });
}

/// Exception thrown when authentication with the WebDAV server fails.
///
/// This typically occurs when the username or password is incorrect,
/// or when the user lacks permission to access the resource.
class WebDavAuthException extends WebDavException {
  const WebDavAuthException(
    super.message, {
    super.cause,
    super.statusCode,
  });
}

/// Exception thrown when a requested resource is not found on the server.
///
/// This corresponds to HTTP 404 errors.
class WebDavNotFoundException extends WebDavException {
  /// The path that was not found.
  final String? path;

  const WebDavNotFoundException(
    super.message, {
    this.path,
    super.cause,
    super.statusCode,
  });

  @override
  String toString() {
    final buffer = StringBuffer('WebDavNotFoundException: $message');
    if (path != null) {
      buffer.write(' (path: $path)');
    }
    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }
    if (cause != null) {
      buffer.write(' [caused by: $cause]');
    }
    return buffer.toString();
  }
}

/// Exception thrown when the server returns an unexpected error.
///
/// This is used for HTTP 5xx errors and other server-side issues.
class WebDavServerException extends WebDavException {
  const WebDavServerException(
    super.message, {
    super.cause,
    super.statusCode,
  });
}

/// Exception thrown when a WebDAV operation times out.
class WebDavTimeoutException extends WebDavException {
  /// The timeout duration that was exceeded.
  final Duration? timeout;

  const WebDavTimeoutException(
    super.message, {
    this.timeout,
    super.cause,
  });

  @override
  String toString() {
    final buffer = StringBuffer('WebDavTimeoutException: $message');
    if (timeout != null) {
      buffer.write(' (timeout: ${timeout!.inSeconds}s)');
    }
    if (cause != null) {
      buffer.write(' [caused by: $cause]');
    }
    return buffer.toString();
  }
}

/// Exception thrown when a file operation fails.
///
/// This includes download failures, permission issues, and disk errors.
class WebDavFileException extends WebDavException {
  /// The file path involved in the operation.
  final String? filePath;

  const WebDavFileException(
    super.message, {
    this.filePath,
    super.cause,
    super.statusCode,
  });

  @override
  String toString() {
    final buffer = StringBuffer('WebDavFileException: $message');
    if (filePath != null) {
      buffer.write(' (file: $filePath)');
    }
    if (statusCode != null) {
      buffer.write(' (HTTP $statusCode)');
    }
    if (cause != null) {
      buffer.write(' [caused by: $cause]');
    }
    return buffer.toString();
  }
}
