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

/// Represents WebDAV server credentials.
///
/// This class holds the username and password for authenticating
/// with a WebDAV server. Credentials are stored encrypted using
/// platform-native secure storage.
class ServerCredentials {
  /// The username for authentication.
  final String username;

  /// The password for authentication.
  final String password;

  const ServerCredentials({
    required this.username,
    required this.password,
  });

  /// Creates credentials from a JSON string.
  ///
  /// Used when reading from secure storage.
  factory ServerCredentials.fromJson(String jsonString) {
    final Map<String, dynamic> data = json.decode(jsonString);
    return ServerCredentials(
      username: data['username'] as String,
      password: data['password'] as String,
    );
  }

  /// Converts credentials to a JSON string.
  ///
  /// Used when writing to secure storage.
  String toJson() {
    return json.encode({
      'username': username,
      'password': password,
    });
  }

  /// Returns true if both username and password are not empty.
  bool get isValid => username.isNotEmpty && password.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerCredentials &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(username, password);

  @override
  String toString() {
    return 'ServerCredentials(username: $username, password: ****)';
  }
}
