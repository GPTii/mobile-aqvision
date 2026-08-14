with open("lib/screens/home/record_list_screen.dart", "r") as f:
    content = f.read()

# 1. Add url_launcher import
if "import 'package:url_launcher/url_launcher.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';")

# 2. Add duration and replace displayTime text
old_text_block = """                        Text(
                          'Bắt đầu ${recording.displayTime}',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11.5),
                        ),"""

new_text_block = """                        Text(
                          recording.displayTime,
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11.5),
                        ),
                        if (recording.durationText.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            recording.durationText,
                            style: TextStyle(
                                color: AppColors.accent, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],"""

content = content.replace(old_text_block, new_text_block)


# 3. Add Download button next to Delete button in the Tile (not AppBar!)
old_button_block = """                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.textMuted),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),"""

new_button_block = """                  // Download button
                  IconButton(
                    icon: const Icon(Icons.download_rounded,
                        size: 20, color: AppColors.accent),
                    onPressed: () {
                      launchUrl(Uri.parse(recording.mp4Url), mode: LaunchMode.externalApplication);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.textMuted),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),"""

content = content.replace(old_button_block, new_button_block)


with open("lib/screens/home/record_list_screen.dart", "w") as f:
    f.write(content)

