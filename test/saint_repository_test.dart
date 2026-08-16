import 'package:flutter_test/flutter_test.dart';
import 'package:my_catholic_day/data/repositories/saint_repository.dart';
import 'package:my_catholic_day/models/saint.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Saint JSON parsing', () {
    test('parses required and optional saint fields', () {
      final Saint saint = Saint.fromJson(<String, dynamic>{
        'id': 'sample-saint',
        'displayName': 'Sample Saint',
        'feast': <String, dynamic>{'month': 2, 'day': 3},
        'shortBiography': 'Temporary sample biography.',
        'patronages': <String>['Sample patronage'],
        'birthInformation': <String, dynamic>{
          'date': 'Sample birth date',
          'place': 'Sample birth place',
          'notes': 'Sample birth notes',
        },
        'deathInformation': <String, dynamic>{
          'date': 'Sample death date',
          'place': 'Sample death place',
          'notes': 'Sample death notes',
        },
        'saintType': 'Sample title',
        'shortReflection': 'Temporary sample reflection.',
        'prayer': 'Temporary sample prayer.',
        'sources': <Map<String, dynamic>>[
          <String, dynamic>{
            'label': 'Sample source',
            'url': 'https://example.invalid/sample',
            'publisher': 'Sample publisher',
            'attribution': 'Sample attribution',
            'license': 'Sample license',
            'notes': 'Sample source notes',
          },
        ],
      });

      expect(saint.id, 'sample-saint');
      expect(saint.displayName, 'Sample Saint');
      expect(saint.feastMonth, 2);
      expect(saint.feastDay, 3);
      expect(saint.shortBiography, 'Temporary sample biography.');
      expect(saint.patronages, <String>['Sample patronage']);
      expect(saint.birthInformation?.date, 'Sample birth date');
      expect(saint.birthInformation?.place, 'Sample birth place');
      expect(saint.birthInformation?.notes, 'Sample birth notes');
      expect(saint.deathInformation?.date, 'Sample death date');
      expect(saint.deathInformation?.place, 'Sample death place');
      expect(saint.deathInformation?.notes, 'Sample death notes');
      expect(saint.saintType, 'Sample title');
      expect(saint.shortReflection, 'Temporary sample reflection.');
      expect(saint.prayer, 'Temporary sample prayer.');
      expect(saint.sources, hasLength(1));
      expect(saint.sources.single.label, 'Sample source');
      expect(saint.sources.single.url, 'https://example.invalid/sample');
      expect(saint.sources.single.publisher, 'Sample publisher');
      expect(saint.sources.single.attribution, 'Sample attribution');
      expect(saint.sources.single.license, 'Sample license');
      expect(saint.sources.single.notes, 'Sample source notes');
    });

    test('allows optional saint fields to be omitted', () {
      final Saint saint = Saint.fromJson(<String, dynamic>{
        'id': 'minimal-saint',
        'displayName': 'Minimal Saint',
        'feast': <String, dynamic>{'month': 1, 'day': 1},
        'shortBiography': 'Temporary sample biography.',
        'patronages': <String>[],
        'sources': <Map<String, dynamic>>[
          <String, dynamic>{'label': 'Sample source'},
        ],
      });

      expect(saint.birthInformation, isNull);
      expect(saint.deathInformation, isNull);
      expect(saint.saintType, isNull);
      expect(saint.shortReflection, isNull);
      expect(saint.prayer, isNull);
    });

    test('accepts February 29 as a recurring feast date', () {
      final Saint saint = Saint.fromJson(
        _minimalSaintJson(feastMonth: 2, feastDay: 29),
      );

      expect(saint.feastMonth, 2);
      expect(saint.feastDay, 29);
    });

    test('rejects February 30 as an invalid feast date', () {
      expect(
        () => Saint.fromJson(_minimalSaintJson(feastMonth: 2, feastDay: 30)),
        throwsFormatException,
      );
    });

    test('rejects April 31 as an invalid feast date', () {
      expect(
        () => Saint.fromJson(_minimalSaintJson(feastMonth: 4, feastDay: 31)),
        throwsFormatException,
      );
    });
  });

  group('SaintRepository', () {
    final SaintRepository repository = SaintRepository();

    test('loads the bundled saint profile by stable ID', () async {
      final Saint? saint = await repository.getById('elizabeth-ann-seton');

      expect(saint, isNotNull);
      expect(saint!.id, 'elizabeth-ann-seton');
      expect(saint.displayName, 'Saint Elizabeth Ann Seton');
      expect(saint.feastMonth, 1);
      expect(saint.feastDay, 4);
      expect(
        saint.shortBiography,
        startsWith('Elizabeth Ann Bayley Seton was born'),
      );
      expect(saint.patronages, <String>[
        'Catholic schools',
        'Sea Services personnel and families',
      ]);
      expect(saint.sources, hasLength(3));
      expect(
        saint.sources.map((SaintSourceReference source) => source.publisher),
        <String>[
          'United States Conference of Catholic Bishops',
          'National Shrine of Saint Elizabeth Ann Seton',
          'The Holy See',
        ],
      );
    });

    test('returns null for an unknown stable ID', () async {
      final Saint? saint = await repository.getById('not-in-bundled-data');

      expect(saint, isNull);
    });

    test('returns the bundled saint for January 4', () async {
      final List<Saint> saints = await repository.getByFeastDate(
        month: 1,
        day: 4,
      );

      expect(saints.map((Saint saint) => saint.id), <String>[
        'elizabeth-ann-seton',
      ]);
    });

    test('returns an empty list when no bundled saint matches', () async {
      final List<Saint> saints = await repository.getByFeastDate(
        month: 2,
        day: 1,
      );

      expect(saints, isEmpty);
    });

    test('returns every saint sharing the same feast date', () async {
      final SaintRepository multipleSaintRepository =
          _TestSaintRepository(<Saint>[
            _testSaint(id: 'first-saint', feastMonth: 5, feastDay: 12),
            _testSaint(id: 'second-saint', feastMonth: 5, feastDay: 12),
            _testSaint(id: 'different-date', feastMonth: 5, feastDay: 13),
          ]);

      final List<Saint> saints = await multipleSaintRepository.getByFeastDate(
        month: 5,
        day: 12,
      );

      expect(saints.map((Saint saint) => saint.id), <String>[
        'first-saint',
        'second-saint',
      ]);
    });

    test('rejects invalid feast dates', () async {
      await expectLater(
        repository.getByFeastDate(month: 13, day: 1),
        throwsRangeError,
      );
      await expectLater(
        repository.getByFeastDate(month: 2, day: 30),
        throwsRangeError,
      );
    });
  });
}

Map<String, dynamic> _minimalSaintJson({
  required int feastMonth,
  required int feastDay,
}) {
  return <String, dynamic>{
    'id': 'date-validation-saint',
    'displayName': 'Date Validation Saint',
    'feast': <String, dynamic>{'month': feastMonth, 'day': feastDay},
    'shortBiography': 'Test biography.',
    'patronages': <String>[],
    'sources': <Map<String, dynamic>>[
      <String, dynamic>{'label': 'Test source'},
    ],
  };
}

Saint _testSaint({
  required String id,
  required int feastMonth,
  required int feastDay,
}) {
  return Saint(
    id: id,
    displayName: 'Test Saint',
    feastMonth: feastMonth,
    feastDay: feastDay,
    shortBiography: 'Test biography.',
    patronages: const <String>[],
    sources: const <SaintSourceReference>[
      SaintSourceReference(label: 'Test source'),
    ],
  );
}

class _TestSaintRepository extends SaintRepository {
  _TestSaintRepository(this.saints);

  final List<Saint> saints;

  @override
  Future<List<Saint>> getAll() async => saints;
}
