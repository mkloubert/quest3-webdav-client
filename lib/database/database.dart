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

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

/// Table for storing virtual folder configurations.
class VirtualFolders extends Table {
  /// Unique identifier (UUID).
  TextColumn get id => text()();

  /// Display name.
  TextColumn get name => text().withLength(min: 1, max: 255)();

  /// WebDAV server URL.
  TextColumn get serverUrl => text()();

  /// Base path on the remote server.
  TextColumn get basePath => text()();

  /// Reference ID to credentials in secure storage.
  TextColumn get credentialId => text()();

  /// Optional color for the folder icon (ARGB integer).
  IntColumn get iconColor => integer().nullable()();

  /// Timestamp when the folder was created.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the folder was last updated.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table for tracking offline file copies.
class OfflineFiles extends Table {
  /// Unique identifier (UUID).
  TextColumn get id => text()();

  /// Reference to the virtual folder.
  TextColumn get virtualFolderId => text().references(VirtualFolders, #id)();

  /// Full remote path on the WebDAV server.
  TextColumn get remotePath => text()();

  /// Local file system path.
  TextColumn get localPath => text()();

  /// File size in bytes.
  IntColumn get fileSize => integer()();

  /// MIME type of the file.
  TextColumn get mimeType => text()();

  /// Timestamp when the file was downloaded.
  DateTimeColumn get downloadedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Data Access Object for virtual folders.
@DriftAccessor(tables: [VirtualFolders])
class VirtualFolderDao extends DatabaseAccessor<AppDatabase>
    with _$VirtualFolderDaoMixin {
  VirtualFolderDao(super.db);

  /// Returns all virtual folders ordered by name.
  Future<List<VirtualFolder>> getAllFolders() {
    return (select(virtualFolders)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Watches all virtual folders for changes.
  Stream<List<VirtualFolder>> watchAllFolders() {
    return (select(virtualFolders)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Returns a single folder by ID.
  Future<VirtualFolder?> getFolderById(String id) {
    return (select(virtualFolders)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Inserts a new virtual folder.
  Future<void> insertFolder(VirtualFoldersCompanion folder) {
    return into(virtualFolders).insert(folder);
  }

  /// Updates an existing virtual folder.
  Future<bool> updateFolder(VirtualFoldersCompanion folder) {
    return update(virtualFolders).replace(folder);
  }

  /// Deletes a virtual folder by ID.
  Future<int> deleteFolder(String id) {
    return (delete(virtualFolders)..where((t) => t.id.equals(id))).go();
  }
}

/// Data Access Object for offline files.
@DriftAccessor(tables: [OfflineFiles])
class OfflineFileDao extends DatabaseAccessor<AppDatabase>
    with _$OfflineFileDaoMixin {
  OfflineFileDao(super.db);

  /// Returns all offline files for a virtual folder.
  Future<List<OfflineFile>> getFilesForFolder(String virtualFolderId) {
    return (select(offlineFiles)
          ..where((t) => t.virtualFolderId.equals(virtualFolderId))
          ..orderBy([(t) => OrderingTerm.asc(t.remotePath)]))
        .get();
  }

  /// Watches offline files for a virtual folder.
  Stream<List<OfflineFile>> watchFilesForFolder(String virtualFolderId) {
    return (select(offlineFiles)
          ..where((t) => t.virtualFolderId.equals(virtualFolderId))
          ..orderBy([(t) => OrderingTerm.asc(t.remotePath)]))
        .watch();
  }

  /// Returns an offline file by its remote path and folder ID.
  Future<OfflineFile?> getFileByRemotePath(
    String virtualFolderId,
    String remotePath,
  ) {
    return (select(offlineFiles)
          ..where((t) =>
              t.virtualFolderId.equals(virtualFolderId) &
              t.remotePath.equals(remotePath)))
        .getSingleOrNull();
  }

  /// Inserts a new offline file record.
  Future<void> insertFile(OfflineFilesCompanion file) {
    return into(offlineFiles).insert(file);
  }

  /// Deletes an offline file by ID.
  Future<int> deleteFile(String id) {
    return (delete(offlineFiles)..where((t) => t.id.equals(id))).go();
  }

  /// Deletes all offline files for a virtual folder.
  Future<int> deleteFilesForFolder(String virtualFolderId) {
    return (delete(offlineFiles)
          ..where((t) => t.virtualFolderId.equals(virtualFolderId)))
        .go();
  }

  /// Returns all offline files.
  Future<List<OfflineFile>> getAllFiles() {
    return select(offlineFiles).get();
  }

  /// Returns the total size of all offline files in bytes.
  Future<int> getTotalSize() async {
    final files = await getAllFiles();
    return files.fold<int>(0, (sum, file) => sum + file.fileSize);
  }
}

/// The main application database.
@DriftDatabase(
  tables: [VirtualFolders, OfflineFiles],
  daos: [VirtualFolderDao, OfflineFileDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with custom executor.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Add future migrations here
      },
    );
  }
}

/// Opens a connection to the SQLite database.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'quest3_webdav.db'));
    return NativeDatabase.createInBackground(file);
  });
}
