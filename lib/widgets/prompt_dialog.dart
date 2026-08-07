import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shows a small dialog with a single text field and returns the trimmed
/// value on confirm, or null if cancelled / left empty.
Future<String?> showTextPromptDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
  String hint = '',
  String confirmLabel = 'Lưu',
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _TextPromptDialog(
      title: title,
      initialValue: initialValue,
      hint: hint,
      confirmLabel: confirmLabel,
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
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

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
      title: Text(widget.title, style: const TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            widget.confirmLabel,
            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
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
  String confirmLabel = 'Xoá',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
