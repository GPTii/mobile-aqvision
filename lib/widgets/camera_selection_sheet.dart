import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/camera_store.dart';

Future<void> showCameraSelectionSheet(BuildContext context, {required String groupId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CameraSelectionSheet(groupId: groupId),
  );
}

class _CameraSelectionSheet extends StatefulWidget {
  final String groupId;

  const _CameraSelectionSheet({required this.groupId});

  @override
  State<_CameraSelectionSheet> createState() => _CameraSelectionSheetState();
}

class _CameraSelectionSheetState extends State<_CameraSelectionSheet> {
  final Set<String> _selectedIds = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cameras = CameraStore.instance.cameras.where((c) => c.groupId != widget.groupId).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Chọn camera vào nhóm', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          
          if (cameras.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text("Không có camera nào khả dụng.", style: TextStyle(color: AppColors.textMuted)),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cameras.length,
                itemBuilder: (context, index) {
                  final cam = cameras[index];
                  final isSelected = _selectedIds.contains(cam.id);
                  return CheckboxListTile(
                    title: Text(cam.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                    subtitle: Text(cam.cameraCode, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    value: isSelected,
                    activeColor: AppColors.accent,
                    checkColor: Colors.white,
                    side: const BorderSide(color: AppColors.textMuted),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(cam.id);
                        } else {
                          _selectedIds.remove(cam.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: AppColors.surface,
                    ),
                    child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: (_isLoading || _selectedIds.isEmpty) ? null : _submit,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: AppColors.accent,
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Thêm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      for (final id in _selectedIds) {
        await CameraStore.instance.updateCamera(id, groupId: widget.groupId);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
