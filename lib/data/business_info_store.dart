import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/app_strings.dart';

/// Business/company identity for the signed-in account's agency
/// ("Thông tin doanh nghiệp"), shared across every user under the agency.
/// Backed by `GET/PATCH /api/v1/agency`. Hydrated from the `agency` object
/// already returned by `/auth/me` (see [hydrateFromAgency], called by
/// `AuthStore.fetchProfile`) — saving goes through [save].
class BusinessInfoStore extends ChangeNotifier {
  static final BusinessInfoStore instance = BusinessInfoStore._();
  BusinessInfoStore._();

  String companyName = '';
  String registrationNo = '';
  String address = '';
  String taxCode = '';
  String contactEmail = '';
  String hotline = '';

  bool saving = false;

  String get _baseUrl => ApiConfig.apiV1Base;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Populates fields from the `agency` object of an `/auth/me` response —
  /// avoids a second network round trip for data AuthStore already fetched.
  void hydrateFromAgency(Map<String, dynamic>? agency) {
    if (agency == null) return;
    companyName = agency['companyName'] ?? '';
    registrationNo = agency['registrationNo'] ?? '';
    address = agency['address'] ?? '';
    taxCode = agency['taxCode'] ?? '';
    contactEmail = agency['contactEmail'] ?? '';
    hotline = agency['hotline'] ?? '';
    notifyListeners();
  }

  Future<void> save({
    String? companyName,
    String? registrationNo,
    String? address,
    String? taxCode,
    String? contactEmail,
    String? hotline,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Chưa đăng nhập'.tr);

    saving = true;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseUrl/agency');
      final res = await http.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (companyName != null) 'companyName': companyName.trim(),
          if (registrationNo != null) 'registrationNo': registrationNo.trim(),
          if (address != null) 'address': address.trim(),
          if (taxCode != null) 'taxCode': taxCode.trim(),
          if (contactEmail != null) 'contactEmail': contactEmail.trim(),
          if (hotline != null) 'hotline': hotline.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        hydrateFromAgency(json['agency']);
      } else {
        final json = jsonDecode(res.body);
        final message = (json['error'] as String?) ?? 'Lỗi cập nhật thông tin doanh nghiệp';
        throw Exception(message.tr);
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
