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

/// Supported image file extensions.
const Set<String> supportedImageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'heic',
  'heif',
};

/// Supported video file extensions.
const Set<String> supportedVideoExtensions = {
  'mp4',
  'mkv',
  'webm',
  'mov',
  'avi',
  'm4v',
  '3gp',
  'ts',
};

/// Image MIME type prefixes.
const Set<String> imageMimeTypes = {
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
  'image/bmp',
  'image/heic',
  'image/heif',
};

/// Video MIME type prefixes.
const Set<String> videoMimeTypes = {
  'video/mp4',
  'video/x-matroska',
  'video/webm',
  'video/quicktime',
  'video/x-msvideo',
  'video/avi',
  'video/x-m4v',
  'video/3gpp',
  'video/mp2t',
};

/// Helper class for MIME type detection and media file identification.
class MimeTypeHelper {
  MimeTypeHelper._();

  /// Maps file extensions to MIME types.
  static const Map<String, String> _extensionToMimeType = {
    // Images
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'bmp': 'image/bmp',
    'heic': 'image/heic',
    'heif': 'image/heif',
    // Videos
    'mp4': 'video/mp4',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'm4v': 'video/x-m4v',
    '3gp': 'video/3gpp',
    'ts': 'video/mp2t',
    // Audio
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'flac': 'audio/flac',
    'aac': 'audio/aac',
    'ogg': 'audio/ogg',
    'm4a': 'audio/mp4',
    // Documents
    'pdf': 'application/pdf',
    'txt': 'text/plain',
    'json': 'application/json',
    'xml': 'application/xml',
    'html': 'text/html',
    'htm': 'text/html',
    // Archives
    'zip': 'application/zip',
    'rar': 'application/x-rar-compressed',
    '7z': 'application/x-7z-compressed',
    'tar': 'application/x-tar',
    'gz': 'application/gzip',
  };

  /// Returns the MIME type for a given file extension.
  ///
  /// [extension] - The file extension without the leading dot.
  /// Returns the MIME type string or 'application/octet-stream' if unknown.
  static String getMimeType(String extension) {
    final ext = extension.toLowerCase();
    return _extensionToMimeType[ext] ?? 'application/octet-stream';
  }

  /// Returns the MIME type for a given file name or path.
  ///
  /// [fileName] - The file name or path.
  /// Returns the MIME type string or 'application/octet-stream' if unknown.
  static String getMimeTypeFromFileName(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == fileName.length - 1) {
      return 'application/octet-stream';
    }
    final extension = fileName.substring(lastDot + 1);
    return getMimeType(extension);
  }

  /// Checks if the given MIME type represents an image.
  ///
  /// [mimeType] - The MIME type to check.
  /// Returns true if the MIME type is a supported image type.
  static bool isImage(String? mimeType) {
    if (mimeType == null) return false;
    final lower = mimeType.toLowerCase();
    return imageMimeTypes.contains(lower) || lower.startsWith('image/');
  }

  /// Checks if the given MIME type represents a video.
  ///
  /// [mimeType] - The MIME type to check.
  /// Returns true if the MIME type is a supported video type.
  static bool isVideo(String? mimeType) {
    if (mimeType == null) return false;
    final lower = mimeType.toLowerCase();
    return videoMimeTypes.contains(lower) || lower.startsWith('video/');
  }

  /// Checks if the given MIME type represents audio.
  ///
  /// [mimeType] - The MIME type to check.
  /// Returns true if the MIME type is an audio type.
  static bool isAudio(String? mimeType) {
    if (mimeType == null) return false;
    return mimeType.toLowerCase().startsWith('audio/');
  }

  /// Checks if the given MIME type represents a media file (image, video, or audio).
  ///
  /// [mimeType] - The MIME type to check.
  /// Returns true if the MIME type is a media type.
  static bool isMedia(String? mimeType) {
    return isImage(mimeType) || isVideo(mimeType) || isAudio(mimeType);
  }

  /// Checks if a file extension represents an image.
  ///
  /// [extension] - The file extension without the leading dot.
  /// Returns true if the extension is a supported image type.
  static bool isImageExtension(String? extension) {
    if (extension == null) return false;
    return supportedImageExtensions.contains(extension.toLowerCase());
  }

  /// Checks if a file extension represents a video.
  ///
  /// [extension] - The file extension without the leading dot.
  /// Returns true if the extension is a supported video type.
  static bool isVideoExtension(String? extension) {
    if (extension == null) return false;
    return supportedVideoExtensions.contains(extension.toLowerCase());
  }

  /// Checks if a file extension represents a media file.
  ///
  /// [extension] - The file extension without the leading dot.
  /// Returns true if the extension is a supported media type.
  static bool isMediaExtension(String? extension) {
    return isImageExtension(extension) || isVideoExtension(extension);
  }

  /// Extracts the file extension from a file name or path.
  ///
  /// [fileName] - The file name or path.
  /// Returns the extension without the leading dot, or null if none.
  static String? getExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == fileName.length - 1) {
      return null;
    }
    return fileName.substring(lastDot + 1).toLowerCase();
  }
}
