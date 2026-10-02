import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/gateway_session.dart';
import 'gateway_store.dart';
import '../utils/app_strings.dart';
import 'gateway_image_store.dart';

/// Holds the single active [GatewaySession] app-wide and reconnects to a saved
/// gateway on demand (README_BLE.md §1.5, §1.6). Screens that talk to the
/// gateway over the LAN read [session] from here rather than creating their own.
class GatewaySessionStore extends ChangeNotifier {
  static final GatewaySessionStore instance = GatewaySessionStore._();
  GatewaySessionStore._();

  final _store = GatewayStore();

  GatewaySession? _session;
  GatewaySession? get session => _session;

  bool _connecting = false;
  bool get connecting => _connecting;

  String? _error;
  String? get error => _error;

  bool get hasSavedGateway => _cachedSavedCount > 0;
  int _cachedSavedCount = 0;

  static const _selectedKey = 'eyerus_selected_gateway';

  /// Placeholder homes offered until the first real gateway is set up.
  /// Selectable, but they never open a gateway session.
  static const _samplePrefix = 'sample:';
  static const sampleCompanyId = '${_samplePrefix}company';
  static const sampleTrafficId = '${_samplePrefix}traffic';
  static const sampleHomes = [
    SavedGateway(sampleCompanyId, 'Công ty', '', ''),
    SavedGateway(sampleTrafficId, 'Giao thông', '', ''),
  ];
  static bool isSample(String id) => id.startsWith(_samplePrefix);

  /// Stream-code prefix of the traffic cameras (giaothong1..4).
  static const trafficCameraPrefix = 'giaothong';

  /// Whether a camera belongs to [homeId]. Sample homes split cameras by
  /// stream code: "Giao thông" = giaothong*, "Công ty" = everything else.
  /// `null` (all) and real gateways show every camera — cloud cameras
  /// aren't linked to a gateway yet.
  static bool homeIncludesCamera(String? homeId, String cameraCode) {
    final isTraffic = cameraCode.toLowerCase().startsWith(trafficCameraPrefix);
    if (homeId == sampleTrafficId) return isTraffic;
    if (homeId == sampleCompanyId) return !isTraffic;
    return true;
  }

  /// Saved gateways shown as "homes" in the Camera tab header picker.
  List<SavedGateway> _saved = [];
  List<SavedGateway> get savedGateways => List.unmodifiable(_saved);

  /// What the picker lists: real gateways, or the samples when there are none.
  List<SavedGateway> get homes => _saved.isEmpty ? sampleHomes : savedGateways;

  /// Home the user picked in the header; defaults to the first one listed.
  String? _selectedId;
  SavedGateway? get selectedGateway {
    final list = homes;
    for (final g in list) {
      if (g.id == _selectedId) return g;
    }
    return list.first;
  }

  /// Reload saved gateways + the persisted selection.
  Future<void> loadSaved() async {
    _saved = await _store.all();
    _cachedSavedCount = _saved.length;
    _selectedId = (await SharedPreferences.getInstance()).getString(_selectedKey);
    notifyListeners();
  }

  /// Pick [gatewayId] as the current home and switch the live session to it.
  /// Returns false when the gateway can't be reached (see [error]); the
  /// selection is kept either way so the next reconnect targets it.
  Future<bool> select(String gatewayId) async {
    _selectedId = gatewayId;
    await (await SharedPreferences.getInstance()).setString(_selectedKey, gatewayId);
    notifyListeners();
    if (isSample(gatewayId)) return true;
    return await ensureConnected(gatewayId: gatewayId) != null;
  }

  /// Whether a live session is currently connected.
  bool get isConnected => _session != null;

  /// Ensures a connected session, reconnecting to the given (or first saved)
  /// gateway if needed. Returns null when there is no saved gateway or it is
  /// unreachable — the UI should then guide the user to onboard / press the
  /// gateway button (§1.5).
  Future<GatewaySession?> ensureConnected({String? gatewayId}) async {
    final selected = _selectedId;
    if (gatewayId == null && selected != null && !isSample(selected)) gatewayId = selected;
    if (_session != null && (gatewayId == null || _session!.gatewayId == gatewayId)) {
      return _session;
    }

    _connecting = true;
    _error = null;
    notifyListeners();

    try {
      final saved = await _store.all();
      _cachedSavedCount = saved.length;
      if (saved.isEmpty) {
        _error = 'Chưa có gateway nào. Hãy thêm gateway trước.'.tr;
        return null;
      }
      final target =
          gatewayId == null ? saved.first : saved.firstWhere((g) => g.id == gatewayId, orElse: () => saved.first);

      final s = await GatewaySession.reconnect(target);
      if (s == null) {
        _error =
            'Không tìm thấy gateway trong mạng. Kiểm tra WiFi điện thoại, hoặc nhấn nhanh nút trên gateway rồi cài lại.'
                .tr;
        return null;
      }
      await _swap(s);
      return s;
    } catch (e) {
      _error = 'Lỗi kết nối gateway: {e}'.trArgs({'e': e});
      return null;
    } finally {
      _connecting = false;
      notifyListeners();
    }
  }

  /// Adopt a session created elsewhere (e.g. right after BLE provisioning).
  Future<void> adopt(GatewaySession s) async {
    await _swap(s);
    // A freshly provisioned gateway becomes the current home.
    final id = s.gatewayId;
    if (id != null) {
      await (await SharedPreferences.getInstance()).setString(_selectedKey, id);
    }
    await loadSaved();
  }

  Future<void> _swap(GatewaySession s) async {
    final old = _session;
    _session = s;
    if (old != null && !identical(old, s)) {
      await old.dispose();
    }
  }

  Future<void> disconnect() async {
    final old = _session;
    _session = null;
    notifyListeners();
    await old?.dispose();
  }

  /// Add a gateway by its local address (default `localhost`) and make it
  /// the current home. Throws with a readable message when unreachable.
  Future<void> addManual(String host, {int port = kGatewayPort}) async {
    final s = await GatewaySession.connectManual(host, port: port);
    await adopt(s);
  }

  /// Remove [gatewayId] from this phone: drops its saved entry and
  /// credentials, closes the live session if it pointed there, and clears
  /// the selection so the picker falls back to the next gateway.
  Future<void> forget(String gatewayId) async {
    if (_session?.gatewayId == gatewayId) await disconnect();
    await _store.remove(gatewayId);
    await GatewayCredentialStore().clear(gatewayId);
    await GatewayImageStore.instance.reset(gatewayId);
    if (_selectedId == gatewayId) {
      _selectedId = null;
      await (await SharedPreferences.getInstance()).remove(_selectedKey);
    }
    await loadSaved();
  }

  Future<void> refreshSavedCount() => loadSaved();
}
