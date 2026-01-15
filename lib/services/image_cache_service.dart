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

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Service for caching images from WebDAV servers.
///
/// Uses flutter_cache_manager for smart caching with automatic cleanup.
/// Supports authentication headers for accessing protected resources.
class ImageCacheService {
  /// Singleton instance.
  static final ImageCacheService _instance = ImageCacheService._();

  /// The cache manager instance.
  late final CacheManager _cacheManager;

  /// Cache key for identifying this cache.
  static const String _cacheKey = 'webdav_image_cache';

  /// Maximum age of cached files.
  static const Duration _maxAge = Duration(days: 7);

  /// Maximum number of cached files.
  static const int _maxFiles = 200;

  ImageCacheService._() {
    _cacheManager = CacheManager(
      Config(
        _cacheKey,
        stalePeriod: _maxAge,
        maxNrOfCacheObjects: _maxFiles,
      ),
    );
  }

  /// Returns the singleton instance.
  factory ImageCacheService() => _instance;

  /// Gets an image from cache or downloads it.
  ///
  /// [url] - The URL of the image to fetch.
  /// [headers] - Optional authentication headers.
  /// Returns a [File] pointing to the cached image.
  Future<File> getImage(String url, {Map<String, String>? headers}) async {
    final fileInfo = await _cacheManager.downloadFile(
      url,
      authHeaders: headers,
    );
    return fileInfo.file;
  }

  /// Gets an image file if it's already in cache.
  ///
  /// [url] - The URL of the image to check.
  /// Returns a [File] if cached, null otherwise.
  Future<File?> getImageFromCache(String url) async {
    final fileInfo = await _cacheManager.getFileFromCache(url);
    return fileInfo?.file;
  }

  /// Gets a stream of file info for an image.
  ///
  /// [url] - The URL of the image to fetch.
  /// [headers] - Optional authentication headers.
  /// Returns a stream that emits cache status and file info.
  Stream<FileResponse> getImageStream(
    String url, {
    Map<String, String>? headers,
  }) {
    return _cacheManager.getFileStream(
      url,
      headers: headers,
      withProgress: true,
    );
  }

  /// Removes a specific image from cache.
  ///
  /// [url] - The URL of the image to remove.
  Future<void> removeImage(String url) async {
    await _cacheManager.removeFile(url);
  }

  /// Clears all cached images.
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  /// Gets the cache size in bytes.
  ///
  /// Note: flutter_cache_manager doesn't expose the cache directory directly,
  /// so this returns 0. For accurate size tracking, consider using a custom
  /// cache implementation or tracking downloads manually.
  Future<int> getCacheSize() async {
    // Cache manager doesn't expose directory directly
    // Return 0 as we can't calculate size without filesystem access
    return 0;
  }

  /// Disposes of the cache manager.
  ///
  /// Should be called when the app is closing.
  Future<void> dispose() async {
    await _cacheManager.dispose();
  }
}

/// Extension on ImageCacheService for formatted cache size.
extension ImageCacheServiceExtension on ImageCacheService {
  /// Gets a human-readable cache size string.
  Future<String> getFormattedCacheSize() async {
    final bytes = await getCacheSize();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
