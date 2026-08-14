import re

with open("lib/screens/home/record_list_screen.dart", "r") as f:
    content = f.read()

# 1. Replace VideoProgressIndicator
old_progress = """                          VideoProgressIndicator(_vpController!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: AppColors.accent,
                                backgroundColor: Colors.white24,
                              )),"""

new_progress = """                          _VideoSlider(controller: _vpController!),"""
content = content.replace(old_progress, new_progress)

# 2. Append _VideoSlider class at the end of the file
slider_class = """
class _VideoSlider extends StatefulWidget {
  final VideoPlayerController controller;
  const _VideoSlider({required this.controller});

  @override
  State<_VideoSlider> createState() => _VideoSliderState();
}

class _VideoSliderState extends State<_VideoSlider> {
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _listener = () {
      if (mounted) setState(() {});
    };
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }
  
  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    if (d.inHours > 0) {
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final pos = widget.controller.value.position;
    final dur = widget.controller.value.duration;
    
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(_formatDuration(pos), style: const TextStyle(color: Colors.white, fontSize: 12)),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppColors.accent,
                overlayColor: AppColors.accent.withOpacity(0.2),
              ),
              child: Slider(
                value: pos.inMilliseconds.toDouble().clamp(0, dur.inMilliseconds.toDouble()),
                min: 0,
                max: dur.inMilliseconds.toDouble() > 0 ? dur.inMilliseconds.toDouble() : 100,
                onChanged: (val) {
                  widget.controller.seekTo(Duration(milliseconds: val.toInt()));
                },
              ),
            ),
          ),
          Text(_formatDuration(dur), style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
"""

if "_VideoSlider" not in content:
    content += slider_class

with open("lib/screens/home/record_list_screen.dart", "w") as f:
    f.write(content)
