// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
mixin _$VirtualFolderDaoMixin on DatabaseAccessor<AppDatabase> {
  $VirtualFoldersTable get virtualFolders => attachedDatabase.virtualFolders;
  VirtualFolderDaoManager get managers => VirtualFolderDaoManager(this);
}

class VirtualFolderDaoManager {
  final _$VirtualFolderDaoMixin _db;
  VirtualFolderDaoManager(this._db);
  $$VirtualFoldersTableTableManager get virtualFolders =>
      $$VirtualFoldersTableTableManager(
        _db.attachedDatabase,
        _db.virtualFolders,
      );
}

mixin _$OfflineFileDaoMixin on DatabaseAccessor<AppDatabase> {
  $VirtualFoldersTable get virtualFolders => attachedDatabase.virtualFolders;
  $OfflineFilesTable get offlineFiles => attachedDatabase.offlineFiles;
  OfflineFileDaoManager get managers => OfflineFileDaoManager(this);
}

class OfflineFileDaoManager {
  final _$OfflineFileDaoMixin _db;
  OfflineFileDaoManager(this._db);
  $$VirtualFoldersTableTableManager get virtualFolders =>
      $$VirtualFoldersTableTableManager(
        _db.attachedDatabase,
        _db.virtualFolders,
      );
  $$OfflineFilesTableTableManager get offlineFiles =>
      $$OfflineFilesTableTableManager(_db.attachedDatabase, _db.offlineFiles);
}

class $VirtualFoldersTable extends VirtualFolders
    with TableInfo<$VirtualFoldersTable, VirtualFolder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VirtualFoldersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUrlMeta = const VerificationMeta(
    'serverUrl',
  );
  @override
  late final GeneratedColumn<String> serverUrl = GeneratedColumn<String>(
    'server_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _basePathMeta = const VerificationMeta(
    'basePath',
  );
  @override
  late final GeneratedColumn<String> basePath = GeneratedColumn<String>(
    'base_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _credentialIdMeta = const VerificationMeta(
    'credentialId',
  );
  @override
  late final GeneratedColumn<String> credentialId = GeneratedColumn<String>(
    'credential_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconColorMeta = const VerificationMeta(
    'iconColor',
  );
  @override
  late final GeneratedColumn<int> iconColor = GeneratedColumn<int>(
    'icon_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    serverUrl,
    basePath,
    credentialId,
    iconColor,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'virtual_folders';
  @override
  VerificationContext validateIntegrity(
    Insertable<VirtualFolder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('server_url')) {
      context.handle(
        _serverUrlMeta,
        serverUrl.isAcceptableOrUnknown(data['server_url']!, _serverUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_serverUrlMeta);
    }
    if (data.containsKey('base_path')) {
      context.handle(
        _basePathMeta,
        basePath.isAcceptableOrUnknown(data['base_path']!, _basePathMeta),
      );
    } else if (isInserting) {
      context.missing(_basePathMeta);
    }
    if (data.containsKey('credential_id')) {
      context.handle(
        _credentialIdMeta,
        credentialId.isAcceptableOrUnknown(
          data['credential_id']!,
          _credentialIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_credentialIdMeta);
    }
    if (data.containsKey('icon_color')) {
      context.handle(
        _iconColorMeta,
        iconColor.isAcceptableOrUnknown(data['icon_color']!, _iconColorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VirtualFolder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VirtualFolder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      serverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_url'],
      )!,
      basePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_path'],
      )!,
      credentialId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}credential_id'],
      )!,
      iconColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $VirtualFoldersTable createAlias(String alias) {
    return $VirtualFoldersTable(attachedDatabase, alias);
  }
}

class VirtualFolder extends DataClass implements Insertable<VirtualFolder> {
  /// Unique identifier (UUID).
  final String id;

  /// Display name.
  final String name;

  /// WebDAV server URL.
  final String serverUrl;

  /// Base path on the remote server.
  final String basePath;

  /// Reference ID to credentials in secure storage.
  final String credentialId;

  /// Optional color for the folder icon (ARGB integer).
  final int? iconColor;

  /// Timestamp when the folder was created.
  final DateTime createdAt;

  /// Timestamp when the folder was last updated.
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['server_url'] = Variable<String>(serverUrl);
    map['base_path'] = Variable<String>(basePath);
    map['credential_id'] = Variable<String>(credentialId);
    if (!nullToAbsent || iconColor != null) {
      map['icon_color'] = Variable<int>(iconColor);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VirtualFoldersCompanion toCompanion(bool nullToAbsent) {
    return VirtualFoldersCompanion(
      id: Value(id),
      name: Value(name),
      serverUrl: Value(serverUrl),
      basePath: Value(basePath),
      credentialId: Value(credentialId),
      iconColor: iconColor == null && nullToAbsent
          ? const Value.absent()
          : Value(iconColor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VirtualFolder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VirtualFolder(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      serverUrl: serializer.fromJson<String>(json['serverUrl']),
      basePath: serializer.fromJson<String>(json['basePath']),
      credentialId: serializer.fromJson<String>(json['credentialId']),
      iconColor: serializer.fromJson<int?>(json['iconColor']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'serverUrl': serializer.toJson<String>(serverUrl),
      'basePath': serializer.toJson<String>(basePath),
      'credentialId': serializer.toJson<String>(credentialId),
      'iconColor': serializer.toJson<int?>(iconColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VirtualFolder copyWith({
    String? id,
    String? name,
    String? serverUrl,
    String? basePath,
    String? credentialId,
    Value<int?> iconColor = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => VirtualFolder(
    id: id ?? this.id,
    name: name ?? this.name,
    serverUrl: serverUrl ?? this.serverUrl,
    basePath: basePath ?? this.basePath,
    credentialId: credentialId ?? this.credentialId,
    iconColor: iconColor.present ? iconColor.value : this.iconColor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  VirtualFolder copyWithCompanion(VirtualFoldersCompanion data) {
    return VirtualFolder(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      serverUrl: data.serverUrl.present ? data.serverUrl.value : this.serverUrl,
      basePath: data.basePath.present ? data.basePath.value : this.basePath,
      credentialId: data.credentialId.present
          ? data.credentialId.value
          : this.credentialId,
      iconColor: data.iconColor.present ? data.iconColor.value : this.iconColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VirtualFolder(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('basePath: $basePath, ')
          ..write('credentialId: $credentialId, ')
          ..write('iconColor: $iconColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    serverUrl,
    basePath,
    credentialId,
    iconColor,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VirtualFolder &&
          other.id == this.id &&
          other.name == this.name &&
          other.serverUrl == this.serverUrl &&
          other.basePath == this.basePath &&
          other.credentialId == this.credentialId &&
          other.iconColor == this.iconColor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VirtualFoldersCompanion extends UpdateCompanion<VirtualFolder> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> serverUrl;
  final Value<String> basePath;
  final Value<String> credentialId;
  final Value<int?> iconColor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VirtualFoldersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.serverUrl = const Value.absent(),
    this.basePath = const Value.absent(),
    this.credentialId = const Value.absent(),
    this.iconColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VirtualFoldersCompanion.insert({
    required String id,
    required String name,
    required String serverUrl,
    required String basePath,
    required String credentialId,
    this.iconColor = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       serverUrl = Value(serverUrl),
       basePath = Value(basePath),
       credentialId = Value(credentialId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<VirtualFolder> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? serverUrl,
    Expression<String>? basePath,
    Expression<String>? credentialId,
    Expression<int>? iconColor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (serverUrl != null) 'server_url': serverUrl,
      if (basePath != null) 'base_path': basePath,
      if (credentialId != null) 'credential_id': credentialId,
      if (iconColor != null) 'icon_color': iconColor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VirtualFoldersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? serverUrl,
    Value<String>? basePath,
    Value<String>? credentialId,
    Value<int?>? iconColor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return VirtualFoldersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      serverUrl: serverUrl ?? this.serverUrl,
      basePath: basePath ?? this.basePath,
      credentialId: credentialId ?? this.credentialId,
      iconColor: iconColor ?? this.iconColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (serverUrl.present) {
      map['server_url'] = Variable<String>(serverUrl.value);
    }
    if (basePath.present) {
      map['base_path'] = Variable<String>(basePath.value);
    }
    if (credentialId.present) {
      map['credential_id'] = Variable<String>(credentialId.value);
    }
    if (iconColor.present) {
      map['icon_color'] = Variable<int>(iconColor.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VirtualFoldersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('serverUrl: $serverUrl, ')
          ..write('basePath: $basePath, ')
          ..write('credentialId: $credentialId, ')
          ..write('iconColor: $iconColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineFilesTable extends OfflineFiles
    with TableInfo<$OfflineFilesTable, OfflineFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _virtualFolderIdMeta = const VerificationMeta(
    'virtualFolderId',
  );
  @override
  late final GeneratedColumn<String> virtualFolderId = GeneratedColumn<String>(
    'virtual_folder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES virtual_folders (id)',
    ),
  );
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _downloadedAtMeta = const VerificationMeta(
    'downloadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> downloadedAt = GeneratedColumn<DateTime>(
    'downloaded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    virtualFolderId,
    remotePath,
    localPath,
    fileSize,
    mimeType,
    downloadedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('virtual_folder_id')) {
      context.handle(
        _virtualFolderIdMeta,
        virtualFolderId.isAcceptableOrUnknown(
          data['virtual_folder_id']!,
          _virtualFolderIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_virtualFolderIdMeta);
    }
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    } else if (isInserting) {
      context.missing(_remotePathMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('downloaded_at')) {
      context.handle(
        _downloadedAtMeta,
        downloadedAt.isAcceptableOrUnknown(
          data['downloaded_at']!,
          _downloadedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_downloadedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      virtualFolderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}virtual_folder_id'],
      )!,
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      downloadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}downloaded_at'],
      )!,
    );
  }

  @override
  $OfflineFilesTable createAlias(String alias) {
    return $OfflineFilesTable(attachedDatabase, alias);
  }
}

class OfflineFile extends DataClass implements Insertable<OfflineFile> {
  /// Unique identifier (UUID).
  final String id;

  /// Reference to the virtual folder.
  final String virtualFolderId;

  /// Full remote path on the WebDAV server.
  final String remotePath;

  /// Local file system path.
  final String localPath;

  /// File size in bytes.
  final int fileSize;

  /// MIME type of the file.
  final String mimeType;

  /// Timestamp when the file was downloaded.
  final DateTime downloadedAt;
  const OfflineFile({
    required this.id,
    required this.virtualFolderId,
    required this.remotePath,
    required this.localPath,
    required this.fileSize,
    required this.mimeType,
    required this.downloadedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['virtual_folder_id'] = Variable<String>(virtualFolderId);
    map['remote_path'] = Variable<String>(remotePath);
    map['local_path'] = Variable<String>(localPath);
    map['file_size'] = Variable<int>(fileSize);
    map['mime_type'] = Variable<String>(mimeType);
    map['downloaded_at'] = Variable<DateTime>(downloadedAt);
    return map;
  }

  OfflineFilesCompanion toCompanion(bool nullToAbsent) {
    return OfflineFilesCompanion(
      id: Value(id),
      virtualFolderId: Value(virtualFolderId),
      remotePath: Value(remotePath),
      localPath: Value(localPath),
      fileSize: Value(fileSize),
      mimeType: Value(mimeType),
      downloadedAt: Value(downloadedAt),
    );
  }

  factory OfflineFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineFile(
      id: serializer.fromJson<String>(json['id']),
      virtualFolderId: serializer.fromJson<String>(json['virtualFolderId']),
      remotePath: serializer.fromJson<String>(json['remotePath']),
      localPath: serializer.fromJson<String>(json['localPath']),
      fileSize: serializer.fromJson<int>(json['fileSize']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      downloadedAt: serializer.fromJson<DateTime>(json['downloadedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'virtualFolderId': serializer.toJson<String>(virtualFolderId),
      'remotePath': serializer.toJson<String>(remotePath),
      'localPath': serializer.toJson<String>(localPath),
      'fileSize': serializer.toJson<int>(fileSize),
      'mimeType': serializer.toJson<String>(mimeType),
      'downloadedAt': serializer.toJson<DateTime>(downloadedAt),
    };
  }

  OfflineFile copyWith({
    String? id,
    String? virtualFolderId,
    String? remotePath,
    String? localPath,
    int? fileSize,
    String? mimeType,
    DateTime? downloadedAt,
  }) => OfflineFile(
    id: id ?? this.id,
    virtualFolderId: virtualFolderId ?? this.virtualFolderId,
    remotePath: remotePath ?? this.remotePath,
    localPath: localPath ?? this.localPath,
    fileSize: fileSize ?? this.fileSize,
    mimeType: mimeType ?? this.mimeType,
    downloadedAt: downloadedAt ?? this.downloadedAt,
  );
  OfflineFile copyWithCompanion(OfflineFilesCompanion data) {
    return OfflineFile(
      id: data.id.present ? data.id.value : this.id,
      virtualFolderId: data.virtualFolderId.present
          ? data.virtualFolderId.value
          : this.virtualFolderId,
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      downloadedAt: data.downloadedAt.present
          ? data.downloadedAt.value
          : this.downloadedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineFile(')
          ..write('id: $id, ')
          ..write('virtualFolderId: $virtualFolderId, ')
          ..write('remotePath: $remotePath, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('downloadedAt: $downloadedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    virtualFolderId,
    remotePath,
    localPath,
    fileSize,
    mimeType,
    downloadedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineFile &&
          other.id == this.id &&
          other.virtualFolderId == this.virtualFolderId &&
          other.remotePath == this.remotePath &&
          other.localPath == this.localPath &&
          other.fileSize == this.fileSize &&
          other.mimeType == this.mimeType &&
          other.downloadedAt == this.downloadedAt);
}

class OfflineFilesCompanion extends UpdateCompanion<OfflineFile> {
  final Value<String> id;
  final Value<String> virtualFolderId;
  final Value<String> remotePath;
  final Value<String> localPath;
  final Value<int> fileSize;
  final Value<String> mimeType;
  final Value<DateTime> downloadedAt;
  final Value<int> rowid;
  const OfflineFilesCompanion({
    this.id = const Value.absent(),
    this.virtualFolderId = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.localPath = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.downloadedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OfflineFilesCompanion.insert({
    required String id,
    required String virtualFolderId,
    required String remotePath,
    required String localPath,
    required int fileSize,
    required String mimeType,
    required DateTime downloadedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       virtualFolderId = Value(virtualFolderId),
       remotePath = Value(remotePath),
       localPath = Value(localPath),
       fileSize = Value(fileSize),
       mimeType = Value(mimeType),
       downloadedAt = Value(downloadedAt);
  static Insertable<OfflineFile> custom({
    Expression<String>? id,
    Expression<String>? virtualFolderId,
    Expression<String>? remotePath,
    Expression<String>? localPath,
    Expression<int>? fileSize,
    Expression<String>? mimeType,
    Expression<DateTime>? downloadedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (virtualFolderId != null) 'virtual_folder_id': virtualFolderId,
      if (remotePath != null) 'remote_path': remotePath,
      if (localPath != null) 'local_path': localPath,
      if (fileSize != null) 'file_size': fileSize,
      if (mimeType != null) 'mime_type': mimeType,
      if (downloadedAt != null) 'downloaded_at': downloadedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OfflineFilesCompanion copyWith({
    Value<String>? id,
    Value<String>? virtualFolderId,
    Value<String>? remotePath,
    Value<String>? localPath,
    Value<int>? fileSize,
    Value<String>? mimeType,
    Value<DateTime>? downloadedAt,
    Value<int>? rowid,
  }) {
    return OfflineFilesCompanion(
      id: id ?? this.id,
      virtualFolderId: virtualFolderId ?? this.virtualFolderId,
      remotePath: remotePath ?? this.remotePath,
      localPath: localPath ?? this.localPath,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (virtualFolderId.present) {
      map['virtual_folder_id'] = Variable<String>(virtualFolderId.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (downloadedAt.present) {
      map['downloaded_at'] = Variable<DateTime>(downloadedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineFilesCompanion(')
          ..write('id: $id, ')
          ..write('virtualFolderId: $virtualFolderId, ')
          ..write('remotePath: $remotePath, ')
          ..write('localPath: $localPath, ')
          ..write('fileSize: $fileSize, ')
          ..write('mimeType: $mimeType, ')
          ..write('downloadedAt: $downloadedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VirtualFoldersTable virtualFolders = $VirtualFoldersTable(this);
  late final $OfflineFilesTable offlineFiles = $OfflineFilesTable(this);
  late final VirtualFolderDao virtualFolderDao = VirtualFolderDao(
    this as AppDatabase,
  );
  late final OfflineFileDao offlineFileDao = OfflineFileDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    virtualFolders,
    offlineFiles,
  ];
}

typedef $$VirtualFoldersTableCreateCompanionBuilder =
    VirtualFoldersCompanion Function({
      required String id,
      required String name,
      required String serverUrl,
      required String basePath,
      required String credentialId,
      Value<int?> iconColor,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$VirtualFoldersTableUpdateCompanionBuilder =
    VirtualFoldersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> serverUrl,
      Value<String> basePath,
      Value<String> credentialId,
      Value<int?> iconColor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$VirtualFoldersTableReferences
    extends BaseReferences<_$AppDatabase, $VirtualFoldersTable, VirtualFolder> {
  $$VirtualFoldersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$OfflineFilesTable, List<OfflineFile>>
  _offlineFilesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.offlineFiles,
    aliasName: $_aliasNameGenerator(
      db.virtualFolders.id,
      db.offlineFiles.virtualFolderId,
    ),
  );

  $$OfflineFilesTableProcessedTableManager get offlineFilesRefs {
    final manager = $$OfflineFilesTableTableManager($_db, $_db.offlineFiles)
        .filter(
          (f) => f.virtualFolderId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_offlineFilesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VirtualFoldersTableFilterComposer
    extends Composer<_$AppDatabase, $VirtualFoldersTable> {
  $$VirtualFoldersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get basePath => $composableBuilder(
    column: $table.basePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get credentialId => $composableBuilder(
    column: $table.credentialId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconColor => $composableBuilder(
    column: $table.iconColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> offlineFilesRefs(
    Expression<bool> Function($$OfflineFilesTableFilterComposer f) f,
  ) {
    final $$OfflineFilesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.offlineFiles,
      getReferencedColumn: (t) => t.virtualFolderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OfflineFilesTableFilterComposer(
            $db: $db,
            $table: $db.offlineFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VirtualFoldersTableOrderingComposer
    extends Composer<_$AppDatabase, $VirtualFoldersTable> {
  $$VirtualFoldersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUrl => $composableBuilder(
    column: $table.serverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get basePath => $composableBuilder(
    column: $table.basePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get credentialId => $composableBuilder(
    column: $table.credentialId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconColor => $composableBuilder(
    column: $table.iconColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VirtualFoldersTableAnnotationComposer
    extends Composer<_$AppDatabase, $VirtualFoldersTable> {
  $$VirtualFoldersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get serverUrl =>
      $composableBuilder(column: $table.serverUrl, builder: (column) => column);

  GeneratedColumn<String> get basePath =>
      $composableBuilder(column: $table.basePath, builder: (column) => column);

  GeneratedColumn<String> get credentialId => $composableBuilder(
    column: $table.credentialId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get iconColor =>
      $composableBuilder(column: $table.iconColor, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> offlineFilesRefs<T extends Object>(
    Expression<T> Function($$OfflineFilesTableAnnotationComposer a) f,
  ) {
    final $$OfflineFilesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.offlineFiles,
      getReferencedColumn: (t) => t.virtualFolderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OfflineFilesTableAnnotationComposer(
            $db: $db,
            $table: $db.offlineFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VirtualFoldersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VirtualFoldersTable,
          VirtualFolder,
          $$VirtualFoldersTableFilterComposer,
          $$VirtualFoldersTableOrderingComposer,
          $$VirtualFoldersTableAnnotationComposer,
          $$VirtualFoldersTableCreateCompanionBuilder,
          $$VirtualFoldersTableUpdateCompanionBuilder,
          (VirtualFolder, $$VirtualFoldersTableReferences),
          VirtualFolder,
          PrefetchHooks Function({bool offlineFilesRefs})
        > {
  $$VirtualFoldersTableTableManager(
    _$AppDatabase db,
    $VirtualFoldersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VirtualFoldersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VirtualFoldersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VirtualFoldersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> serverUrl = const Value.absent(),
                Value<String> basePath = const Value.absent(),
                Value<String> credentialId = const Value.absent(),
                Value<int?> iconColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VirtualFoldersCompanion(
                id: id,
                name: name,
                serverUrl: serverUrl,
                basePath: basePath,
                credentialId: credentialId,
                iconColor: iconColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String serverUrl,
                required String basePath,
                required String credentialId,
                Value<int?> iconColor = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => VirtualFoldersCompanion.insert(
                id: id,
                name: name,
                serverUrl: serverUrl,
                basePath: basePath,
                credentialId: credentialId,
                iconColor: iconColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VirtualFoldersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({offlineFilesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (offlineFilesRefs) db.offlineFiles],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (offlineFilesRefs)
                    await $_getPrefetchedData<
                      VirtualFolder,
                      $VirtualFoldersTable,
                      OfflineFile
                    >(
                      currentTable: table,
                      referencedTable: $$VirtualFoldersTableReferences
                          ._offlineFilesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$VirtualFoldersTableReferences(
                            db,
                            table,
                            p0,
                          ).offlineFilesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.virtualFolderId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$VirtualFoldersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VirtualFoldersTable,
      VirtualFolder,
      $$VirtualFoldersTableFilterComposer,
      $$VirtualFoldersTableOrderingComposer,
      $$VirtualFoldersTableAnnotationComposer,
      $$VirtualFoldersTableCreateCompanionBuilder,
      $$VirtualFoldersTableUpdateCompanionBuilder,
      (VirtualFolder, $$VirtualFoldersTableReferences),
      VirtualFolder,
      PrefetchHooks Function({bool offlineFilesRefs})
    >;
typedef $$OfflineFilesTableCreateCompanionBuilder =
    OfflineFilesCompanion Function({
      required String id,
      required String virtualFolderId,
      required String remotePath,
      required String localPath,
      required int fileSize,
      required String mimeType,
      required DateTime downloadedAt,
      Value<int> rowid,
    });
typedef $$OfflineFilesTableUpdateCompanionBuilder =
    OfflineFilesCompanion Function({
      Value<String> id,
      Value<String> virtualFolderId,
      Value<String> remotePath,
      Value<String> localPath,
      Value<int> fileSize,
      Value<String> mimeType,
      Value<DateTime> downloadedAt,
      Value<int> rowid,
    });

final class $$OfflineFilesTableReferences
    extends BaseReferences<_$AppDatabase, $OfflineFilesTable, OfflineFile> {
  $$OfflineFilesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VirtualFoldersTable _virtualFolderIdTable(_$AppDatabase db) =>
      db.virtualFolders.createAlias(
        $_aliasNameGenerator(
          db.offlineFiles.virtualFolderId,
          db.virtualFolders.id,
        ),
      );

  $$VirtualFoldersTableProcessedTableManager get virtualFolderId {
    final $_column = $_itemColumn<String>('virtual_folder_id')!;

    final manager = $$VirtualFoldersTableTableManager(
      $_db,
      $_db.virtualFolders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_virtualFolderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OfflineFilesTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineFilesTable> {
  $$OfflineFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$VirtualFoldersTableFilterComposer get virtualFolderId {
    final $$VirtualFoldersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.virtualFolderId,
      referencedTable: $db.virtualFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VirtualFoldersTableFilterComposer(
            $db: $db,
            $table: $db.virtualFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OfflineFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineFilesTable> {
  $$OfflineFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$VirtualFoldersTableOrderingComposer get virtualFolderId {
    final $$VirtualFoldersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.virtualFolderId,
      referencedTable: $db.virtualFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VirtualFoldersTableOrderingComposer(
            $db: $db,
            $table: $db.virtualFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OfflineFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineFilesTable> {
  $$OfflineFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<DateTime> get downloadedAt => $composableBuilder(
    column: $table.downloadedAt,
    builder: (column) => column,
  );

  $$VirtualFoldersTableAnnotationComposer get virtualFolderId {
    final $$VirtualFoldersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.virtualFolderId,
      referencedTable: $db.virtualFolders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VirtualFoldersTableAnnotationComposer(
            $db: $db,
            $table: $db.virtualFolders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OfflineFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineFilesTable,
          OfflineFile,
          $$OfflineFilesTableFilterComposer,
          $$OfflineFilesTableOrderingComposer,
          $$OfflineFilesTableAnnotationComposer,
          $$OfflineFilesTableCreateCompanionBuilder,
          $$OfflineFilesTableUpdateCompanionBuilder,
          (OfflineFile, $$OfflineFilesTableReferences),
          OfflineFile,
          PrefetchHooks Function({bool virtualFolderId})
        > {
  $$OfflineFilesTableTableManager(_$AppDatabase db, $OfflineFilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineFilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> virtualFolderId = const Value.absent(),
                Value<String> remotePath = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<DateTime> downloadedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OfflineFilesCompanion(
                id: id,
                virtualFolderId: virtualFolderId,
                remotePath: remotePath,
                localPath: localPath,
                fileSize: fileSize,
                mimeType: mimeType,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String virtualFolderId,
                required String remotePath,
                required String localPath,
                required int fileSize,
                required String mimeType,
                required DateTime downloadedAt,
                Value<int> rowid = const Value.absent(),
              }) => OfflineFilesCompanion.insert(
                id: id,
                virtualFolderId: virtualFolderId,
                remotePath: remotePath,
                localPath: localPath,
                fileSize: fileSize,
                mimeType: mimeType,
                downloadedAt: downloadedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OfflineFilesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({virtualFolderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (virtualFolderId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.virtualFolderId,
                                referencedTable: $$OfflineFilesTableReferences
                                    ._virtualFolderIdTable(db),
                                referencedColumn: $$OfflineFilesTableReferences
                                    ._virtualFolderIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OfflineFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineFilesTable,
      OfflineFile,
      $$OfflineFilesTableFilterComposer,
      $$OfflineFilesTableOrderingComposer,
      $$OfflineFilesTableAnnotationComposer,
      $$OfflineFilesTableCreateCompanionBuilder,
      $$OfflineFilesTableUpdateCompanionBuilder,
      (OfflineFile, $$OfflineFilesTableReferences),
      OfflineFile,
      PrefetchHooks Function({bool virtualFolderId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VirtualFoldersTableTableManager get virtualFolders =>
      $$VirtualFoldersTableTableManager(_db, _db.virtualFolders);
  $$OfflineFilesTableTableManager get offlineFiles =>
      $$OfflineFilesTableTableManager(_db, _db.offlineFiles);
}
