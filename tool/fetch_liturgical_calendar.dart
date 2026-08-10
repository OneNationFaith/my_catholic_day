import 'dart:convert';
import 'dart:io';

const String _nationalBaseUrl =
    'https://litcal.johnromanodorazio.com/api/v5/calendar/nation/US';

const String _generalBaseUrl =
    'https://litcal.johnromanodorazio.com/api/v5/calendar';

const String _outputDirectory = 'tool/source/liturgical_calendar';

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.length != 1) {
      _printUsage();
      exitCode = 64;
      return;
    }

    final int? year = int.tryParse(arguments.first);

    if (year == null || year < 1970) {
      throw const FormatException(
        'Enter a valid calendar year, for example 2026.',
      );
    }

    final Uri nationalUri = Uri.parse(
      '$_nationalBaseUrl/$year',
    ).replace(queryParameters: <String, String>{'year_type': 'CIVIL'});

    final Uri ascensionThursdayUri = Uri.parse('$_generalBaseUrl/$year')
        .replace(
          queryParameters: <String, String>{
            'year_type': 'CIVIL',
            'epiphany': 'SUNDAY_JAN2_JAN8',
            'ascension': 'THURSDAY',
            'corpus_christi': 'SUNDAY',
            'eternal_high_priest': 'false',
          },
        );

    stdout.writeln('One Nation Faith Liturgical Calendar Fetcher');
    stdout.writeln('============================================');
    stdout.writeln();
    stdout.writeln('Year: $year');
    stdout.writeln();
    stdout.writeln('National U.S. source:');
    stdout.writeln(nationalUri);
    stdout.writeln();
    stdout.writeln('Ascension Thursday source:');
    stdout.writeln(ascensionThursdayUri);
    stdout.writeln();

    final Map<String, dynamic> nationalCalendar = await _fetchCalendar(
      nationalUri,
    );

    final Map<String, dynamic> ascensionThursdayCalendar = await _fetchCalendar(
      ascensionThursdayUri,
    );

    final int nationalEventCount = _validateCalendar(
      calendar: nationalCalendar,
      year: year,
      expectedAscension: 'SUNDAY',
      expectedNationalCalendar: 'US',
      label: 'National U.S. calendar',
    );

    final int ascensionThursdayEventCount = _validateCalendar(
      calendar: ascensionThursdayCalendar,
      year: year,
      expectedAscension: 'THURSDAY',
      label: 'Ascension Thursday calendar',
    );

    final Directory outputDirectory = Directory(_outputDirectory);

    outputDirectory.createSync(recursive: true);

    final File nationalOutputFile = File(
      '$_outputDirectory/${year}_litcal_raw.json',
    );

    final File ascensionThursdayOutputFile = File(
      '$_outputDirectory/'
      '${year}_litcal_ascension_thursday_raw.json',
    );

    const JsonEncoder encoder = JsonEncoder.withIndent('  ');

    nationalOutputFile.writeAsStringSync(
      '${encoder.convert(nationalCalendar)}\n',
    );

    ascensionThursdayOutputFile.writeAsStringSync(
      '${encoder.convert(ascensionThursdayCalendar)}\n',
    );

    stdout.writeln(
      'Validated $nationalEventCount '
      'national U.S. LitCal events.',
    );

    stdout.writeln(
      'Validated $ascensionThursdayEventCount '
      'Ascension Thursday LitCal events.',
    );

    stdout.writeln();
    stdout.writeln('Saved national U.S. calendar:');
    stdout.writeln(nationalOutputFile.path);

    stdout.writeln();
    stdout.writeln('Saved Ascension Thursday calendar:');
    stdout.writeln(ascensionThursdayOutputFile.path);
  } catch (error) {
    stderr.writeln();
    stderr.writeln('ERROR: $error');
    exitCode = 1;
  }
}

Future<Map<String, dynamic>> _fetchCalendar(Uri uri) async {
  final HttpClient client = HttpClient();

  try {
    final HttpClientRequest request = await client.getUrl(uri);

    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    request.headers.set(HttpHeaders.acceptLanguageHeader, 'en-US');

    final HttpClientResponse response = await request.close();

    final String responseBody = await utf8.decoder.bind(response).join();

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        'LitCal returned HTTP ${response.statusCode}.',
        uri: uri,
      );
    }

    final Object? decoded = jsonDecode(responseBody);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('LitCal did not return a JSON object.');
    }

    return decoded;
  } finally {
    client.close(force: true);
  }
}

int _validateCalendar({
  required Map<String, dynamic> calendar,
  required int year,
  required String expectedAscension,
  required String label,
  String? expectedNationalCalendar,
}) {
  final Object? settingsValue = calendar['settings'];

  if (settingsValue is! Map<String, dynamic>) {
    throw FormatException('$label has no valid settings object.');
  }

  final int? returnedYear = _integerValue(settingsValue['year']);

  if (returnedYear != year) {
    throw FormatException(
      '$label returned year $returnedYear '
      'instead of $year.',
    );
  }

  final String yearType =
      settingsValue['year_type']?.toString().trim().toUpperCase() ?? '';

  if (yearType != 'CIVIL') {
    throw FormatException(
      '$label returned year_type "$yearType" '
      'instead of CIVIL.',
    );
  }

  final String ascension =
      settingsValue['ascension']?.toString().trim().toUpperCase() ?? '';

  if (ascension != expectedAscension) {
    throw FormatException(
      '$label returned ascension "$ascension" '
      'instead of $expectedAscension.',
    );
  }

  if (expectedNationalCalendar != null) {
    final String nationalCalendar =
        settingsValue['national_calendar']?.toString().trim().toUpperCase() ??
        '';

    if (nationalCalendar != expectedNationalCalendar) {
      throw FormatException(
        '$label returned national_calendar '
        '"$nationalCalendar" instead of '
        '$expectedNationalCalendar.',
      );
    }
  }

  final Object? litcalValue = calendar['litcal'];

  if (litcalValue is! List) {
    throw FormatException('$label has no valid litcal event list.');
  }

  final Set<String> civilDates = <String>{};

  for (final dynamic eventValue in litcalValue) {
    if (eventValue is! Map<String, dynamic>) {
      continue;
    }

    final int? eventYear = _integerValue(eventValue['year']);

    final int? month = _integerValue(eventValue['month']);

    final int? day = _integerValue(eventValue['day']);

    if (eventYear != year || month == null || day == null) {
      continue;
    }

    civilDates.add(
      '$eventYear-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}',
    );
  }

  final int expectedDays = DateTime.utc(
    year + 1,
    1,
    1,
  ).difference(DateTime.utc(year, 1, 1)).inDays;

  if (civilDates.length != expectedDays) {
    throw FormatException(
      '$label should contain $expectedDays '
      'civil dates for $year, but contained '
      '${civilDates.length}.',
    );
  }

  return litcalValue.length;
}

int? _integerValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '');
}

void _printUsage() {
  stdout.writeln('Usage:');
  stdout.writeln(
    '  dart run '
    'tool/fetch_liturgical_calendar.dart 2026',
  );
}
