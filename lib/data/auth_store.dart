import 'package:flutter/foundation.dart';

class UserAccount {
  String name;
  String email;
  String phone;
  String role;

  UserAccount({
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'Quản trị viên',
  });
}

/// Holds the signed-in account for the session. There is no real backend
/// yet, so `login` just creates a mock account for the demo credential.
class AuthStore extends ChangeNotifier {
  static final AuthStore instance = AuthStore._();

  AuthStore._();

  UserAccount? _currentUser;

  UserAccount? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void login(String username) {
    _currentUser = UserAccount(
      name: 'Admin',
      email: '$username@aqp.vn',
      phone: '090 123 4567',
    );
    notifyListeners();
  }

  void updateProfile({String? name, String? email, String? phone}) {
    final user = _currentUser;
    if (user == null) return;
    if (name != null && name.trim().isNotEmpty) user.name = name.trim();
    if (email != null && email.trim().isNotEmpty) user.email = email.trim();
    if (phone != null) user.phone = phone.trim();
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
