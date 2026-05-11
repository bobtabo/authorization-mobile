import 'package:shared_preferences/shared_preferences.dart';
import '../config/backends.dart';

class BackendService {
  static const _key = 'selected_backend_slug';

  static Future<BackendOption> load() async {
    final prefs = await SharedPreferences.getInstance();
    final slug = prefs.getString(_key);
    if (slug == null) return kDefaultBackend;
    return kBackends.firstWhere(
      (b) => b.slug == slug,
      orElse: () => kDefaultBackend,
    );
  }

  static Future<void> save(BackendOption backend) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, backend.slug);
  }
}
