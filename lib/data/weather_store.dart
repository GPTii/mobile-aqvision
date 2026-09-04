import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../utils/app_strings.dart';

enum WeatherStatus { idle, loading, ready, permissionDenied, permissionDeniedForever, error }

class WeatherSnapshot {
  final double temperatureC;
  final int weatherCode;

  const WeatherSnapshot({required this.temperatureC, required this.weatherCode});

  /// WMO weather code -> (emoji, short Vietnamese label). Table:
  /// https://open-meteo.com/en/docs (see "weathercode").
  static Map<int, (String, String)> get _codeInfo => {
    0: ('☀️', 'Trời quang'.tr),
    1: ('🌤️', 'Ít mây'.tr),
    2: ('⛅', 'Có mây'.tr),
    3: ('☁️', 'Nhiều mây'.tr),
    45: ('🌫️', 'Sương mù'.tr),
    48: ('🌫️', 'Sương mù'.tr),
    51: ('🌦️', 'Mưa phùn nhẹ'.tr),
    53: ('🌦️', 'Mưa phùn'.tr),
    55: ('🌦️', 'Mưa phùn dày'.tr),
    61: ('🌧️', 'Mưa nhẹ'.tr),
    63: ('🌧️', 'Mưa'.tr),
    65: ('🌧️', 'Mưa to'.tr),
    71: ('🌨️', 'Tuyết nhẹ'.tr),
    73: ('🌨️', 'Tuyết'.tr),
    75: ('🌨️', 'Tuyết dày'.tr),
    80: ('🌦️', 'Mưa rào nhẹ'.tr),
    81: ('🌦️', 'Mưa rào'.tr),
    82: ('⛈️', 'Mưa rào to'.tr),
    95: ('⛈️', 'Dông'.tr),
    96: ('⛈️', 'Dông kèm mưa đá'.tr),
    99: ('⛈️', 'Dông kèm mưa đá'.tr),
  };

  String get emoji => _codeInfo[weatherCode]?.$1 ?? '🌡️';
  String get label => _codeInfo[weatherCode]?.$2 ?? 'Không rõ'.tr;
}

/// Current-location weather for the Home tab header. Uses the device GPS
/// (needs location permission) + Open-Meteo, a free forecast API that
/// needs no API key/signup — there's nothing for backend to build here.
class WeatherStore extends ChangeNotifier {
  static final WeatherStore instance = WeatherStore._();
  WeatherStore._();

  WeatherStatus status = WeatherStatus.idle;
  WeatherSnapshot? snapshot;

  Future<void> requestAndFetch() async {
    status = WeatherStatus.loading;
    notifyListeners();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        status = WeatherStatus.error;
        notifyListeners();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        status = WeatherStatus.permissionDenied;
        notifyListeners();
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        status = WeatherStatus.permissionDeniedForever;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      final uri = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&current=temperature_2m,weather_code&timezone=auto');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final current = json['current'];
        snapshot = WeatherSnapshot(
          temperatureC: (current['temperature_2m'] as num).toDouble(),
          weatherCode: (current['weather_code'] as num).toInt(),
        );
        status = WeatherStatus.ready;
      } else {
        status = WeatherStatus.error;
      }
    } catch (_) {
      status = WeatherStatus.error;
    }

    notifyListeners();
  }
}
