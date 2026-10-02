import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// One decoded event from the telemetry SSE stream.
class TelemetryEvent {
  /// `"system"` (§5.1) or `"telemetry"` (§6).
  final String event;
  final Map<String, dynamic> data;
  const TelemetryEvent(this.event, this.data);
}

/// Server-Sent Events client for `GET /api/telemetry/live` (README_BLE.md §6.2).
///
/// Emits `event: system` on connect (and when name/stream count changes), then
/// `event: telemetry` every [intervalMs]. Auto-reconnects 1 s after a drop
/// (WiFi change, gateway restart). The caller decides when to stop by
/// cancelling the subscription.
Stream<TelemetryEvent> openTelemetryStream(
  Uri base, {
  int intervalMs = 100,
  String? token,
}) async* {
  while (true) {
    final client = http.Client();
    try {
      final req = http.Request(
        'GET',
        base.resolve('/api/telemetry/live?interval_ms=$intervalMs'),
      );
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      final res = await client.send(req);
      var event = 'message';
      await for (final line in res.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.startsWith('event: ')) {
          event = line.substring(7);
        } else if (line.startsWith('data: ')) {
          final data = jsonDecode(line.substring(6));
          if (data is Map<String, dynamic>) {
            yield TelemetryEvent(event, data);
          }
        }
      }
    } catch (_) {
      // network change, gateway restart... fall through to reconnect
    } finally {
      client.close();
    }
    await Future.delayed(const Duration(seconds: 1));
  }
}

/// Decoded DHT11 reading: relative humidity (%) and temperature (°C).
class Dht11Reading {
  final double humidity;
  final double temperature;
  const Dht11Reading(this.humidity, this.temperature);
}

List<int>? _hex5(String? h) {
  if (h == null || h.length != 10) return null;
  try {
    return [
      for (var i = 0; i < 10; i += 2) int.parse(h.substring(i, i + 2), radix: 16),
    ];
  } catch (_) {
    return null;
  }
}

/// Decode a DHT11 raw frame (§6.1). Returns null when the checksum fails.
/// Frame: [humidity_int, humidity_dec, temp_int, temp_dec, checksum].
Dht11Reading? decodeDht11(String? raw) {
  final b = _hex5(raw);
  if (b == null || ((b[0] + b[1] + b[2] + b[3]) & 0xFF) != b[4]) return null;
  return Dht11Reading(b[0] + b[1] / 10, b[2] + b[3] / 10);
}

/// Decode an AGS10 raw frame to TVOC in ppb (§6.1). Returns null when the
/// CRC-8 (poly 0x31, init 0xFF) fails or bit0 of byte0 is set.
int? decodeAgs10(String? raw) {
  final b = _hex5(raw);
  if (b == null || (b[0] & 0x01) != 0) return null;
  var crc = 0xFF;
  for (final x in b.sublist(0, 4)) {
    crc ^= x;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x80) != 0 ? ((crc << 1) ^ 0x31) & 0xFF : (crc << 1) & 0xFF;
    }
  }
  return crc == b[4] ? (b[1] << 16 | b[2] << 8 | b[3]) : null;
}

/// Rough air-quality band from TVOC ppb (§6.1). App picks its own labels/colors.
enum AirQuality { good, moderate, poor, veryPoor, hazardous }

AirQuality airQualityFromTvoc(int ppb) {
  if (ppb < 220) return AirQuality.good;
  if (ppb < 660) return AirQuality.moderate;
  if (ppb < 2200) return AirQuality.poor;
  if (ppb < 5500) return AirQuality.veryPoor;
  return AirQuality.hazardous;
}
