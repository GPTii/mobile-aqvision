import re

with open("lib/data/recording_store.dart", "r") as f:
    content = f.read()

new_recording_file = """class RecordingFile {
  final String date;       // YYYY-MM-DD
  final String fileName;   // e.g. 08-30-00.mp4
  final String app;
  final String stream;
  final String serverUrl;  // base URL of media server
  final String token;      // auth token

  RecordingFile({
    required this.date,
    required this.fileName,
    required this.app,
    required this.stream,
    required this.serverUrl,
    required this.token,
  });

  String get mp4Url =>
      '$serverUrl/record/$app/$stream/$date/$fileName?access_token=$token';

  String get displayTime {
    final parts = fileName.replaceAll('.mp4', '').split('-');
    if (parts.length >= 6 && parts[0].length == 4) {
      return 'Bắt đầu: ${parts[3]}:${parts[4]}:${parts[5]}';
    } else if (parts.length >= 3) {
      return 'Bắt đầu: ${parts[0]}:${parts[1]}:${parts[2]}';
    }
    return fileName;
  }

  String get durationText {
    final parts = fileName.replaceAll('.mp4', '').split('-');
    if (parts.length >= 7 && parts[0].length == 4) {
      int? dur = int.tryParse(parts[6]);
      if (dur != null && dur > 0) return 'Thời lượng: $dur giây';
    }
    return '';
  }

  String get id => '$date/$fileName';
}"""

content = re.sub(r"class RecordingFile \{.*?\n  String get id => '\$date/\$fileName';\n\}", new_recording_file, content, flags=re.DOTALL)

with open("lib/data/recording_store.dart", "w") as f:
    f.write(content)

