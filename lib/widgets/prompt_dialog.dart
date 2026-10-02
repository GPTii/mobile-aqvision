import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

/// Shows a small dialog with a single text field and returns the trimmed
/// value on confirm, or null if cancelled / left empty.
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String hint = '',
  String? confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _TextPromptDialog(
      title: title,
      initialValue: initialValue,
      hint: hint,
      confirmLabel: confirmLabel ?? 'Lưu'.tr,
    ),
  );
}

/// Owns the [TextEditingController] itself so it's disposed exactly when
/// the dialog widget unmounts — disposing it right after the `showDialog`
/// future resolves races the dialog's own exit animation and crashes.
class _TextPromptDialog extends StatefulWidget {
  final String title;
  final String initialValue;
  final String hint;
  final String confirmLabel;

  const _TextPromptDialog({
    required this.title,
    required this.initialValue,
    required this.hint,
    required this.confirmLabel,
  });

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(widget.title, style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.accent, width: 1.4),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Huỷ'.tr, style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.confirmLabel,
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Asks for a host and a port. Returns `(host, port)` on confirm, or null if
/// cancelled. Typing `host:port` in the first field fills the port field.
Future<(String, int)?> showHostPortDialog(
  BuildContext context, {
  required String title,
  String initialHost = '',
  required int initialPort,
  String hint = '',
  String? confirmLabel,
}) {
  return showDialog<(String, int)>(
    context: context,
    builder: (_) => _HostPortDialog(
      title: title,
      initialHost: initialHost,
      initialPort: initialPort,
      hint: hint,
      confirmLabel: confirmLabel ?? 'Lưu'.tr,
    ),
  );
}

class _HostPortDialog extends StatefulWidget {
  final String title;
  final String initialHost;
  final int initialPort;
  final String hint;
  final String confirmLabel;

  const _HostPortDialog({
    required this.title,
    required this.initialHost,
    required this.initialPort,
    required this.hint,
    required this.confirmLabel,
  });

  @override
  State<_HostPortDialog> createState() => _HostPortDialogState();
}

class _HostPortDialogState extends State<_HostPortDialog> {
  late final TextEditingController _host = TextEditingController(text: widget.initialHost);
  late final TextEditingController _port = TextEditingController(text: '${widget.initialPort}');
  String? _portError;

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  /// `192.168.1.5:8080` typed / pasted into the host field → split it.
  void _onHostChanged(String v) {
    final m = RegExp(r'^(?:https?://)?([^/:]+):(\d{1,5})(?:/.*)?$').firstMatch(v.trim());
    if (m == null) return;
    _host.value = TextEditingValue(
      text: m.group(1)!,
      selection: TextSelection.collapsed(offset: m.group(1)!.length),
    );
    _port.text = m.group(2)!;
  }

  void _submit() {
    final host = _host.text.trim().replaceFirst(RegExp(r'^https?://'), '').replaceFirst(RegExp(r'/.*$'), '');
    final port = int.tryParse(_port.text.trim());
    if (port == null || port < 1 || port > 65535) {
      setState(() => _portError = 'Port phải từ 1 đến 65535'.tr);
      return;
    }
    if (host.isEmpty) return;
    Navigator.of(context).pop((host, port));
  }

  InputDecoration _decoration(String label, {String? hint, String? error}) => InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        hintStyle: TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.accent, width: 1.4),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(widget.title, style: TextStyle(color: AppColors.textPrimary)),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _host,
              autofocus: true,
              keyboardType: TextInputType.url,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: _decoration('Địa chỉ'.tr, hint: widget.hint),
              onChanged: _onHostChanged,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: _decoration('Port'.tr, error: _portError),
              onChanged: (_) {
                if (_portError != null) setState(() => _portError = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Huỷ'.tr, style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.confirmLabel,
            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Shows a Yes/No confirmation dialog. Returns true if confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
      content: Text(message, style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('Huỷ'.tr, style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel ?? 'Xoá'.tr,
            style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
