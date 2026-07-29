import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static Future<int> getProgress(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  static Future<void> saveProgress(
    String key,
    int progress,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, progress);
  }

  static Future<void> clearProgress(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}