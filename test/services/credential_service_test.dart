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

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:quest3_webdav_client/models/server_credentials.dart';
import 'package:quest3_webdav_client/services/credential_service.dart';

/// A mock implementation of FlutterSecureStorage for testing.
class MockSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _storage = {};
  bool shouldThrow = false;

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) {
      throw Exception('Mock storage error');
    }
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) {
      throw Exception('Mock storage error');
    }
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) {
      throw Exception('Mock storage error');
    }
    _storage.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) {
      throw Exception('Mock storage error');
    }
    return Map.from(_storage);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) {
      throw Exception('Mock storage error');
    }
    _storage.clear();
  }

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (shouldThrow) {
      throw Exception('Mock storage error');
    }
    return _storage.containsKey(key);
  }

  @override
  IOSOptions get iOptions => const IOSOptions();

  @override
  AndroidOptions get aOptions => const AndroidOptions();

  @override
  LinuxOptions get lOptions => const LinuxOptions();

  @override
  WebOptions get webOptions => const WebOptions();

  @override
  MacOsOptions get mOptions => const MacOsOptions();

  @override
  WindowsOptions get wOptions => const WindowsOptions();

  @override
  Future<bool?> isCupertinoProtectedDataAvailable() async => true;

  @override
  Stream<bool>? get onCupertinoProtectedDataAvailabilityChanged => null;

  @override
  void registerListener({
    required String key,
    required void Function(String?) listener,
  }) {}

  @override
  void unregisterListener({
    required String key,
    required void Function(String?) listener,
  }) {}

  @override
  void unregisterAllListenersForKey({required String key}) {}

  @override
  void unregisterAllListeners() {}

  void clear() => _storage.clear();
}

void main() {
  group('ServerCredentials', () {
    test('creates credentials with username and password', () {
      const credentials = ServerCredentials(
        username: 'testuser',
        password: 'testpass',
      );

      expect(credentials.username, 'testuser');
      expect(credentials.password, 'testpass');
    });

    test('serializes to JSON and back', () {
      const original = ServerCredentials(
        username: 'testuser',
        password: 'testpass123',
      );

      final json = original.toJson();
      final restored = ServerCredentials.fromJson(json);

      expect(restored.username, original.username);
      expect(restored.password, original.password);
      expect(restored, original);
    });

    test('isValid returns true for non-empty credentials', () {
      const valid = ServerCredentials(username: 'user', password: 'pass');
      const emptyUser = ServerCredentials(username: '', password: 'pass');
      const emptyPass = ServerCredentials(username: 'user', password: '');

      expect(valid.isValid, true);
      expect(emptyUser.isValid, false);
      expect(emptyPass.isValid, false);
    });

    test('equality works correctly', () {
      const cred1 = ServerCredentials(username: 'user', password: 'pass');
      const cred2 = ServerCredentials(username: 'user', password: 'pass');
      const cred3 = ServerCredentials(username: 'other', password: 'pass');

      expect(cred1, cred2);
      expect(cred1, isNot(cred3));
    });

    test('toString hides password', () {
      const credentials = ServerCredentials(
        username: 'testuser',
        password: 'secretpassword',
      );

      final str = credentials.toString();
      expect(str, contains('testuser'));
      expect(str, isNot(contains('secretpassword')));
      expect(str, contains('****'));
    });
  });

  group('CredentialService', () {
    late MockSecureStorage mockStorage;
    late CredentialService service;

    setUp(() {
      mockStorage = MockSecureStorage();
      service = CredentialService.withStorage(mockStorage);
    });

    tearDown(() {
      mockStorage.clear();
      mockStorage.shouldThrow = false;
    });

    test('saves and retrieves credentials', () async {
      const credentialId = 'test-id-123';
      const username = 'testuser';
      const password = 'testpass';

      await service.saveCredentials(credentialId, username, password);
      final retrieved = await service.getCredentials(credentialId);

      expect(retrieved, isNotNull);
      expect(retrieved!.username, username);
      expect(retrieved.password, password);
    });

    test('returns null for non-existent credentials', () async {
      final retrieved = await service.getCredentials('non-existent');
      expect(retrieved, isNull);
    });

    test('hasCredentials returns correct values', () async {
      const credentialId = 'test-id-456';

      expect(await service.hasCredentials(credentialId), false);

      await service.saveCredentials(credentialId, 'user', 'pass');

      expect(await service.hasCredentials(credentialId), true);
    });

    test('deletes credentials', () async {
      const credentialId = 'test-id-789';

      await service.saveCredentials(credentialId, 'user', 'pass');
      expect(await service.hasCredentials(credentialId), true);

      await service.deleteCredentials(credentialId);
      expect(await service.hasCredentials(credentialId), false);
    });

    test('updates existing credentials', () async {
      const credentialId = 'test-id-update';

      await service.saveCredentials(credentialId, 'olduser', 'oldpass');
      await service.updateCredentials(credentialId, 'newuser', 'newpass');

      final retrieved = await service.getCredentials(credentialId);
      expect(retrieved!.username, 'newuser');
      expect(retrieved.password, 'newpass');
    });

    test('deleteAllCredentials removes only credential keys', () async {
      await service.saveCredentials('cred1', 'user1', 'pass1');
      await service.saveCredentials('cred2', 'user2', 'pass2');

      await service.deleteAllCredentials();

      expect(await service.hasCredentials('cred1'), false);
      expect(await service.hasCredentials('cred2'), false);
    });

    test('throws CredentialStorageException on save error', () async {
      mockStorage.shouldThrow = true;

      expect(
        () => service.saveCredentials('id', 'user', 'pass'),
        throwsA(isA<CredentialStorageException>()),
      );
    });

    test('throws CredentialStorageException on read error', () async {
      mockStorage.shouldThrow = true;

      expect(
        () => service.getCredentials('id'),
        throwsA(isA<CredentialStorageException>()),
      );
    });

    test('throws CredentialStorageException on delete error', () async {
      mockStorage.shouldThrow = true;

      expect(
        () => service.deleteCredentials('id'),
        throwsA(isA<CredentialStorageException>()),
      );
    });

    test('throws CredentialStorageException on hasCredentials error', () async {
      mockStorage.shouldThrow = true;

      expect(
        () => service.hasCredentials('id'),
        throwsA(isA<CredentialStorageException>()),
      );
    });
  });

  group('CredentialStorageException', () {
    test('toString includes message', () {
      const exception = CredentialStorageException('Test error');
      expect(exception.toString(), contains('Test error'));
    });

    test('toString includes cause when present', () {
      final exception = CredentialStorageException(
        'Test error',
        Exception('Underlying error'),
      );
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('caused by'));
    });
  });
}
