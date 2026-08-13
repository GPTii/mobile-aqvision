import 'package:flutter/material.dart';

import '../data/camera_store.dart';
import '../theme/app_colors.dart';


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
        );
      } else {
        await CameraStore.instance.addCamera(
          name: _codeController.text,
          cameraCode: _codeController.text,
          type: kCameraTypes.first,
          ipAddress: _ipController.text,
          location: '',
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
                    _FieldLabel('Tên luồng (Stream ID)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _fieldDecoration('VD: cam_cong_chinh'),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Vui lòng nhập Stream ID'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Nguồn RTSP / URL'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ipController,
                      keyboardType: TextInputType.url,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _fieldDecoration('rtsp://user:pass@192.168.1.100/stream'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Vui lòng nhập URL nguồn';
                        return null;
                      },
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
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.accent,
                      title: const Text(
                        'Ghi hình (MP4)',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _recording ? 'Đang bật ghi hình' : 'Tắt ghi hình',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
