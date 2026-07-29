import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class ScriptureDatabase {
  ScriptureDatabase._();

  static final ScriptureDatabase instance = ScriptureDatabase._();

  static const String _assetPath = 'assets/databases/webc.db';
  static const String _databaseFileName = 'webc.db';

  // Increase this number whenever a newly rebuilt WEBC database
  // should replace the database already installed on a device.
  static const int _assetDatabaseVersion = 3;

  sqflite.Database? _database;

  Future<sqflite.Database> get database async {
    final sqflite.Database? existingDatabase = _database;

    if (existingDatabase != null) {
      return existingDatabase;
    }

    final sqflite.Database openedDatabase =
        await _openDatabase();

    _database = openedDatabase;
    return openedDatabase;
  }

  Future<sqflite.Database> _openDatabase() async {
    final String databasePath =
        await _prepareDatabaseFile();

    if (Platform.isWindows || Platform.isLinux) {
      ffi.sqfliteFfiInit();

      return ffi.databaseFactoryFfi.openDatabase(
        databasePath,
        options: ffi.OpenDatabaseOptions(
          readOnly: true,
        ),
      );
    }

    return sqflite.openDatabase(
      databasePath,
      readOnly: true,
    );
  }

  Future<String> _prepareDatabaseFile() async {
    final Directory supportDirectory =
        await getApplicationSupportDirectory();

    final Directory databaseDirectory = Directory(
      path.join(
        supportDirectory.path,
        'databases',
      ),
    );

    await databaseDirectory.create(
      recursive: true,
    );

    final File databaseFile = File(
      path.join(
        databaseDirectory.path,
        _databaseFileName,
      ),
    );

    final File versionFile = File(
      '${databaseFile.path}.version',
    );

    final bool databaseNeedsCopy =
        await _databaseNeedsCopy(
      databaseFile: databaseFile,
      versionFile: versionFile,
    );

    if (databaseNeedsCopy) {
      await _copyBundledDatabase(
        databaseFile: databaseFile,
        versionFile: versionFile,
      );
    }

    return databaseFile.path;
  }

  Future<bool> _databaseNeedsCopy({
    required File databaseFile,
    required File versionFile,
  }) async {
    if (!await databaseFile.exists()) {
      return true;
    }

    if (!await versionFile.exists()) {
      return true;
    }

    try {
      final String installedVersion =
          (await versionFile.readAsString()).trim();

      return installedVersion !=
          _assetDatabaseVersion.toString();
    } catch (_) {
      return true;
    }
  }

  Future<void> _copyBundledDatabase({
    required File databaseFile,
    required File versionFile,
  }) async {
    final ByteData bundledDatabase =
        await rootBundle.load(_assetPath);

    final List<int> databaseBytes =
        bundledDatabase.buffer.asUint8List(
      bundledDatabase.offsetInBytes,
      bundledDatabase.lengthInBytes,
    );

    final File temporaryFile = File(
      '${databaseFile.path}.temporary',
    );

    if (await temporaryFile.exists()) {
      await temporaryFile.delete();
    }

    await temporaryFile.writeAsBytes(
      databaseBytes,
      flush: true,
    );

    await _deleteDatabaseFiles(
      databaseFile.path,
    );

    await temporaryFile.rename(
      databaseFile.path,
    );

    await versionFile.writeAsString(
      _assetDatabaseVersion.toString(),
      flush: true,
    );
  }

  Future<void> _deleteDatabaseFiles(
    String databasePath,
  ) async {
    final List<String> possibleFiles = [
      databasePath,
      '$databasePath-shm',
      '$databasePath-wal',
      '$databasePath-journal',
    ];

    for (final String filePath in possibleFiles) {
      final File file = File(filePath);

      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> close() async {
    final sqflite.Database? openDatabase = _database;

    if (openDatabase == null) {
      return;
    }

    await openDatabase.close();
    _database = null;
  }
}