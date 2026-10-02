import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/gateway_store.dart';
import 'gateway_session.dart';

/// Finds a gateway that is on the phone's WiFi but not saved in the app yet,
/// by probing `http://<subnet>.1-254:5050/api/system`. Used when the BLE link
/// fails right after the WiFi was sent (the gateway is online, but its
/// "http://ip:5050" result never reached us).
///
/// With a label id (Eyerus-8C09 → 8C09, or the WiFi MAC one below it) only a
/// gateway whose name / hostname carries it is accepted; without one, the only
/// new gateway found.
/// Returns its base URL, or null.
Future<String?> findNewGatewayOnLan({required String labelName, required String mac}) async {
  final prefixes = await _lanPrefixes();
  if (prefixes.isEmpty) return null;
  final saved = {for (final g in await GatewayStore().all()) g.id};
  final hints = _idHints(labelName, mac);

  final found = <String, Map>{}; // url -> gateway map
  final client = http.Client();
  try {
    for (final prefix in prefixes) {
      // Batches keep the number of open sockets reasonable on phones.
      for (var start = 1; start <= 254; start += 64) {
        await Future.wait([
          for (var i = start; i < start + 64 && i <= 254; i++) _probe(client, '$prefix$i', found),
        ]);
      }
    }
  } finally {
    client.close();
  }

  final fresh = found.entries.where((e) => !saved.contains('${e.value['gateway_id']}')).toList();
  bool matches(Map gw) {
    final text = '${gw['gateway_name'] ?? ''} ${gw['hostname'] ?? ''}'.toUpperCase();
    return hints.any(text.contains);
  }

  // With a label id, only its own gateway counts — never adopt a neighbour's.
  if (hints.isNotEmpty) {
    final matched = fresh.where((e) => matches(e.value)).toList();
    return matched.isEmpty ? null : matched.first.key;
  }
  return fresh.length == 1 ? fresh.first.key : null;
}

Future<void> _probe(http.Client client, String ip, Map<String, Map> found) async {
  final base = 'http://$ip:$kGatewayPort';
  try {
    final r = await client.get(Uri.parse('$base/api/system')).timeout(const Duration(seconds: 2));
    if (r.statusCode != 200) return;
    final gw = (jsonDecode(utf8.decode(r.bodyBytes)) as Map)['gateway'];
    if (gw is Map && gw['gateway_id'] != null) found[base] = gw;
  } catch (_) {
    // not a gateway / unreachable
  }
}

/// "192.168.1." for each private IPv4 address of the phone (WiFi, not mobile data).
Future<List<String>> _lanPrefixes() async {
  final out = <String>{};
  for (final iface in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    for (final a in iface.addresses) {
      final p = a.address.split('.');
      if (p.length != 4 || a.isLoopback) continue;
      final private = p[0] == '10' ||
          (p[0] == '192' && p[1] == '168') ||
          (p[0] == '172' && (int.tryParse(p[1]) ?? 0) >= 16 && (int.tryParse(p[1]) ?? 0) <= 31);
      if (private) out.add('${p[0]}.${p[1]}.${p[2]}.');
    }
  }
  return out.toList();
}

/// "8C09" from "Eyerus-8C09" plus the WiFi-MAC neighbour "8C08" (the hotspot /
/// hostname use the WiFi MAC, one below the Bluetooth one on the Radxa).
List<String> _idHints(String labelName, String mac) {
  final ids = <String>{};
  final i = labelName.lastIndexOf('-');
  if (i >= 0 && i < labelName.length - 1) ids.add(labelName.substring(i + 1).toUpperCase());
  final m = mac.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
  if (m.length >= 4) ids.add(m.substring(m.length - 4).toUpperCase());
  for (final id in [...ids]) {
    final v = int.tryParse(id, radix: 16);
    if (v != null) ids.add(((v - 1) & 0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0'));
  }
  ids.removeWhere((e) => e.length < 4);
  return ids.toList();
}
