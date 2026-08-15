import re

def main():
    file_path = "lib/screens/home/record_list_screen.dart"
    with open(file_path, "r") as f:
        content = f.read()

    # Replace image_gallery_saver import with gal
    content = content.replace("import 'package:image_gallery_saver/image_gallery_saver.dart';", "import 'package:gal/gal.dart';")

    # Replace the usage of image_gallery_saver with gal in _takeSnapshot
    old_gal = """      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: "snapshot_${DateTime.now().millisecondsSinceEpoch}"
      );
      
      if (result != null && result['isSuccess'] == true) {"""
      
    new_gal = """      await Gal.putImageBytes(pngBytes, name: "snapshot_${DateTime.now().millisecondsSinceEpoch}");
      
      if (true) {"""
    
    content = content.replace(old_gal, new_gal)
    
    with open(file_path, "w") as f:
        f.write(content)

if __name__ == "__main__":
    main()
