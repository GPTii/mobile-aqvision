import 'package:flutter/material.dart';

import '../data/camera_store.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

/// Opens the shared add/edit camera form. Pass [camera] to edit an existing
/// one, or omit it to create a new camera (optionally pre-selecting
/// [initialGroupId], e.g. when adding from within a room section).
Future<void> showCameraFormSheet(
  BuildContext context, {
  Camera? camera,
  String? initialGroupId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CameraFormSheet(
      camera: camera,
      initialGroupId: initialGroupId,
    ),
  );
}

class _CameraFormSheet extends StatefulWidget {
  final Camera? camera;
  final String? initialGroupId;

  const _CameraFormSheet({this.camera, this.initialGroupId});

  @override
  State<_CameraFormSheet> createState() => _CameraFormSheetState();
}

class _CameraFormSheetState extends State<_CameraFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _ipController;
  late final TextEditingController _newGroupController;
  late final TextEditingController _locationController;
  late final TextEditingController _mapLinkController;

  List<String> _selectedGroupIds = [];
  bool _creatingNewGroup = false;
  bool _isLoading = false;
  late bool _recording;

  bool get _isEditing => widget.camera != null;

  @override
  void initState() {
    super.initState();
    final camera = widget.camera;
    _codeController = TextEditingController(
      text: camera?.cameraCode ?? '',
    );
    _ipController = TextEditingController(
      text: camera?.ipAddress ?? 'rtsp://',
    );
    _newGroupController = TextEditingController();
    _locationController = TextEditingController(text: camera?.location ?? '');
    _mapLinkController = TextEditingController(text: camera?.mapLink ?? '');
    _recording = camera?.recording ?? false;

    final groups = CameraStore.instance.groups;
    final preselect = widget.initialGroupId;
    _selectedGroupIds = camera?.groupIds.toList() ?? [];
    if (_selectedGroupIds.isEmpty && preselect != null && groups.any((g) => g.id == preselect)) {
      _selectedGroupIds.add(preselect);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _ipController.dispose();
    _newGroupController.dispose();
    _locationController.dispose();
    _mapLinkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final groupIdsToSave = List<String>.from(_selectedGroupIds);
      if (_creatingNewGroup && _newGroupController.text.trim().isNotEmpty) {
        final newGroup = await CameraStore.instance.addGroup(_newGroupController.text);
        groupIdsToSave.add(newGroup.id);
      }

      if (_isEditing) {
        await CameraStore.instance.updateCamera(
          widget.camera!.id,
          name: _codeController.text,
          cameraCode: _codeController.text,
          ipAddress: _ipController.text,
          groupIds: groupIdsToSave,
          recording: _recording,
          location: _locationController.text.trim(),
          mapLink: _mapLinkController.text.trim(),
        );
      } else {
        await CameraStore.instance.addCamera(
          name: _codeController.text,
          cameraCode: _codeController.text,
          type: kCameraTypes.first,
          ipAddress: _ipController.text,
          location: _locationController.text.trim(),
          mapLink: _mapLinkController.text.trim(),
          groupIds: groupIdsToSave,
          recording: _recording,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = CameraStore.instance.groups;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      _isEditing ? 'Sửa thông tin camera'.tr : 'Thêm camera mới'.tr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 20),
                    _FieldLabel('Tên luồng (Stream ID)'.tr),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _codeController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _fieldDecoration('VD: cam_cong_chinh'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? 'Vui lòng nhập Stream ID'.tr : null,
                    ),
                    SizedBox(height: 16),
                    _FieldLabel('Nguồn RTSP / URL'.tr),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _ipController,
                      keyboardType: TextInputType.url,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _fieldDecoration('rtsp://user:pass@192.168.1.100/stream'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập URL nguồn'.tr;
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _FieldLabel('Vị trí lắp đặt'.tr),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _fieldDecoration('VD: Cổng trước, tầng 1'.tr),
                    ),
                    SizedBox(height: 16),
                    _FieldLabel('Link Google Maps'.tr),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _mapLinkController,
                      keyboardType: TextInputType.url,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: _fieldDecoration('https://maps.app.goo.gl/...'),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return null;
                        final uri = Uri.tryParse(v);
                        if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
                          return 'Link không hợp lệ (phải bắt đầu bằng https://)'.tr;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    _FieldLabel('Nhóm / phòng'.tr),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final group in groups)
                          FilterChip(
                            label: Text(group.displayName,
                                style: TextStyle(
                                    color: _selectedGroupIds.contains(group.id)
                                        ? AppColors.accent
                                        : AppColors.textPrimary)),
                            selected: _selectedGroupIds.contains(group.id),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedGroupIds.add(group.id);
                                } else {
                                  _selectedGroupIds.remove(group.id);
                                }
                              });
                            },
                            selectedColor: AppColors.accent.withOpacity(0.15),
                            checkmarkColor: AppColors.accent,
                            backgroundColor: AppColors.card,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ActionChip(
                          label: Text('+ Tạo nhóm mới'.tr,
                              style: TextStyle(color: _creatingNewGroup ? AppColors.accent : AppColors.textSecondary)),
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onPressed: () => setState(() => _creatingNewGroup = !_creatingNewGroup),
                        ),
                      ],
                    ),
                    if (_creatingNewGroup) ...[
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _newGroupController,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: _fieldDecoration('Tên nhóm mới'.tr),
                        validator: (value) {
                          if (!_creatingNewGroup) return null;
                          return (value == null || value.trim().isEmpty) ? 'Vui lòng nhập tên nhóm'.tr : null;
                        },
                      ),
                    ],
                    SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.accent,
                      title: Text(
                        'Ghi hình (MP4)'.tr,
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _recording ? 'Đang bật ghi hình'.tr : 'Tắt ghi hình'.tr,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      value: _recording,
                      onChanged: (value) => setState(() => _recording = value),
                    ),
                    SizedBox(height: 12),
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
                            onTap: _isLoading ? null : _save,
                            child: Center(
                              child: Text(
                                _isLoading ? 'Đang lưu...'.tr : (_isEditing ? 'Lưu thay đổi'.tr : 'Thêm camera'.tr),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
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
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String? hint) {
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

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
