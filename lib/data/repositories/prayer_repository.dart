import '../../models/prayer.dart';

import '../prayers/daily_prayers.dart';
import '../prayers/pray_with_me_prayers.dart';
import '../prayers/traditional_prayers.dart';

class PrayerRepository {
  static final List<Prayer> prayers = [
    ...prayWithMePrayers,
    ...traditionalPrayers,
    ...dailyPrayers,
  ];

  static Prayer getById(String id) {
    return prayers.firstWhere(
      (prayer) => prayer.id == id,
    );
  }

  static List<Prayer> getByCategory(String category) {
    return prayers
        .where((prayer) => prayer.category == category)
        .toList();
  }

  static List<Prayer> search(String query) {
    final search = query.toLowerCase();

    return prayers.where((prayer) {
      return prayer.title.toLowerCase().contains(search) ||
          prayer.tags.any(
            (tag) => tag.toLowerCase().contains(search),
          );
    }).toList();
  }
}