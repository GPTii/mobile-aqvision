import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/weather_store.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

List<String> get _kWeekdayNames => [
  'Thứ Hai'.tr,
  'Thứ Ba'.tr,
  'Thứ Tư'.tr,
  'Thứ Năm'.tr,
  'Thứ Sáu'.tr,
  'Thứ Bảy'.tr,
  'Chủ Nhật'.tr,
];

/// Thin date/time + current-location weather subtitle, meant to sit right
/// under a screen title (e.g. "Trang chủ".tr) rather than as a boxed chip
/// competing with the notification bell — a flowing line reads calmer and
/// closer to how modern dashboard apps present a greeting subtitle.
class WeatherTimeHeader extends StatefulWidget {
  const WeatherTimeHeader({super.key});

  @override
  State<WeatherTimeHeader> createState() => _WeatherTimeHeaderState();
}

class _WeatherTimeHeaderState extends State<WeatherTimeHeader> {
  late DateTime _now = DateTime.now();
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WeatherStore.instance.requestAndFetch();
    // Re-check every minute; re-aligns to the next minute boundary first.
    final msToNextMinute = 60000 - (DateTime.now().millisecondsSinceEpoch % 60000);
    Timer(Duration(milliseconds: msToNextMinute), () {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _timeLabel =>
      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

  String get _dateLabel =>
      '${_kWeekdayNames[_now.weekday - 1]}, ${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 600;

    return ListenableBuilder(
      listenable: WeatherStore.instance,
      builder: (context, _) {
        final store = WeatherStore.instance;

        if (store.status == WeatherStatus.permissionDenied ||
            store.status == WeatherStatus.permissionDeniedForever) {
          return _PermissionRow(
            deniedForever: store.status == WeatherStatus.permissionDeniedForever,
          );
        }

        return _SubtitleRow(
          dateLabel: _dateLabel,
          timeLabel: _timeLabel,
          store: store,
          showLabel: wide,
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7),
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle),
        ),
      );
}

class _SubtitleRow extends StatelessWidget {
  final String dateLabel;
  final String timeLabel;
  final WeatherStore store;
  final bool showLabel;

  const _SubtitleRow({
    required this.dateLabel,
    required this.timeLabel,
    required this.store,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    final snap = store.snapshot;
    final fontSize = showLabel ? 14.0 : 12.5;
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    );

    // Narrow phones only have room for weather + time — weekday/date and
    // the clock icon were pushing the line past the available width and
    // getting cut off with "…". Wider screens (tablet) show the full line.
    final trailing = showLabel ? '$dateLabel · $timeLabel' : timeLabel;

    return Row(
      children: [
        if (store.status == WeatherStatus.loading)
          SizedBox(
            width: fontSize,
            height: fontSize,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: AppColors.accent),
          )
        else
          Text(snap?.emoji ?? '🌡️', style: TextStyle(fontSize: fontSize + 1)),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            snap == null
                ? '--°C'
                : (showLabel ? '${snap.temperatureC.round()}°C ${snap.label}' : '${snap.temperatureC.round()}°C'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ),
        const _Dot(),
        if (showLabel) ...[
          Icon(Icons.access_time_rounded, size: fontSize, color: AppColors.textMuted),
          SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            trailing,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final bool deniedForever;

  const _PermissionRow({required this.deniedForever});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (deniedForever) {
            Geolocator.openAppSettings();
          } else {
            WeatherStore.instance.requestAndFetch();
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on_outlined, size: 14, color: AppColors.accent),
            SizedBox(width: 5),
            Text(
              'Bật định vị để xem thời tiết'.tr,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
