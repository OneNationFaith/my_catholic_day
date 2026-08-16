class Saint {
  const Saint({
    required this.id,
    required this.displayName,
    required this.feastMonth,
    required this.feastDay,
    required this.shortBiography,
    required this.patronages,
    required this.sources,
    this.birthInformation,
    this.deathInformation,
    this.saintType,
    this.shortReflection,
    this.prayer,
  });

  final String id;
  final String displayName;
  final int feastMonth;
  final int feastDay;
  final String shortBiography;
  final List<String> patronages;
  final SaintLifeInformation? birthInformation;
  final SaintLifeInformation? deathInformation;
  final String? saintType;
  final String? shortReflection;
  final String? prayer;
  final List<SaintSourceReference> sources;

  factory Saint.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> feast = _requiredMap(json, 'feast');
    final int feastMonth = _requiredInt(feast, 'month');
    final int feastDay = _requiredInt(feast, 'day');

    if (feastMonth < 1 || feastMonth > 12) {
      throw FormatException('Invalid saint feast month: $feastMonth.');
    }

    final int daysInMonth = DateTime(2000, feastMonth + 1, 0).day;

    if (feastDay < 1 || feastDay > daysInMonth) {
      throw FormatException('Invalid saint feast date: $feastMonth/$feastDay.');
    }

    return Saint(
      id: _requiredString(json, 'id'),
      displayName: _requiredString(json, 'displayName'),
      feastMonth: feastMonth,
      feastDay: feastDay,
      shortBiography: _requiredString(json, 'shortBiography'),
      patronages: _stringList(json, 'patronages'),
      birthInformation: _optionalLifeInformation(json, 'birthInformation'),
      deathInformation: _optionalLifeInformation(json, 'deathInformation'),
      saintType: _optionalString(json, 'saintType'),
      shortReflection: _optionalString(json, 'shortReflection'),
      prayer: _optionalString(json, 'prayer'),
      sources: _sourceList(json, 'sources'),
    );
  }
}

class SaintLifeInformation {
  const SaintLifeInformation({this.date, this.place, this.notes});

  final String? date;
  final String? place;
  final String? notes;

  factory SaintLifeInformation.fromJson(Map<String, dynamic> json) {
    return SaintLifeInformation(
      date: _optionalString(json, 'date'),
      place: _optionalString(json, 'place'),
      notes: _optionalString(json, 'notes'),
    );
  }
}

class SaintSourceReference {
  const SaintSourceReference({
    required this.label,
    this.url,
    this.publisher,
    this.attribution,
    this.license,
    this.notes,
  });

  final String label;
  final String? url;
  final String? publisher;
  final String? attribution;
  final String? license;
  final String? notes;

  factory SaintSourceReference.fromJson(Map<String, dynamic> json) {
    return SaintSourceReference(
      label: _requiredString(json, 'label'),
      url: _optionalString(json, 'url'),
      publisher: _optionalString(json, 'publisher'),
      attribution: _optionalString(json, 'attribution'),
      license: _optionalString(json, 'license'),
      notes: _optionalString(json, 'notes'),
    );
  }
}

SaintLifeInformation? _optionalLifeInformation(
  Map<String, dynamic> json,
  String key,
) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! Map<String, dynamic>) {
    throw FormatException('Saint field "$key" must be an object.');
  }

  return SaintLifeInformation.fromJson(value);
}

List<String> _stringList(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! List<dynamic>) {
    throw FormatException('Saint field "$key" must be a list.');
  }

  return List<String>.unmodifiable(
    value.map((dynamic item) {
      if (item is! String || item.trim().isEmpty) {
        throw FormatException('Saint field "$key" contains an invalid value.');
      }

      return item.trim();
    }),
  );
}

List<SaintSourceReference> _sourceList(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! List<dynamic>) {
    throw FormatException('Saint field "$key" must be a list.');
  }

  return List<SaintSourceReference>.unmodifiable(
    value.map((dynamic item) {
      if (item is! Map<String, dynamic>) {
        throw FormatException('Saint field "$key" contains an invalid source.');
      }

      return SaintSourceReference.fromJson(item);
    }),
  );
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! Map<String, dynamic>) {
    throw FormatException('Saint field "$key" must be an object.');
  }

  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is num) {
    return value.toInt();
  }

  throw FormatException('Saint field "$key" must be a number.');
}

String _requiredString(Map<String, dynamic> json, String key) {
  final String? value = _optionalString(json, key);

  if (value == null) {
    throw FormatException('Saint field "$key" is required.');
  }

  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('Saint field "$key" must be text.');
  }

  final String trimmedValue = value.trim();
  return trimmedValue.isEmpty ? null : trimmedValue;
}
