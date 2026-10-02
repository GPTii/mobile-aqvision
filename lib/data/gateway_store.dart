import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A gateway remembered on the phone (README_BLE.md §1.4).
///
/// [id] (`gateway_id`) is the stable primary key — it survives IP/WiFi changes.
/// [ip] may change via DHCP; [hostname] lets us find it again over mDNS.
/// [port] is the config-server port — 5050 unless the user typed another one
/// (port-forward / NAT / a gateway configured on a different port).
class SavedGateway {
  static const defaultPort = 5050;

  final String id;
  final String name;
  final String ip;
  final String hostname;
  final int port;

  const SavedGateway(this.id, this.name, this.ip, this.hostname, [this.port = defaultPort]);

  /// `192.168.1.189` for the default port, `192.168.1.189:8080` otherwise.
  String get address => port == defaultPort ? ip : '$ip:$port';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'hostname': hostname,
        'port': port,
      };

  static SavedGateway fromJson(Map<String, dynamic> j) => SavedGateway(
        (j['id'] ?? '') as String,
        (j['name'] ?? '') as String,
        (j['ip'] ?? '') as String,
        (j['hostname'] ?? '') as String,
        (j['port'] as num?)?.toInt() ?? defaultPort,
      );

  SavedGateway copyWith({String? name, String? ip, String? hostname, int? port}) =>
      SavedGateway(id, name ?? this.name, ip ?? this.ip, hostname ?? this.hostname, port ?? this.port);
}

/// Persists the list of known gateways (§1.4). Keyed by `gateway_id`.
class GatewayStore {
  static const _key = 'eyerus_gateways';

  Future<List<SavedGateway>> all() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => SavedGateway.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Upsert by `gateway_id`.
  Future<void> save(SavedGateway g) async {
    final list = (await all()).where((x) => x.id != g.id).toList()..add(g);
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<void> remove(String id) async {
    final list = (await all()).where((x) => x.id != id).toList();
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  Future<SavedGateway?> byId(String id) async {
    for (final g in await all()) {
      if (g.id == id) return g;
    }
    return null;
  }
}

/// Login credentials per gateway, used to re-auth silently (§14.3).
///
/// NOTE: gateway accounts are "in source, not yet deployed" per README_BLE.md,
/// so this path is dormant today. When it goes live these should move to
/// platform secure storage (Keychain / EncryptedSharedPreferences) — see the
/// `flutter_secure_storage` follow-up. Stored in SharedPreferences for now.
class GatewayCredentialStore {
  static const _key = 'eyerus_gateway_credentials';

  Future<Map<String, List<String>>> _load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    if (raw == null) return {};
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return m.map((k, v) => MapEntry(k, (v as List).cast<String>()));
  }

  /// Returns (username, password) for [gatewayId], or null.
  Future<(String, String)?> read(String gatewayId) async {
    final c = (await _load())[gatewayId];
    if (c == null || c.length < 2) return null;
    return (c[0], c[1]);
  }

  Future<void> write(String gatewayId, (String, String) creds) async {
    final m = await _load();
    m[gatewayId] = [creds.$1, creds.$2];
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(m));
  }

  Future<void> clear(String gatewayId) async {
    final m = await _load()
      ..remove(gatewayId);
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(m));
  }
}
