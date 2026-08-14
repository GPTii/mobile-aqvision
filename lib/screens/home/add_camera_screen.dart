import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';

class AddCameraScreen extends StatefulWidget {
  final Map<String, dynamic>? cameraToEdit;
  const AddCameraScreen({super.key, this.cameraToEdit});

  @override
  State<AddCameraScreen> createState() => _AddCameraScreenState();
}

class _AddCameraScreenState extends State<AddCameraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _appController = TextEditingController(text: "live");
  final _streamController = TextEditingController();
  final _urlController = TextEditingController();
  
  bool _isLoading = false;
  List<dynamic> _groups = [];
  List<int> _selectedGroupIds = [];

  bool _enableHls = true;
  bool _enableMp4 = false;
  bool _enableCloudSync = false;

  String get _apiBase {
    if (kIsWeb) {
      final port = Uri.base.port;
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : "localhost";
      if (port != 3002 && (host == 'localhost' || host == '127.0.0.1')) {
        return "http://$host:3002/api";
      }
      return "${Uri.base.scheme}://${Uri.base.authority}/api";
    }
    return "https://dev1.aqvision.net/api";
  }

  @override
  void initState() {
    super.initState();
    if (widget.cameraToEdit != null) {
      _appController.text = widget.cameraToEdit!["app"] ?? "live";
      _streamController.text = widget.cameraToEdit!["stream"] ?? "";
      _urlController.text = widget.cameraToEdit!["url"] ?? widget.cameraToEdit!["targetUrl"] ?? "";
      _selectedGroupIds = List<int>.from(widget.cameraToEdit!["groupIds"] ?? []);
      _enableHls = widget.cameraToEdit!["enableHls"] ?? true;
      _enableMp4 = widget.cameraToEdit!["enableMp4"] ?? false;
      _enableCloudSync = widget.cameraToEdit!["enableCloudSync"] ?? false;
    }
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final uri = Uri.parse("$_apiBase/groups");
      final res = await http.get(uri, headers: {"Authorization": "Bearer $token"});
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        setState(() {
          _groups = json["data"] ?? [];
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      
      final url = widget.cameraToEdit == null 
        ? Uri.parse("$_apiBase/proxies")
        : Uri.parse("$_apiBase/proxies/${widget.cameraToEdit!['id']}");
        
      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };
      
      final body = jsonEncode({
        "app": _appController.text,
        "stream": _streamController.text,
        "url": _urlController.text,
        "enableHls": _enableHls,
        "enableMp4": _enableMp4,
        "enableCloudSync": _enableCloudSync,
        "groupIds": _selectedGroupIds,
      });
      
      final res = widget.cameraToEdit == null
          ? await http.post(url, headers: headers, body: body)
          : await http.put(url, headers: headers, body: body);
          
      setState(() => _isLoading = false);
      
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        final json = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json["error"] ?? "Lỗi")));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.cameraToEdit == null ? "Thêm Camera" : "Sửa Camera", style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
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
                controller: _appController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: "App (Thường là 'live')", filled: true, fillColor: AppColors.surface),
                validator: (val) => val == null || val.isEmpty ? "Vui lòng nhập App" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streamController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: "Stream ID (Mã camera)", filled: true, fillColor: AppColors.surface),
                validator: (val) => val == null || val.isEmpty ? "Vui lòng nhập Stream ID" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urlController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: "Source URL (RTSP/RTMP/HTTP)", filled: true, fillColor: AppColors.surface),
                validator: (val) => val == null || val.isEmpty ? "Vui lòng nhập URL nguồn" : null,
              ),
              const SizedBox(height: 16),
              const Text("Nhóm (Có thể chọn nhiều)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _groups.map((g) {
                  final id = g["id"] as int;
                  final isSelected = _selectedGroupIds.contains(id);
                  return FilterChip(
                    label: Text(g["name"], style: TextStyle(color: isSelected ? AppColors.accent : AppColors.textPrimary)),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text("Enable HLS", style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      value: _enableHls,
                      onChanged: (val) => setState(() => _enableHls = val ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.accent,
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text("Enable MP4", style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      value: _enableMp4,
                      onChanged: (val) => setState(() => _enableMp4 = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.accent,
                    ),
                  ),
                ],
              ),
              CheckboxListTile(
                title: const Text("Cloud Sync", style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                value: _enableCloudSync,
                onChanged: (val) => setState(() => _enableCloudSync = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.accent,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: AppColors.textPrimary) : const Text("LƯU"),
              ),
              if (widget.cameraToEdit != null) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _delete,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.danger,
                  ),
                  child: const Text("Xóa Camera"),
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
        title: const Text("Xác nhận xóa", style: TextStyle(color: AppColors.textPrimary)),
        content: const Text("Bạn có chắc chắn muốn xóa camera này không?", style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy", style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token") ?? "";
      final uri = Uri.parse("$_apiBase/proxies/${widget.cameraToEdit!['id']}");
      
      final res = await http.delete(uri, headers: {"Authorization": "Bearer $token"});
      setState(() => _isLoading = false);
      
      if (res.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        if (!mounted) return;
        final json = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(json["error"] ?? "Lỗi")));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối")));
    }
  }
}
