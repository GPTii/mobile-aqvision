import 'package:flutter/material.dart';

import '../../data/camera_store.dart';
import '../../theme/app_colors.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  bool _adding = false;
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _addGroup() async {
    final name = _addCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      await CameraStore.instance.addGroup(name);
      _addCtrl.clear();
      setState(() => _adding = false);
      _showSnack('Đã thêm nhóm "$name"');
    } catch (e) {
      _showSnack('Lỗi: $e', error: true);
    }
  }

  Future<void> _renameGroup(CameraGroup group) async {
    final ctrl = TextEditingController(text: group.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đổi tên nhóm',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tên nhóm mới'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Lưu',
                  style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty && newName != group.name) {
      await CameraStore.instance.renameGroup(group.id, newName);
      _showSnack('Đã đổi tên thành "$newName"');
    }
  }

  Future<void> _deleteGroup(CameraGroup group) async {
    final cameras = CameraStore.instance.camerasInGroup(group.id);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa nhóm?',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Text(
          cameras.isNotEmpty
              ? 'Nhóm "${group.name}" có ${cameras.length} camera. '
                  'Camera sẽ không bị xóa nhưng sẽ không còn thuộc nhóm này.'
              : 'Xóa nhóm "${group.name}"?',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    ) ?? false;
    if (ok) {
      try {
        await CameraStore.instance.deleteGroup(group.id);
        _showSnack('Đã xóa nhóm "${group.name}"');
      } catch (e) {
        _showSnack('Lỗi: $e', error: true);
      }
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CameraStore.instance,
      builder: (ctx, _) {
        final groups = CameraStore.instance.groups;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.headerBackground,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.textPrimary, size: 20),
                        ),
                        const Expanded(
                          child: Text('Quản lý nhóm',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${groups.length} nhóm',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Add group input
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _adding
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _addCtrl,
                                  autofocus: true,
                                  onSubmitted: (_) => _addGroup(),
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Tên nhóm mới...',
                                    hintStyle: const TextStyle(color: AppColors.textMuted),
                                    filled: true,
                                    fillColor: AppColors.card,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.accent),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppColors.border),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _addGroup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                child: const Text('Thêm'),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.textMuted),
                                onPressed: () {
                                  _addCtrl.clear();
                                  setState(() => _adding = false);
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // List
                Expanded(
                  child: groups.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.folder_off_rounded,
                                  size: 52,
                                  color: AppColors.textMuted.withOpacity(0.4)),
                              const SizedBox(height: 12),
                              const Text('Chưa có nhóm nào',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              const Text('Nhấn "+" để thêm nhóm mới',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 12)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: groups.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final group = groups[i];
                            final cameras = CameraStore.instance.camerasInGroup(group.id);
                            return _GroupTile(
                              group: group,
                              cameraCount: cameras.length,
                              onRename: () => _renameGroup(group),
                              onDelete: () => _deleteGroup(group),
                              onTap: () => _showGroupCameras(context, group, cameras),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => setState(() => _adding = true),
            backgroundColor: AppColors.accent,
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showGroupCameras(
      BuildContext context, CameraGroup group, List<Camera> cameras) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text('Nhóm: ${group.name}',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            if (cameras.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('Chưa có camera nào trong nhóm này',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
              )
            else
              ...cameras.map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: c.online
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.textMuted.withOpacity(0.1),
                      child: Icon(Icons.videocam_rounded,
                          size: 18,
                          color: c.online ? AppColors.success : AppColors.textMuted),
                    ),
                    title: Text(c.name,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    subtitle: Text(c.cameraCode,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.online
                            ? AppColors.success.withOpacity(0.1)
                            : AppColors.textMuted.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c.online ? 'Online' : 'Offline',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: c.online ? AppColors.success : AppColors.textMuted),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final CameraGroup group;
  final int cameraCount;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _GroupTile({
    required this.group,
    required this.cameraCount,
    required this.onRename,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('$cameraCount camera',
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 20),
                color: AppColors.card,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (v) {
                  if (v == 'rename') onRename();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Đổi tên')),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('Xóa nhóm',
                          style: TextStyle(color: AppColors.danger))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
