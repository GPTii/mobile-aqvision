with open("lib/screens/home/record_list_screen.dart", "r") as f:
    content = f.read()

target = """                        if (recording.durationText.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            recording.durationText,
                            style: TextStyle(
                                color: AppColors.accent, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                        ),
                      ],
                    ),
                  ),
                  // Delete button
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.textMuted),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),"""

replacement = """                        if (recording.durationText.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            recording.durationText,
                            style: TextStyle(
                                color: AppColors.accent, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Download button
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

content = content.replace(target, replacement)

with open("lib/screens/home/record_list_screen.dart", "w") as f:
    f.write(content)

