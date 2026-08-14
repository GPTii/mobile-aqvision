import re

with open("lib/screens/home/record_list_screen.dart", "r") as f:
    content = f.read()

# Add import
if "import 'package:url_launcher/url_launcher.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:url_launcher/url_launcher.dart';")

# Replace Bắt đầu
content = content.replace("'Bắt đầu ${recording.displayTime}'", "recording.displayTime")

# Add duration text
duration_code = """
                        const SizedBox(height: 2),
                        Text(
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
                        ],
"""
content = re.sub(r"const SizedBox\(height: 2\),\s*Text\(\s*recording\.displayTime,.*?\),", duration_code.strip(), content, flags=re.DOTALL)


# Add download button
download_button_code = """
                  IconButton(
                    icon: const Icon(Icons.download_rounded,
                        size: 20, color: AppColors.accent),
                    onPressed: () {
                      launchUrl(Uri.parse(recording.mp4Url), mode: LaunchMode.externalApplication);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
"""
content = content.replace("                  IconButton(", download_button_code, 1) # Only replace the first occurrence (which is the delete button)


with open("lib/screens/home/record_list_screen.dart", "w") as f:
    f.write(content)
