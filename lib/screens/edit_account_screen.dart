import 'package:flutter/material.dart';

import '../data/auth_store.dart';
import '../data/business_info_store.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

class EditAccountScreen extends StatefulWidget {
  const EditAccountScreen({super.key});

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  late final TextEditingController _companyNameController;
  late final TextEditingController _registrationNoController;
  late final TextEditingController _addressController;
  late final TextEditingController _taxCodeController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _hotlineController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AuthStore.instance.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');

    final biz = BusinessInfoStore.instance;
    _companyNameController = TextEditingController(text: biz.companyName);
    _registrationNoController = TextEditingController(text: biz.registrationNo);
    _addressController = TextEditingController(text: biz.address);
    _taxCodeController = TextEditingController(text: biz.taxCode);
    _contactEmailController = TextEditingController(text: biz.contactEmail);
    _hotlineController = TextEditingController(text: biz.hotline);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _registrationNoController.dispose();
    _addressController.dispose();
    _taxCodeController.dispose();
    _contactEmailController.dispose();
    _hotlineController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AuthStore.instance.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      );
      await BusinessInfoStore.instance.save(
        companyName: _companyNameController.text,
        registrationNo: _registrationNoController.text,
        address: _addressController.text,
        taxCode: _taxCodeController.text,
        contactEmail: _contactEmailController.text,
        hotline: _hotlineController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textPrimary,
          content: Text('Đã cập nhật thông tin'.tr, style: const TextStyle(color: Colors.white)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        'Chỉnh sửa thông tin'.tr,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    _GroupLabel('Thông tin cá nhân'.tr),
                    const SizedBox(height: 10),
                    _FieldLabel('Họ và tên'.tr),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _decoration('Nhập họ và tên'.tr),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên'.tr : null,
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Email'.tr),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      readOnly: true,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AppColors.textMuted),
                      decoration: _decoration('you@example.com'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email'.tr;
                        if (!v.contains('@')) return 'Email không hợp lệ'.tr;
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Số điện thoại'.tr),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _decoration('090 xxx xxxx'),
                    ),

                    const SizedBox(height: 24),
                    _GroupLabel('Thông tin doanh nghiệp'.tr),
                    const SizedBox(height: 10),
                    _FieldLabel('Tên doanh nghiệp'.tr),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _companyNameController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _decoration('VD: Công ty TNHH ABC'.tr),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Giấy chứng nhận ĐKKD'.tr),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _registrationNoController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _decoration('Số giấy chứng nhận đăng ký kinh doanh'.tr),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Trụ sở chính'.tr),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      minLines: 1,
                      maxLines: 3,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _decoration('Địa chỉ trụ sở chính'.tr),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Mã số thuế'.tr),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _taxCodeController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _decoration('VD: 0102030405'),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Email liên hệ'.tr),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _contactEmailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _decoration('contact@congty.com'),
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('Hotline hỗ trợ'.tr),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _hotlineController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _decoration('19002625'),
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: AppColors.accentGradient,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _saving ? null : _save,
                            child: Center(
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'Lưu thay đổi'.tr,
                                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.danger),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary));
  }
}
