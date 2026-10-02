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

  /// Shown until the agency has saved its own details (every field empty on
  /// the server). Saving from "Sửa thông tin" persists whatever is on screen.
  static const _default = {
    'companyName': 'Công ty Cổ phần Công nghệ TechVN',
    'registrationNo': '0102030405',
    'address': 'Tầng 3, Tòa nhà ABC, 123 Đường Trần Duy Hưng, Cầu Giấy, Hà Nội',
    'taxCode': '0102030405',
    'contactEmail': 'contact.techvn@gmail.com',
    'hotline': '19001234',
  };

  String companyName = _default['companyName']!;
  String registrationNo = _default['registrationNo']!;
  String address = _default['address']!;
  String taxCode = _default['taxCode']!;
  String contactEmail = _default['contactEmail']!;
  String hotline = _default['hotline']!;

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
    final hasOwnInfo = _default.keys.any((k) => (agency[k] ?? '').toString().trim().isNotEmpty);
    final Map<String, dynamic> src = hasOwnInfo ? agency : _default;
    companyName = src['companyName'] ?? '';
    registrationNo = src['registrationNo'] ?? '';
    address = src['address'] ?? '';
    taxCode = src['taxCode'] ?? '';
    contactEmail = src['contactEmail'] ?? '';
    hotline = src['hotline'] ?? '';
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
      final res = await http
          .patch(
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
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        hydrateFromAgency(json['agency']);
      } else {
        final json = jsonDecode(res.body);
        final message = (json['error'] as String?) ?? 'Lỗi cập nhật thông tin doanh nghiệp'.tr;
        throw Exception(message.tr);
      }
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
