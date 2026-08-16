import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/saint.dart';

class SaintRepository {
  SaintRepository({this.assetPath = 'assets/data/saints/saints.json'});

  final String assetPath;

  Future<Map<String, Saint>>? _saintsByIdFuture;

  Future<List<Saint>> getAll() async {
    final Map<String, Saint> saintsById = await _loadSaintsById();
    return List<Saint>.unmodifiable(saintsById.values);
  }

  Future<Saint?> getById(String id) async {
    final String normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final Map<String, Saint> saintsById = await _loadSaintsById();
    return saintsById[normalizedId];
  }

  Future<Map<String, Saint>> _loadSaintsById() {
    return _saintsByIdFuture ??= _readSaintsById();
  }

  Future<Map<String, Saint>> _readSaintsById() async {
    final String jsonText = await rootBundle.loadString(assetPath);
    final Object? decoded = jsonDecode(jsonText);

    if (decoded is! Map<String, dynamic>) {
      throw FormatException('$assetPath is not a JSON object.');
    }

    final int schemaVersion = (decoded['schemaVersion'] as num?)?.toInt() ?? 0;

    if (schemaVersion != 1) {
      throw FormatException(
        '$assetPath uses unsupported schemaVersion $schemaVersion.',
      );
    }

    final Object? saintsValue = decoded['saints'];

    if (saintsValue is! List<dynamic>) {
      throw FormatException('$assetPath has no valid saints list.');
    }

    final Map<String, Saint> saintsById = <String, Saint>{};

    for (final dynamic saintValue in saintsValue) {
      if (saintValue is! Map<String, dynamic>) {
        throw FormatException('$assetPath contains an invalid saint record.');
      }

      final Saint saint = Saint.fromJson(saintValue);

      if (saintsById.containsKey(saint.id)) {
        throw FormatException(
          '$assetPath contains duplicate saint ID "${saint.id}".',
        );
      }

      saintsById[saint.id] = saint;
    }

    return Map<String, Saint>.unmodifiable(saintsById);
  }
}
