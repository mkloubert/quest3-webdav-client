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

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';

/// Provider for the application database instance.
///
/// This is a singleton provider that creates and manages the Drift database.
/// Use this provider to access the database throughout the app.
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  // Close database when provider is disposed
  ref.onDispose(() {
    database.close();
  });

  return database;
});

/// Provider for the VirtualFolderDao.
///
/// Provides access to virtual folder database operations.
final virtualFolderDaoProvider = Provider<VirtualFolderDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.virtualFolderDao;
});

/// Provider for the OfflineFileDao.
///
/// Provides access to offline file database operations.
final offlineFileDaoProvider = Provider<OfflineFileDao>((ref) {
  final database = ref.watch(databaseProvider);
  return database.offlineFileDao;
});
