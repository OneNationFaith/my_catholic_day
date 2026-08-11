import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/util/legacy_to_async_migration_util.dart';

class UserPreferencesService {
  UserPreferencesService._();

  static const String _nameKey = 'user_display_name';
  static const String _namePromptedKey = 'user_display_name_prompted';
  static const String _stateCodeKey = 'user_state_code';
  static const String _statePromptedKey = 'user_state_prompted';
  static const String _migrationCompletedKey =
      'onf_preferences_async_migration_v1';

  static const SharedPreferencesOptions _options =
      SharedPreferencesOptions();

  static final SharedPreferencesAsync _preferences =
      SharedPreferencesAsync(options: _options);

  static Future<void>? _initializationFuture;

  static Future<void> initialize() {
    return _initializationFuture ??= _migrateLegacyPreferences();
  }

  static Future<void> _migrateLegacyPreferences() async {
    final SharedPreferences legacyPreferences =
        await SharedPreferences.getInstance();

    await migrateLegacySharedPreferencesToSharedPreferencesAsyncIfNecessary(
      legacySharedPreferencesInstance: legacyPreferences,
      sharedPreferencesAsyncOptions: _options,
      migrationCompletedKey: _migrationCompletedKey,
    );
  }

  static Future<String?> loadName() async {
    await initialize();

    final String? savedName =
        (await _preferences.getString(_nameKey))?.trim();

    if (savedName == null || savedName.isEmpty) {
      return null;
    }

    return savedName;
  }

  static Future<bool> hasPromptedForName() async {
    await initialize();
    return await _preferences.getBool(_namePromptedKey) ?? false;
  }

  static Future<void> saveName(String name) async {
    await initialize();

    final String trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      await skipName();
      return;
    }

    await _preferences.setString(_nameKey, trimmedName);
    await _preferences.setBool(_namePromptedKey, true);
  }

  static Future<void> skipName() async {
    await initialize();

    await _preferences.remove(_nameKey);
    await _preferences.setBool(_namePromptedKey, true);
  }

  static Future<String?> loadStateCode() async {
    await initialize();

    final String? savedStateCode =
        (await _preferences.getString(_stateCodeKey))?.trim().toUpperCase();

    if (savedStateCode == null || savedStateCode.isEmpty) {
      return null;
    }

    return savedStateCode;
  }

  static Future<bool> hasPromptedForState() async {
    await initialize();

    final String? savedStateCode = await loadStateCode();
    if (savedStateCode != null) {
      return true;
    }

    return await _preferences.getBool(_statePromptedKey) ?? false;
  }

  static Future<void> saveStateCode(String stateCode) async {
    await initialize();

    final String normalizedStateCode = stateCode.trim().toUpperCase();

    if (normalizedStateCode.isEmpty) {
      await useNationalDefault();
      return;
    }

    await _preferences.setString(
      _stateCodeKey,
      normalizedStateCode,
    );
    await _preferences.setBool(_statePromptedKey, true);
  }

  static Future<void> useNationalDefault() async {
    await initialize();

    await _preferences.remove(_stateCodeKey);
    await _preferences.setBool(_statePromptedKey, true);
  }

  static Future<void> clearStateCode() async {
    await useNationalDefault();
  }
}
