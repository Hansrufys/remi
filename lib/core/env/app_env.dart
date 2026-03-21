import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyGeminiApiKey = 'remi_gemini_api_key';
const _keySupabaseUrl = 'remi_supabase_url';
const _keySupabaseAnonKey = 'remi_supabase_anon_key';
const _keyIsProUser = 'remi_is_pro_user';
const _keyFallbackTimezone = 'remi_fallback_timezone';

/// Manages app environment configuration, securely.
class AppEnv {
  AppEnv._();
  static const _storage = FlutterSecureStorage();

  static Future<String?> getGeminiApiKey() =>
      _storage.read(key: _keyGeminiApiKey);

  static Future<void> setGeminiApiKey(String key) =>
      _storage.write(key: _keyGeminiApiKey, value: key);

  static Future<void> clearGeminiApiKey() =>
      _storage.delete(key: _keyGeminiApiKey);

  // Pro Status
  static Future<bool> isProUser() async {
    final value = await _storage.read(key: _keyIsProUser);
    return value == 'true';
  }

  static Future<void> setProUser(bool isPro) =>
      _storage.write(key: _keyIsProUser, value: isPro.toString());

  // Supabase
  static Future<String?> getSupabaseUrl() async {
    final stored = await _storage.read(key: _keySupabaseUrl);
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  static Future<void> setSupabaseUrl(String? url) async {
    if (url == null || url.isEmpty) {
      await _storage.delete(key: _keySupabaseUrl);
    } else {
      await _storage.write(key: _keySupabaseUrl, value: url);
    }
  }

  static Future<String?> getSupabaseAnonKey() async {
    final stored = await _storage.read(key: _keySupabaseAnonKey);
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  static Future<void> setSupabaseAnonKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _storage.delete(key: _keySupabaseAnonKey);
    } else {
      await _storage.write(key: _keySupabaseAnonKey, value: key);
    }
  }

  static Future<void> clearSupabaseConfig() async {
    await _storage.delete(key: _keySupabaseUrl);
    await _storage.delete(key: _keySupabaseAnonKey);
  }

  static const String defaultFallbackTimezone = 'Europe/Berlin';

  static Future<String> getFallbackTimezone() async {
    final stored = await _storage.read(key: _keyFallbackTimezone);
    return (stored == null || stored.isEmpty) ? defaultFallbackTimezone : stored;
  }

  static Future<void> setFallbackTimezone(String timezone) =>
      _storage.write(key: _keyFallbackTimezone, value: timezone);
}
