import 'package:flutter/material.dart';

import '../../core/commadesk_api.dart';
import '../../theme/app_colors.dart';

class AddCameraScreen extends StatefulWidget {
  final Map<String, dynamic>? cameraToEdit;
  const AddCameraScreen({super.key, this.cameraToEdit});

  @override
  State<AddCameraScreen> createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appController = TextEditingController(text: 'live');
  final _streamController = TextEditingController();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, dynamic>> _groups = [];
  List<String> _selectedGroupIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.cameraToEdit != null) {
      final cam = widget.cameraToEdit!;
      _appController.text = cam['app']?.toString() ?? 'live';
      _streamController.text =
          cam['stream']?.toString() ?? cam['cameraCode']?.toString() ?? '';
      _nameController.text = cam['name']?.toString() ?? '';
      _urlController.text =
          cam['url']?.toString() ?? cam['targetUrl']?.toString() ?? '';
      final rawIds = cam['groupIds'];
      if (rawIds is List) {
        _selectedGroupIds = rawIds.map((e) => e.toString()).toList();
      }
    }
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      dynamic raw;
      try {
        raw = await CommaDeskApi.instance.getJson('/me/camera-groups');
      } catch (_) {
        raw = await CommaDeskApi.instance.getJson('/camera-groups');
      }
      final list = CommaDeskApi.asMapList(CommaDeskApi.unwrapBody(raw));
      setState(() => _groups = list);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final body = {
        'name': _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : _streamController.text.trim(),
        'rtsp_url': _urlController.text.trim(),
        'stream_app': _appController.text.trim(),
        'stream_name': _streamController.text.trim(),
        if (_selectedGroupIds.isNotEmpty)
          'camera_group_ids': _selectedGroupIds,
      };

      if (widget.cameraToEdit == null) {
        await CommaDeskApi.instance.postJson('/cameras', body: body);
      } else {
        final id = widget.cameraToEdit!['id']?.toString() ?? '';
        await CommaDeskApi.instance.put('/cameras/$id', body: body);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.cameraToEdit == null ? 'Thêm Camera' : 'Sửa Camera',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Tên camera',
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _appController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: "App (Thường là 'live')",
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Vui lòng nhập App' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streamController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Stream ID (Mã camera)',
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) => val == null || val.isEmpty
                    ? 'Vui lòng nhập Stream ID'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Source URL (RTSP/RTMP/HLS)',
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Vui lòng nhập URL nguồn' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nhóm (Có thể chọn nhiều)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _groups.map((g) {
                  final id = g['id']?.toString() ?? '';
                  final isSelected = _selectedGroupIds.contains(id);
                  return FilterChip(
                    label: Text(
                      g['name']?.toString() ?? 'Nhóm',
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGroupIds.add(id);
                        } else {
                          _selectedGroupIds.remove(id);
                        }
                      });
                    },
                    selectedColor: AppColors.accent.withOpacity(0.2),
                    checkmarkColor: AppColors.accent,
                    backgroundColor: AppColors.surface,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: AppColors.textPrimary)
                    : const Text('LƯU'),
              ),
              if (widget.cameraToEdit != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _delete,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Text('Xóa Camera'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Xác nhận xóa',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Bạn có chắc chắn muốn xóa camera này không?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final id = widget.cameraToEdit!['id']?.toString() ?? '';
      await CommaDeskApi.instance.delete('/cameras/$id');
      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}
