import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../data/auth_store.dart';
import '../../theme/app_colors.dart';
import '../home/home_shell.dart';
import '../../utils/app_strings.dart';
import '../../widgets/app_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late bool _isLocal;
  late final TextEditingController _localIpController;
  late final TextEditingController _localPortController;
  late String _localScheme;
  bool _isTestingConnection = false;
  bool? _connectionSuccess;

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _isLocal = ApiConfig.isLocal;
    _localIpController = TextEditingController(text: ApiConfig.localIp);
    _localPortController = TextEditingController(text: '${ApiConfig.localPort}');
    _localScheme = ApiConfig.localScheme;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _localIpController.dispose();
    _localPortController.dispose();
    super.dispose();
  }

  Future<void> _testLocalConnection() async {
    FocusScope.of(context).unfocus();
    final ip = _localIpController.text.trim();
    final port = int.tryParse(_localPortController.text.trim()) ?? 3000;
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập IP máy chủ local'.tr)),
      );
      return;
    }
    setState(() {
      _isTestingConnection = true;
      _connectionSuccess = null;
    });

    final targetOrigin = '$_localScheme://$ip:$port';
    final ok = await ApiConfig.testConnection(targetOrigin);
    if (!mounted) return;
    setState(() {
      _isTestingConnection = false;
      _connectionSuccess = ok;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        content: Text(
          ok
              ? 'Kết nối máy chủ $targetOrigin thành công!'.tr
              : 'Không thể kết nối tới $targetOrigin. Hãy kiểm tra lại IP/Port.'.tr,
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isLocal) {
      final ip = _localIpController.text.trim();
      final port = int.tryParse(_localPortController.text.trim());
      if (ip.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng nhập địa chỉ IP cho máy chủ local'.tr)),
        );
        return;
      }
      if (port == null || port <= 0 || port > 65535) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cổng (Port) không hợp lệ (1 - 65535)'.tr)),
        );
        return;
      }
      await ApiConfig.setServerConfig(
        mode: 'local',
        ip: ip,
        port: port,
        scheme: _localScheme,
      );
    } else {
      await ApiConfig.setServerConfig(mode: 'cloud');
    }

    if (!mounted) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final username = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      await AuthStore.instance.login(username, password);

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.toString().replaceAll("Exception: ", ""),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AppBackground(
        child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Soft brand-color tint at the top of an otherwise plain white page.
          Positioned(
            top: -size.width * 0.5,
            left: -size.width * 0.2,
            right: -size.width * 0.2,
            child: IgnorePointer(
              child: Container(
                height: size.width * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.07),
                      AppColors.accent.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [_buildLoginCard()],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppColors.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Đăng nhập'.tr,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Truy cập hệ thống camera của bạn'.tr,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _buildServerSelector(),
          const SizedBox(height: 20),
          _buildLabel('Email hoặc tên đăng nhập'.tr),
          SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'you@example.com',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email hoặc tên đăng nhập'.tr;
              }
              return null;
            },
          ),
          SizedBox(height: 18),
          _buildLabel('Mật khẩu'.tr),
          SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu'.tr;
              }
              if (value.length < 4) {
                return 'Mật khẩu phải có ít nhất 4 ký tự'.tr;
              }
              return null;
            },
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) => setState(() => _rememberMe = value ?? false),
                  activeColor: AppColors.accent,
                  checkColor: Colors.white,
                  side: BorderSide(color: AppColors.border, width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  'Ghi nhớ'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Quên mật khẩu?'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.danger, width: 1.4),
        ),
        errorStyle: TextStyle(color: AppColors.danger, fontSize: 12),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppColors.accentGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.28),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _isLoading ? null : _handleLogin,
            child: Center(
              child: _isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      'Đăng nhập'.tr,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerSelector() {
    final curIp = _localIpController.text.trim();
    final curPort = _localPortController.text.trim();
    final targetUrlPreview = '$_localScheme://${curIp.isEmpty ? "192.168.1.xxx" : curIp}:${curPort.isEmpty ? "3000" : curPort}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'MÁY CHỦ KẾT NỐI'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (!_isLocal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'dev1.aqvision.net',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Segmented button for Cloud vs Local
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isLocal) {
                        setState(() {
                          _isLocal = false;
                          _connectionSuccess = null;
                        });
                        ApiConfig.setServerConfig(mode: 'cloud');
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isLocal ? AppColors.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: !_isLocal
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_outlined,
                            size: 16,
                            color: !_isLocal ? AppColors.accent : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Cloud (dev1)'.tr,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: !_isLocal ? FontWeight.w700 : FontWeight.w500,
                              color: !_isLocal ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isLocal) {
                        setState(() {
                          _isLocal = true;
                          _connectionSuccess = null;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isLocal ? AppColors.card : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: _isLocal
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lan_outlined,
                            size: 16,
                            color: _isLocal ? AppColors.accent : AppColors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Local Server'.tr,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: _isLocal ? FontWeight.w700 : FontWeight.w500,
                              color: _isLocal ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLocal) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Scheme toggle: HTTP / HTTPS
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: PopupMenuButton<String>(
                    initialValue: _localScheme,
                    tooltip: 'Giao thức'.tr,
                    onSelected: (val) {
                      setState(() {
                        _localScheme = val;
                        _connectionSuccess = null;
                      });
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'http', child: Text('http://')),
                      const PopupMenuItem(value: 'https', child: Text('https://')),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Text(
                            '$_localScheme://',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // IP input
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 48,
                    child: TextFormField(
                      controller: _localIpController,
                      style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      keyboardType: TextInputType.text,
                      onChanged: (_) {
                        if (_connectionSuccess != null) setState(() => _connectionSuccess = null);
                      },
                      decoration: InputDecoration(
                        hintText: '192.168.1.xxx',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        prefixIcon: Icon(Icons.dns_outlined, size: 18, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent, width: 1.4)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Port input
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 48,
                    child: TextFormField(
                      controller: _localPortController,
                      style: TextStyle(fontSize: 13.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                        if (_connectionSuccess != null) setState(() => _connectionSuccess = null);
                      },
                      decoration: InputDecoration(
                        hintText: '3000',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        prefixIcon: Icon(Icons.numbers_rounded, size: 17, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.accent, width: 1.4)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Preview & Test Connection button
            Row(
              children: [
                Expanded(
                  child: Text(
                    targetUrlPreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _isTestingConnection ? null : _testLocalConnection,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isTestingConnection)
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          )
                        else if (_connectionSuccess == true)
                          Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success)
                        else if (_connectionSuccess == false)
                          Icon(Icons.cancel_rounded, size: 14, color: AppColors.danger)
                        else
                          Icon(Icons.network_check_rounded, size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(
                          _isTestingConnection
                              ? 'Đang kiểm tra...'.tr
                              : _connectionSuccess == true
                                  ? 'Kết nối tốt'.tr
                                  : 'Kiểm tra'.tr,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _connectionSuccess == true
                                ? AppColors.success
                                : _connectionSuccess == false
                                    ? AppColors.danger
                                    : AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
