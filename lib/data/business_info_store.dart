import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-entered business/company identity shown on the account screen
/// ("Thông tin doanh nghiệp"). No backend endpoint exists for this yet —
/// persisted locally only, per device.
class BusinessInfoStore extends ChangeNotifier {
  static final BusinessInfoStore instance = BusinessInfoStore._();
  BusinessInfoStore._();

  static const _kCompanyName = 'biz_company_name';
  static const _kRegistrationNo = 'biz_registration_no';
  static const _kAddress = 'biz_address';
  static const _kTaxCode = 'biz_tax_code';
  static const _kContactEmail = 'biz_contact_email';
  static const _kHotline = 'biz_hotline';

  String companyName = '';
  String registrationNo = '';
  String address = '';
  String taxCode = '';
  String contactEmail = '';
  String hotline = '';
  bool _loaded = false;

  bool get hasAnyData =>
      companyName.isNotEmpty ||
      registrationNo.isNotEmpty ||
      address.isNotEmpty ||
      taxCode.isNotEmpty ||
      contactEmail.isNotEmpty ||
      hotline.isNotEmpty;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    companyName = prefs.getString(_kCompanyName) ?? '';
    registrationNo = prefs.getString(_kRegistrationNo) ?? '';
    address = prefs.getString(_kAddress) ?? '';
    taxCode = prefs.getString(_kTaxCode) ?? '';
    contactEmail = prefs.getString(_kContactEmail) ?? '';
    hotline = prefs.getString(_kHotline) ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> save({
    required String companyName,
    required String registrationNo,
    required String address,
    required String taxCode,
    required String contactEmail,
    required String hotline,
  }) async {
    this.companyName = companyName.trim();
    this.registrationNo = registrationNo.trim();
    this.address = address.trim();
    this.taxCode = taxCode.trim();
    this.contactEmail = contactEmail.trim();
    this.hotline = hotline.trim();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCompanyName, this.companyName);
    await prefs.setString(_kRegistrationNo, this.registrationNo);
    await prefs.setString(_kAddress, this.address);
    await prefs.setString(_kTaxCode, this.taxCode);
    await prefs.setString(_kContactEmail, this.contactEmail);
    await prefs.setString(_kHotline, this.hotline);
  }
}
