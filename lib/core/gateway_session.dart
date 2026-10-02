import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/gateway_store.dart';
import 'gateway_api.dart';
import 'gateway_telemetry.dart';
import '../utils/app_strings.dart';

/// Default LAN port of the Eyerus config-server.
const int kGatewayPort = SavedGateway.defaultPort;

/// Splits what the user typed — `192.168.1.5`, `192.168.1.5:8080`,
/// `http://host:8080/…` — into host + port. An explicit [port] wins over one
/// embedded in the text; otherwise falls back to [kGatewayPort].
(String, int) parseGatewayAddress(String input, {int? port}) {
  var s = input.trim().replaceFirst(RegExp(r'^https?://'), '');
  s = s.replaceFirst(RegExp(r'/.*$'), '');
  var host = s;
  int? embedded;
  final m = RegExp(r'^(.+):(\d{1,5})$').firstMatch(s);
  if (m != null) {
    host = m.group(1)!;
    embedded = int.parse(m.group(2)!);
  }
  return (host, port ?? embedded ?? kGatewayPort);
}

bool isValidPort(int p) => p >= 1 && p <= 65535;

/// Resolves the role for a gateway, logging in if accounts are enabled (§14.3).
///
/// - `/api/auth/status` → 404, or `auth_enabled: false` → returns "admin"
///   (gateway open, no token needed).
/// - Otherwise tries saved credentials, then falls back to [askUser] until a
///   login succeeds or the user cancels ([NeedLogin]).
Future<String> ensureLogin(
  GatewayApi api,
  Future<(String, String)?> Function() askUser,
  GatewayCredentialStore store,
  String gatewayId,
) async {
  final http.Response r;
  try {
    r = await http.get(api.base.resolve('/api/auth/status')).timeout(const Duration(seconds: 5));
  } catch (_) {
    // Old gateway without the endpoint / transient error: treat as open.
    return 'admin';
  }
  if (r.statusCode == 404) return 'admin';
  final st = jsonDecode(utf8.decode(r.bodyBytes));
  if (st is! Map || st['auth_enabled'] != true) return 'admin';

  final saved = await store.read(gatewayId);
  if (saved != null) {
    try {
      return await api.login(saved.$1, saved.$2);
    } on Exception {
      // saved creds no longer valid; fall through to interactive login
    }
  }
  while (true) {
    final c = await askUser();
    if (c == null) throw NeedLogin();
    try {
      final role = await api.login(c.$1, c.$2);
      await store.write(gatewayId, c);
      return role;
    } on NeedLogin {
      rethrow;
    } on Exception {
      // wrong password / locked out (429): loop and ask again
    }
  }
}

/// Never-logs-in helper for the common case (accounts not deployed).
Future<void> _noLogin(GatewayApi api) async {}

/// Ties the per-gateway modules together (README_BLE.md §12): REST [api],
/// the telemetry SSE stream, and the persisted [SavedGateway]. UI works with
/// this object rather than the raw clients.
class GatewaySession {
  GatewayApi api;
  final store = GatewayStore();

  /// Latest `event: system` payload (§5.1).
  Map<String, dynamic>? system;

  /// Latest `event: telemetry` payload (§6).
  Map<String, dynamic>? latest;

  String role = 'admin';

  final _systemCtl = StreamController<Map<String, dynamic>>.broadcast();
  final _telemetryCtl = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription<TelemetryEvent>? _sse;

  GatewaySession(Uri base) : api = GatewayApi(base);

  Stream<Map<String, dynamic>> get systemStream => _systemCtl.stream;
  Stream<Map<String, dynamic>> get telemetryStream => _telemetryCtl.stream;

  String? get gatewayId => (system?['gateway'] as Map?)?['gateway_id'] as String?;
  String? get gatewayName => (system?['gateway'] as Map?)?['gateway_name'] as String?;

  /// First time: after Improv provisioning (§3.5) with url "http://<ip>:5050".
  static Future<GatewaySession> afterProvisioning(
    String url, {
    Future<void> Function(GatewayApi) login = _noLogin,
  }) async {
    final s = GatewaySession(Uri.parse(url));
    if (!await s.api.waitReady()) {
      throw Exception('Gateway chưa sẵn sàng / khác mạng'.tr);
    }
    await login(s.api);
    await s._remember(await s.api.get('/api/system') as Map<String, dynamic>);
    return s;
  }

  /// Later launches / IP changed (§1.5): saved IP → mDNS. Verifies `gateway_id`
  /// so we never bind to a different gateway that took the old IP. Returns null
  /// when unreachable — UI should then guide the user to press the button and
  /// re-provision over BLE.
  static Future<GatewaySession?> reconnect(
    SavedGateway g, {
    Future<void> Function(GatewayApi) login = _noLogin,
  }) async {
    for (final host in [g.ip, '${g.hostname}.local']) {
      if (host.isEmpty || host == '.local') continue;
      final s = GatewaySession(Uri.parse('http://$host:${g.port}'));
      try {
        await s.api.get('/api/health').timeout(const Duration(seconds: 3));
        await login(s.api);
        final sys = await s.api.get('/api/system').timeout(const Duration(seconds: 3)) as Map<String, dynamic>;
        if ((sys['gateway'] as Map?)?['gateway_id'] == g.id) {
          // Keep a hand-typed non-default port; the gateway reports its own
          // listen port, which differs from the reachable one behind NAT.
          await s._remember(sys, host: g.port == kGatewayPort ? null : g.ip, port: g.port);
          return s;
        }
      } catch (_) {
        // try next candidate
      }
      s.api.close();
    }
    return null;
  }

  /// Add a gateway by hand from its local address (`localhost`, a LAN IP…)
  /// without BLE. The typed [host] is kept as the saved address, so a
  /// gateway reached through `localhost` stays on `localhost`.
  static Future<GatewaySession> connectManual(String host, {int port = kGatewayPort}) async {
    final s = GatewaySession(Uri.parse('http://$host:$port'));
    try {
      await s.api.get('/api/health').timeout(const Duration(seconds: 5));
      final sys = await s.api.get('/api/system').timeout(const Duration(seconds: 5));
      await s._remember(sys as Map<String, dynamic>, host: host, port: port);
      return s;
    } catch (e) {
      s.api.close();
      throw Exception('Không kết nối được http://{host}:{port} ({e})'.trArgs({'host': host, 'port': port, 'e': e}));
    }
  }

  Future<void> _remember(Map<String, dynamic> sys, {String? host, int? port}) async {
    system = sys;
    _systemCtl.add(sys);
    final gw = sys['gateway'] as Map<String, dynamic>;
    // Always talk over the IP (not .local) for speed, unless the user typed
    // an address by hand (localhost / port-forward) that must be kept.
    final ip = host ?? (gw['ip'] ?? '') as String;
    final p = host != null ? (port ?? kGatewayPort) : ((gw['http_port'] as num?)?.toInt() ?? port ?? kGatewayPort);
    api = GatewayApi(Uri.parse('http://$ip:$p'), token: api.token);
    await store.save(SavedGateway(
      gw['gateway_id'] as String,
      (gw['gateway_name'] ?? '') as String,
      ip,
      (gw['hostname'] ?? '') as String,
      p,
    ));
  }

  /// Open the SSE stream. Call when entering the dashboard / app foreground (§1.6).
  void start({int intervalMs = 100}) {
    _sse ??= openTelemetryStream(api.base, intervalMs: intervalMs, token: api.token).listen((e) {
      if (e.event == 'system') {
        system = e.data;
        _systemCtl.add(e.data);
      } else if (e.event == 'telemetry') {
        latest = e.data;
        _telemetryCtl.add(e.data);
      }
    });
  }

  /// Close the SSE stream. Call on background / leaving the dashboard (§1.6).
  Future<void> stop() async {
    await _sse?.cancel();
    _sse = null;
  }

  Future<void> dispose() async {
    await stop();
    api.close();
    await _systemCtl.close();
    await _telemetryCtl.close();
  }

  // --- data for the UI (§5, §7, §9) ---

  Future<Map<String, dynamic>> init() async => await api.get('/api/metadata/init') as Map<String, dynamic>;

  Future<List<Map<String, dynamic>>> cameras() async =>
      (await api.get('/api/cameras/health') as List).cast<Map<String, dynamic>>();

  Future<List<Map<String, dynamic>>> scanCameras() async =>
      (await api.get('/api/scan') as List).cast<Map<String, dynamic>>();

  /// Save the WHOLE camera list then restart (missing entries are removed, §7).
  Future<void> saveCameras(List<Map<String, dynamic>> cams) async {
    await api.post('/api/save', {'cameras': cams});
    await api.post('/api/restart', const {});
  }

  Future<List<Map<String, dynamic>>> outputs() async =>
      ((await api.get('/api/rtsp/outputs'))['outputs'] as List).cast<Map<String, dynamic>>();

  /// Save the WHOLE push-target list (missing entries are removed, §9).
  Future<void> saveOutputs(List<Map<String, dynamic>> outs) async =>
      await api.post('/api/rtsp/outputs', {'outputs': outs});

  /// Auto-push of every camera to the media server + per-camera status
  /// (README_BLE §9, `GET /api/rtsp/autopush`).
  Future<Map<String, dynamic>> autopush() async => await api.get('/api/rtsp/autopush') as Map<String, dynamic>;

  /// Admin. Only the keys sent change: `enabled`, `url` (template with
  /// `{mount}` / `{gateway_id}`), `cameras: {mount: bool}`.
  Future<Map<String, dynamic>> saveAutopush(Map<String, dynamic> change) async =>
      await api.post('/api/rtsp/autopush', change) as Map<String, dynamic>;

  Future<Map<String, dynamic>> speedtest(String mount) async =>
      await api.post('/api/speedtest', {'mount': mount}) as Map<String, dynamic>;

  /// Board / CPU / memory / storage / network interfaces + uptime
  /// (README_INTEGRATION §6, `GET /api/hardware`).
  Future<Map<String, dynamic>> hardware() async => await api.get('/api/hardware') as Map<String, dynamic>;

  /// WiFi link: ssid, signal %, ip, hotspot state (`GET /api/wifi/status`).
  Future<Map<String, dynamic>> wifiStatus() async =>
      ((await api.get('/api/wifi/status'))['data'] ?? const {}) as Map<String, dynamic>;

  /// WiFi dBm / quality and per-camera round-trip time (`GET /api/signal`).
  Future<Map<String, dynamic>> signal() async => await api.get('/api/signal') as Map<String, dynamic>;

  /// Rename the gateway (§1.4).
  Future<void> rename(String name) async => await api.post('/api/cluster', {'gateway_name': name});

  // --- remote control (TaiLieuTichHop §4.2, §5) ---

  /// Who is logged in and their role; `{}` when accounts are off (§4.1).
  Future<Map<String, dynamic>> me() async {
    try {
      return await api.get('/api/auth/me') as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// RTSP container: `{"status","running","started"}` (§5.1).
  Future<Map<String, dynamic>> rtspStatus() async => await api.get('/api/status') as Map<String, dynamic>;

  Future<void> restart() async => await api.post('/api/restart', const {});

  /// Admin. Start / stop the RTSP container (§5.1).
  Future<void> setContainer(bool run) async =>
      await api.post(run ? '/api/container/start' : '/api/container/stop', const {});

  /// Admin. Last 100 log lines (§5.1).
  Future<List<String>> logs() async =>
      ((await api.get('/api/logs'))['lines'] as List? ?? const []).map((e) => '$e').toList();

  /// Saved cameras + RTSP server settings (§5.2).
  Future<Map<String, dynamic>> config() async => await api.get('/api/config') as Map<String, dynamic>;

  /// ICMP ping of one camera (not ONVIF/stream): `{"success","rtt_ms"}` (§5.2).
  Future<Map<String, dynamic>> pingCamera(String mount) async =>
      await api.post('/api/test', {'mount': mount}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> network() async => await api.get('/api/network') as Map<String, dynamic>;

  /// Bluetooth / Improv state (§5.4).
  Future<Map<String, dynamic>> ble() async => await api.get('/api/ble') as Map<String, dynamic>;

  Future<void> wifiDisconnect() async => await api.post('/api/wifi/disconnect', const {});

  Future<void> wifiForget(String ssid) async => await api.post('/api/wifi/forget', {'ssid': ssid});

  /// Gateway identity in the cluster; POST only the changed keys (admin, §5.6).
  Future<Map<String, dynamic>> cluster() async => await api.get('/api/cluster') as Map<String, dynamic>;

  Future<void> saveCluster(Map<String, dynamic> change) async => await api.post('/api/cluster', change);

  /// Admin. MQTT broker config (password masked) (§5.6).
  Future<Map<String, dynamic>> mqttConfig() async =>
      ((await api.get('/api/mqtt/config'))['config'] ?? const {}) as Map<String, dynamic>;

  Future<Map<String, dynamic>> mqttTest() async => await api.post('/api/mqtt/test', const {}) as Map<String, dynamic>;

  Future<void> mqttPublish(String event) async => await api.post('/api/mqtt/publish', {'event': event});

  /// Admin. Webhook push state / push now (§5.6).
  Future<Map<String, dynamic>> webhookState() async => await api.get('/api/metadata/state') as Map<String, dynamic>;

  Future<void> webhookPush(String event) async => await api.post('/api/metadata/push', {'event': event});
}
