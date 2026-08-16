import re

with open('/home/ubuntu/mobile/lib/data/auth_store.dart', 'r') as f:
    content = f.read()

# Add import
content = content.replace("import '../config/api_config.dart';", "import '../config/api_config.dart';\nimport 'video_preload_cache.dart';")

target_logout = """  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse("$_webOrigin/api/auth/logout"),
        headers: {
          if (authToken != null) "Cookie": "auth_token=$authToken",
        },
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    _currentUser = null;
    _token = null;
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("auth_token");
    notifyListeners();
  }"""

replacement_logout = """  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse("$_webOrigin/api/auth/logout"),
        headers: {
          if (authToken != null) "Cookie": "auth_token=$authToken",
        },
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}

    _currentUser = null;
    _token = null;
    _authToken = null;
    VideoPreloadCache.instance.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("auth_token");
    notifyListeners();
  }"""

content = content.replace(target_logout, replacement_logout)

with open('/home/ubuntu/mobile/lib/data/auth_store.dart', 'w') as f:
    f.write(content)

print("Patched auth_store.dart")
