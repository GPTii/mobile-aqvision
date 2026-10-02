import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/app_strings.dart';

/// Server sometimes returns a root-relative path (e.g. "/uploads/x.jpg")
/// instead of a full URL — browsers resolve that against the page origin
/// automatically, but Flutter's Image.network does not, so it fails silently.
/// Prepend the API origin ourselves when we see one.
String resolveNewsImageUrl(String url) {
  if (url.startsWith('/')) return '${ApiConfig.origin}$url';
  return url;
}

class NewsArticle {
  final String id;
  final String title;
  final String excerpt;
  final String? body;
  final String coverImageUrl;
  final String? category;
  final bool isFeatured;
  final DateTime publishedAt;
  final String source;
  final int? viewCount;

  NewsArticle({
    required this.id,
    required this.title,
    required this.excerpt,
    this.body,
    required this.coverImageUrl,
    this.category,
    required this.isFeatured,
    required this.publishedAt,
    required this.source,
    this.viewCount,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: (json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      excerpt: json['excerpt'] ?? '',
      body: json['body'],
      coverImageUrl: resolveNewsImageUrl((json['coverImageUrl'] ?? '').toString()),
      category: json['category'],
      isFeatured: json['isFeatured'] == true,
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? '') ?? DateTime.now(),
      source: (json['source'] ?? 'AQ Vision').toString(),
      viewCount: json['viewCount'] is num ? (json['viewCount'] as num).toInt() : null,
    );
  }

  /// "dd/MM/yyyy · HH:mm" — matches the approved News tab design.
  String get dateLabel {
    final d = publishedAt;
    final date = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final time = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }
}

/// News feed backed by `GET /api/v1/news`.
class NewsStore extends ChangeNotifier {
  static final NewsStore instance = NewsStore._();
  NewsStore._();

  List<NewsArticle> articles = [];
  bool loading = false;
  String? error;

  /// Banner-carousel candidates — articles flagged `isFeatured` by the server.
  List<NewsArticle> get featured => articles.where((a) => a.isFeatured).toList();

  String get _baseUrl => ApiConfig.apiV1Base;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void>? _inFlight;

  Future<void> fetchNews() {
    return _inFlight ??= _doFetchNews().whenComplete(() => _inFlight = null);
  }

  Future<void> _doFetchNews() async {
    final token = await _getToken();
    if (token == null) {
      error = 'Chưa đăng nhập'.tr;
      notifyListeners();
      return;
    }

    loading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/news').replace(queryParameters: {
        'page': '1',
        'limit': '20',
      });
      final res = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List data = json['data'] ?? [];
        articles = data.map((e) => NewsArticle.fromJson(e)).toList()
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        for (final a in articles) {
          debugPrint('[NEWS] "${a.title}" coverImageUrl = "${a.coverImageUrl}"');
        }
        error = null;
      } else {
        error = 'Không tải được tin tức'.tr;
      }
    } catch (e) {
      error = 'Không tải được tin tức'.tr;
    }

    loading = false;
    notifyListeners();
  }

  /// Full article (with Markdown `body`) from `GET /api/v1/news/:id` —
  /// the list endpoint omits `body` to keep the feed payload light.
  Future<NewsArticle> fetchArticle(String id) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập'.tr);

    final res = await http.get(Uri.parse('$_baseUrl/news/$id'), headers: {
      'Authorization': 'Bearer $token',
    }).timeout(const Duration(seconds: 10));

    if (res.statusCode != 200) throw Exception('Không tải được bài viết'.tr);
    return NewsArticle.fromJson(jsonDecode(res.body)['data']);
  }

  /// Fire-and-forget view counter (`POST /api/v1/news/:id/view`).
  Future<void> recordView(String id) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      await http.post(Uri.parse('$_baseUrl/news/$id/view'), headers: {
        'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[NEWS] recordView failed for $id: $e');
    }
  }
}
