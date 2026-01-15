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

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/server_credentials.dart';

/// Exception thrown when credential storage operations fail.
class CredentialStorageException implements Exception {
  /// Description of the error.
  final String message;

  /// The underlying error, if any.
  final Object? cause;

  const CredentialStorageException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'CredentialStorageException: $message (caused by: $cause)';
    }
    return 'CredentialStorageException: $message';
  }
}

/// Service for securely storing and retrieving WebDAV credentials.
///
/// Uses platform-native encryption:
/// - Android: EncryptedSharedPreferences (AES-256)
/// - iOS: Keychain Services
///
/// Each credential set is stored with a unique ID that is referenced
/// by the corresponding virtual folder.
class CredentialService {
  /// Prefix for credential keys in secure storage.
  static const String _keyPrefix = 'webdav_credentials_';

  /// The secure storage instance.
  final FlutterSecureStorage _storage;

  /// Creates a new credential service with default Android options.
  CredentialService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  /// Creates a credential service with a custom storage instance.
  ///
  /// Useful for testing with mock storage.
  CredentialService.withStorage(this._storage);

  /// Generates the storage key for a credential ID.
  String _getKey(String credentialId) => '$_keyPrefix$credentialId';

  /// Saves credentials to secure storage.
  ///
  /// [credentialId] - Unique identifier for this credential set.
  /// [username] - The username for authentication.
  /// [password] - The password for authentication.
  ///
  /// Throws [CredentialStorageException] if the operation fails.
  Future<void> saveCredentials(
    String credentialId,
    String username,
    String password,
  ) async {
    try {
      final credentials = ServerCredentials(
        username: username,
        password: password,
      );
      await _storage.write(
        key: _getKey(credentialId),
        value: credentials.toJson(),
      );
    } catch (e) {
      throw CredentialStorageException(
        'Failed to save credentials for ID: $credentialId',
        e,
      );
    }
  }

  /// Retrieves credentials from secure storage.
  ///
  /// [credentialId] - The unique identifier of the credential set.
  ///
  /// Returns the [ServerCredentials] if found, or null if not exists.
  /// Throws [CredentialStorageException] if the operation fails.
  Future<ServerCredentials?> getCredentials(String credentialId) async {
    try {
      final jsonString = await _storage.read(key: _getKey(credentialId));
      if (jsonString == null) {
        return null;
      }
      return ServerCredentials.fromJson(jsonString);
    } catch (e) {
      throw CredentialStorageException(
        'Failed to read credentials for ID: $credentialId',
        e,
      );
    }
  }

  /// Deletes credentials from secure storage.
  ///
  /// [credentialId] - The unique identifier of the credential set to delete.
  ///
  /// Throws [CredentialStorageException] if the operation fails.
  Future<void> deleteCredentials(String credentialId) async {
    try {
      await _storage.delete(key: _getKey(credentialId));
    } catch (e) {
      throw CredentialStorageException(
        'Failed to delete credentials for ID: $credentialId',
        e,
      );
    }
  }

  /// Checks if credentials exist for a given ID.
  ///
  /// [credentialId] - The unique identifier to check.
  ///
  /// Returns true if credentials exist, false otherwise.
  /// Throws [CredentialStorageException] if the operation fails.
  Future<bool> hasCredentials(String credentialId) async {
    try {
      final value = await _storage.read(key: _getKey(credentialId));
      return value != null;
    } catch (e) {
      throw CredentialStorageException(
        'Failed to check credentials for ID: $credentialId',
        e,
      );
    }
  }

  /// Updates existing credentials.
  ///
  /// This is a convenience method that calls [saveCredentials] internally.
  /// It will create new credentials if they don't exist.
  ///
  /// [credentialId] - Unique identifier for this credential set.
  /// [username] - The new username.
  /// [password] - The new password.
  ///
  /// Throws [CredentialStorageException] if the operation fails.
  Future<void> updateCredentials(
    String credentialId,
    String username,
    String password,
  ) async {
    await saveCredentials(credentialId, username, password);
  }

  /// Deletes all stored credentials.
  ///
  /// Use with caution - this will remove all WebDAV credentials.
  /// Throws [CredentialStorageException] if the operation fails.
  Future<void> deleteAllCredentials() async {
    try {
      final allKeys = await _storage.readAll();
      for (final key in allKeys.keys) {
        if (key.startsWith(_keyPrefix)) {
          await _storage.delete(key: key);
        }
      }
    } catch (e) {
      throw CredentialStorageException(
        'Failed to delete all credentials',
        e,
      );
    }
  }
}
