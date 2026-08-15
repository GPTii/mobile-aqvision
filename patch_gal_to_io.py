import re

def main():
    # 1. Remove gal from pubspec
    with open("pubspec.yaml", "r") as f:
        pubspec = f.read()
    pubspec = re.sub(r"^\s*gal:\s*.*\n", "", pubspec, flags=re.MULTILINE)
    with open("pubspec.yaml", "w") as f:
        f.write(pubspec)

    # 2. Add permissions to AndroidManifest
    manifest_path = "android/app/src/main/AndroidManifest.xml"
    with open(manifest_path, "r") as f:
        manifest = f.read()
    if "WRITE_EXTERNAL_STORAGE" not in manifest:
        manifest = manifest.replace(
            '<uses-permission android:name="android.permission.INTERNET"/>',
            '<uses-permission android:name="android.permission.INTERNET"/>\n    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>\n    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>'
        )
    with open(manifest_path, "w") as f:
        f.write(manifest)

    # 3. Update record_list_screen.dart to use dart:io
    file_path = "lib/screens/home/record_list_screen.dart"
    with open(file_path, "r") as f:
        content = f.read()

    content = content.replace("import 'package:gal/gal.dart';", "import 'dart:io';")

    old_gal = """      await Gal.putImageBytes(pngBytes, name: "snapshot_${DateTime.now().millisecondsSinceEpoch}");
      
      if (true) {"""
      
    new_io = """      final dir = Directory('/storage/emulated/0/Pictures');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final file = File('${dir.path}/snapshot_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      
      if (file.existsSync()) {"""
      
    content = content.replace(old_gal, new_io)
    
    with open(file_path, "w") as f:
        f.write(content)

if __name__ == "__main__":
    main()
