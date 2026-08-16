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
  });

  group('SaintRepository', () {
    final SaintRepository repository = SaintRepository();

    test('loads the bundled sample saint by stable ID', () async {
      final Saint? saint = await repository.getById('elizabeth-ann-seton');

      expect(saint, isNotNull);
      expect(saint!.id, 'elizabeth-ann-seton');
      expect(saint.displayName, 'Saint Elizabeth Ann Seton');
      expect(saint.feastMonth, 1);
      expect(saint.feastDay, 4);
      expect(saint.shortBiography, startsWith('TEMPORARY SAMPLE CONTENT:'));
      expect(saint.patronages, isEmpty);
      expect(saint.sources, hasLength(1));
      expect(saint.sources.single.attribution, contains('sample data'));
    });

    test('returns null for an unknown stable ID', () async {
      final Saint? saint = await repository.getById('not-in-bundled-data');

      expect(saint, isNull);
    });
  });
}
