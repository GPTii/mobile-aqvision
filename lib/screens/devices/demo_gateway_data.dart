import 'dart:math';

import '../../data/gateway_store.dart';

/// Fake gateways shown in "Quản lý thiết bị" until a real one is set up.
///
/// Payloads mirror a real Radxa gateway (`/api/system`, `/api/telemetry`,
/// `/api/hardware`, `/api/wifi/status`, `/api/signal`, `/api/cameras/health`)
/// so the detail screen renders them through exactly the same code path.
/// Sensor values are encoded back into raw DHT11 / AGS10 frames and go
/// through the real decoders.
class DemoGateway {
  static const _prefix = 'demo:';
  static bool isDemo(String id) => id.startsWith(_prefix);

  static const gateways = [
    SavedGateway('${_prefix}company', 'Gateway Công ty', '192.168.1.189', 'eyerus-congty'),
    SavedGateway('${_prefix}traffic', 'Gateway Giao thông', '192.168.10.24', 'eyerus-giaothong'),
  ];

  final SavedGateway gateway;
  final Random _rnd;
  final bool _traffic;
  int _seq = 0;

  // Random-walk state.
  late double _temp = _traffic ? 32.5 : 26.5;
  late double _hum = _traffic ? 74.0 : 58.0;
  late double _tvoc = _traffic ? 850 : 180;
  late double _cpu = _traffic ? 22 : 9;
  late double _soc = _traffic ? 66 : 61;
  late double _ram = _traffic ? 2210 : 1705;
  late final List<double> _cores = List.filled(8, _traffic ? 20 : 8);

  DemoGateway(this.gateway)
      : _traffic = gateway.id.endsWith('traffic'),
        _rnd = Random(gateway.id.hashCode);

  static const _ramTotal = 3886.4;
  static const _diskTotal = 58.12;
  double get _diskUsed => _traffic ? 34.9 : 21.48;

  List<Map<String, dynamic>> get _cameraList => _traffic
      ? [
          _cam('giaothong1', '192.168.10.31', 'hikvision', 'DS-2CD2T47G2', true),
          _cam('giaothong2', '192.168.10.32', 'hikvision', 'DS-2CD2T47G2', true),
          _cam('giaothong3', '192.168.10.33', 'dahua', 'IPC-HFW2431T', true),
          _cam('giaothong4', '192.168.10.34', 'dahua', 'IPC-HFW2431T', true),
        ]
      : [
          _cam('cam1', '192.168.1.108', 'General', 'IP Camera', true),
          _cam('cam3', '192.168.1.195', 'tp-link', 'Tapo C200', true),
        ];

  static Map<String, dynamic> _cam(String mount, String host, String maker, String model, bool online) => {
        'mount': mount,
        'host': host,
        'port': 80,
        'enabled': true,
        'online': online,
        'route_ready': online,
        'status': online ? 'online' : 'error',
        'manufacturer': maker,
        'model': model,
      };

  Map<String, dynamic> system() {
    final cams = _cameraList;
    final online = cams.where((c) => c['online'] == true).length;
    return {
      'event': 'system',
      'version': '1.0',
      'gateway': {
        'gateway_id': gateway.id,
        'gateway_name': gateway.name,
        'cluster_id': 'eyerus-cluster-1',
        'zone': _traffic ? 'zone-giaothong' : 'zone-congty',
        'hostname': gateway.hostname,
        'ip': gateway.ip,
        'http_port': 5050,
      },
      'hardware': {
        'board': 'Radxa Cubie A5E',
        'processor': 'Allwinner A527 · 8x ARM Cortex-A55',
        'cpu_cores': 8,
        'cpu_threads': 8,
        'cpu_max_freq_mhz': 1416.0,
        'os': 'Debian GNU/Linux 12 (bookworm)',
        'kernel': '5.15.147-20-aw2501',
        'serial': _traffic ? '40781e56759600000000601000000abc' : '40781e567596d7100000601000000000',
      },
      'status': _hardwareSample(),
      'sensors': _sensorSample(),
      'streams': {
        'cameras_total': cams.length,
        'cameras_enabled': cams.length,
        'routes_ready': online,
        'mounts': [for (final c in cams) c['mount']],
        'push_outputs': online,
        'push_running': online,
        'rtsp_port': 8554,
        'max_sessions': 128,
      },
    };
  }

  /// One `event: telemetry` payload; call once per tick.
  Map<String, dynamic> nextTelemetry() {
    _step();
    return {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'seq': ++_seq,
      'sensors': _sensorSample(),
      'hardware': _hardwareSample(),
    };
  }

  Map<String, dynamic> hardware() => {
        'board': {
          'model': 'Radxa Cubie A5E',
          'hostname': gateway.hostname,
          'os': 'Debian GNU/Linux 12 (bookworm)',
          'kernel': '5.15.147-20-aw2501',
          'uptime_seconds': _traffic ? 1296000 + 7380 : 58224,
          'soc': 'A527',
        },
        'network_interfaces': [
          {
            'interface': 'eth0',
            'ip': _traffic ? gateway.ip : '',
            'mac': '08:ef:6c:c7:48:6a',
            'state': _traffic ? 'up' : 'down'
          },
          {
            'interface': 'wlan0',
            'ip': _traffic ? '' : gateway.ip,
            'mac': 'fc:23:cd:03:8c:08',
            'state': _traffic ? 'down' : 'up'
          },
        ],
      };

  Map<String, dynamic> wifi() => _traffic
      ? {'available': true, 'connected': false, 'state': 'disconnected'}
      : {
          'available': true,
          'connected': true,
          'state': 'connected',
          'ssid': 'VIVI BUILDING',
          'ip': gateway.ip,
          'signal': 46
        };

  Map<String, dynamic> signal() => {
        'wifi': _traffic ? null : {'iface': 'wlan0', 'level_dbm': -76, 'quality_pct': 46},
        'cameras': [
          for (final c in _cameraList)
            if (c['online'] == true) {'mount': c['mount'], 'host': c['host'], 'rtt_ms': 1.5 + _rnd.nextDouble() * 4},
        ],
      };

  List<Map<String, dynamic>> cameras() => _cameraList;

  // ── simulation ────────────────────────────────────────────────────────

  double _walk(double v, double step, double lo, double hi) => (v + (_rnd.nextDouble() * 2 - 1) * step).clamp(lo, hi);

  void _step() {
    _temp = _walk(_temp, 0.15, 18, 38);
    _hum = _walk(_hum, 0.4, 30, 90);
    _tvoc = _walk(_tvoc, 25, 40, 1500);
    _cpu = _walk(_cpu, 6, 2, 95);
    _soc = _walk(_soc, 0.4, 45, 84);
    _ram = _walk(_ram, 15, 1200, 3200);
    for (var i = 0; i < _cores.length; i++) {
      _cores[i] = _walk(_cores[i], 12, 0, 100);
    }
  }

  Map<String, dynamic> _hardwareSample() => {
        'cpu_percent': _r1(_cpu),
        'cpu_per_core': [for (final c in _cores) _r1(c)],
        'cpu_temperature_c': _r1(_soc),
        'cpu_freq_mhz': _cpu > 40 ? 1416 : (_cpu > 15 ? 1008 : 672),
        'load_1m': _r2(_cpu / 25),
        'ram_total_mb': _ramTotal,
        'ram_used_mb': _r1(_ram),
        'ram_percent': _r1(_ram / _ramTotal * 100),
        'disk_total_gb': _diskTotal,
        'disk_used_gb': _diskUsed,
        'disk_percent': _r1(_diskUsed / _diskTotal * 100),
      };

  Map<String, dynamic> _sensorSample() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'available': true,
      'ts_ms': now,
      'interval_ms': 100,
      'dht11': {'raw': _dht11Raw(_hum, _temp), 'status': 'ok', 'read_at_ms': now},
      'ags10': {'raw': _ags10Raw(_tvoc.round()), 'status': 'ok', 'read_at_ms': now},
    };
  }

  /// [hum_int, hum_dec, temp_int, temp_dec, checksum] (README_BLE §6.1).
  static String _dht11Raw(double hum, double temp) {
    final h = (hum * 10).round(), t = (temp * 10).round();
    final b = [h ~/ 10, h % 10, t ~/ 10, t % 10];
    return _hex([...b, (b[0] + b[1] + b[2] + b[3]) & 0xFF]);
  }

  /// [status, tvoc_hi, tvoc_mid, tvoc_lo, crc8(poly 0x31, init 0xFF)].
  static String _ags10Raw(int tvoc) {
    final b = [0x10, (tvoc >> 16) & 0xFF, (tvoc >> 8) & 0xFF, tvoc & 0xFF];
    var crc = 0xFF;
    for (final x in b) {
      crc ^= x;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x80) != 0 ? ((crc << 1) ^ 0x31) & 0xFF : (crc << 1) & 0xFF;
      }
    }
    return _hex([...b, crc]);
  }

  static String _hex(List<int> b) => b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  static double _r1(double v) => (v * 10).round() / 10;
  static double _r2(double v) => (v * 100).round() / 100;
}
