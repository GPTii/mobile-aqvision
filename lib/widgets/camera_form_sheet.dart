import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/camera_store.dart';
import '../theme/app_colors.dart';

const _resolutions = ['720p', '1080p', '4K'];
final _ipRegExp = RegExp(
  r'^(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)){3}$',
);

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
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _ipController;
  late final TextEditingController _locationController;
  late final TextEditingController _newGroupController;

  List<String> _selectedGroupIds = [];
  bool _creatingNewGroup = false;
  bool _isLoading = false;
  late String _type;
  late String _resolution;
  late bool _online;
  late bool _recording;

  bool get _isEditing => widget.camera != null;

  @override
  void initState() {
    super.initState();
    final camera = widget.camera;
    _nameController = TextEditingController(text: camera?.name ?? '');
    _codeController = TextEditingController(
      text: camera?.cameraCode ?? CameraStore.instance.suggestCameraCode(),
    );
    _ipController = TextEditingController(
      text: camera?.ipAddress ?? CameraStore.instance.suggestIpAddress(),
    );
    _locationController = TextEditingController(text: camera?.location ?? '');
    _newGroupController = TextEditingController();
    _type = camera?.type ?? kCameraTypes.first;
    _resolution = camera?.resolution ?? _resolutions[1];
    _online = camera?.online ?? true;
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
    _nameController.dispose();
    _codeController.dispose();
    _ipController.dispose();
    _locationController.dispose();
    _newGroupController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final groupIdsToSave = List<String>.from(_selectedGroupIds);
    if (_creatingNewGroup && _newGroupController.text.trim().isNotEmpty) {
      final newGroup = await CameraStore.instance.addGroup(_newGroupController.text);
      groupIdsToSave.add(newGroup.id);
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditing) {
        await CameraStore.instance.updateCamera(
          widget.camera!.id,
          name: _nameController.text,
          cameraCode: _codeController.text,
          type: _type,
          ipAddress: _ipController.text,
          location: _locationController.text,
          groupIds: groupIdsToSave,
          resolution: _resolution,
          online: _online,
          recording: _recording,
        );
      } else {
        await CameraStore.instance.addCamera(
          name: _nameController.text,
          cameraCode: _codeController.text,
          type: _type,
          ipAddress: _ipController.text,
          location: _locationController.text,
          groupIds: groupIdsToSave,
          resolution: _resolution,
          online: _online,
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
        decoration: const BoxDecoration(
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
                      _isEditing ? 'Sửa thông tin camera' : 'Thêm camera mới',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Tên camera'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _fieldDecoration('VD: Cam cổng chính'),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Vui lòng nhập tên camera'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Camera ID'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _codeController,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: _fieldDecoration('VD: CAM-0001'),
                                validator: (value) => (value == null || value.trim().isEmpty)
                                    ? 'Bắt buộc'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _FieldLabel('Địa chỉ IP'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _ipController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                                ],
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: _fieldDecoration('VD: 192.168.1.101'),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'Bắt buộc';
                                  if (!_ipRegExp.hasMatch(value.trim())) return 'IP không hợp lệ';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Loại camera'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _type,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
                      dropdownColor: AppColors.card,
                      decoration: _fieldDecoration(null),
                      items: [
                        for (final type in kCameraTypes)
                          DropdownMenuItem(value: type, child: Text(type)),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _type = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Vị trí lắp đặt'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _fieldDecoration('VD: Góc trái, gần cửa ra vào'),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Vui lòng nhập vị trí lắp đặt'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Nhóm / phòng'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final group in groups)
                          FilterChip(
                            label: Text(group.name, style: TextStyle(color: _selectedGroupIds.contains(group.id) ? AppColors.accent : AppColors.textPrimary)),
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
                          label: Text('+ Tạo nhóm mới', style: TextStyle(color: _creatingNewGroup ? AppColors.accent : AppColors.textSecondary)),
                          backgroundColor: AppColors.card,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onPressed: () => setState(() => _creatingNewGroup = !_creatingNewGroup),
                        ),
                      ],
                    ),
                    if (_creatingNewGroup) ...[
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _newGroupController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _fieldDecoration('Tên nhóm mới'),
                        validator: (value) {
                          if (!_creatingNewGroup) return null;
                          return (value == null || value.trim().isEmpty)
                              ? 'Vui lòng nhập tên nhóm'
                              : null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    _FieldLabel('Độ phân giải'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final res in _resolutions) ...[
                          Expanded(
                            child: _ResolutionChip(
                              label: res,
                              selected: _resolution == res,
                              onTap: () => setState(() => _resolution = res),
                            ),
                          ),
                          if (res != _resolutions.last) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.accent,
                      title: const Text(
                        'Trạng thái: Online',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _online ? 'Camera đang hoạt động' : 'Camera đang offline',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      value: _online,
                      onChanged: (value) => setState(() => _online = value),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.accent,
                      title: const Text(
                        'Đang ghi hình',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      value: _recording,
                      onChanged: (value) => setState(() => _recording = value),
                    ),
                    const SizedBox(height: 12),
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
                                _isLoading ? 'Đang lưu...' : (_isEditing ? 'Lưu thay đổi' : 'Thêm camera'),
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
      hintStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
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
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _ResolutionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ResolutionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.accent.withOpacity(0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.accent : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
