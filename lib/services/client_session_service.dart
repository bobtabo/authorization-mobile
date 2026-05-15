import 'package:shared_preferences/shared_preferences.dart';

class ClientSessionService {
  static const _keyIdentifier = 'client_identifier';
  static const _keySlug = 'client_slug';

  static Future<({String slug, String identifier})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final identifier = prefs.getString(_keyIdentifier);
    final slug = prefs.getString(_keySlug);
    if (identifier == null || slug == null) return null;
    return (slug: slug, identifier: identifier);
  }

  static Future<void> save(String slug, String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySlug, slug);
    await prefs.setString(_keyIdentifier, identifier);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIdentifier);
    await prefs.remove(_keySlug);
  }
}
