import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/gateway_session.dart';
import '../../data/gateway_session_store.dart';
import '../../data/gateway_store.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_strings.dart';
import 'demo_gateway_data.dart';
import '../../widgets/app_ui.dart';

/// Gateway's own Maintain web (MaintainApp/config_server.py, `http://<ip>:5050`)
/// in embed mode (README_BLE §14.4): RTSP server, push outputs, MQTT/Webhook,
/// cluster, logs… Admin-only entry point — see [AuthStore.isAdmin].
///
/// With a saved [gateway] it reuses the app's gateway session (IP + token).
/// Without one (no gateway set up yet, demo gateway, or unreachable), the
/// admin types the gateway IP and the page is opened directly.
class MaintainWebScreen extends StatefulWidget {
  final SavedGateway? gateway;
  const MaintainWebScreen({super.key, this.gateway});

  @override
  State<MaintainWebScreen> createState() => _MaintainWebScreenState();
}

class _MaintainWebScreenState extends State<MaintainWebScreen> {
  static const _lastHostKey = 'maintain_last_host';

  WebViewController? _controller;
  bool _connecting = true;
  bool _askHost = false;
  String? _error;
  int _progress = 0;
  String _title = '';
  final _hostCtl = TextEditingController();

  SavedGateway? get _realGateway {
    final g = widget.gateway;
    return g == null || DemoGateway.isDemo(g.id) ? null : g;
  }

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _hostCtl.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final last = (await SharedPreferences.getInstance()).getString(_lastHostKey);
    _hostCtl.text = [widget.gateway?.address, last, '192.168.1.189'].firstWhere((h) => h != null && h.isNotEmpty)!;
    if (_realGateway != null) {
      await _openSaved();
    } else {
      setState(() {
        _connecting = false;
        _askHost = true;
      });
    }
  }

  /// Saved gateway: go through the shared session so the page gets its token.
  Future<void> _openSaved() async {
    final g = _realGateway!;
    setState(() {
      _connecting = true;
      _error = null;
      _askHost = false;
    });
    final session = await GatewaySessionStore.instance.ensureConnected(gatewayId: g.id);
    if (!mounted) return;
    if (session == null) {
      // Unreachable by saved IP/mDNS: let the admin type the address.
      setState(() {
        _connecting = false;
        _askHost = true;
        _error = GatewaySessionStore.instance.error ?? 'Không kết nối được gateway'.tr;
      });
      return;
    }
    // `?embed=1` hides the page's own logo/status bar; `#token=` hands the
    // app's gateway session to the page (it swaps it for a cookie via
    // /api/auth/adopt). No token when gateway accounts are off — page is open.
    final token = session.api.token;
    _load(
      session.api.base.resolve('/?embed=1${token == null ? '' : '#token=${Uri.encodeComponent(token)}'}'),
      title: g.name.isNotEmpty ? g.name : g.id,
    );
  }

  /// Manual address: open the page directly; it shows its own login form
  /// when the gateway has accounts enabled.
  Future<void> _openHost() async {
    final (h, port) = parseGatewayAddress(_hostCtl.text);
    if (h.isEmpty) return;
    final host = port == kGatewayPort ? h : '$h:$port';
    final base = Uri.parse('http://$h:$port');
    await (await SharedPreferences.getInstance()).setString(_lastHostKey, host);
    FocusManager.instance.primaryFocus?.unfocus();
    _load(base.resolve('/?embed=1'), title: host);
  }

  void _load(Uri url, {required String title}) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        onWebResourceError: (e) {
          // Only a failed main page is fatal; broken sub-resources are not.
          if (e.isForMainFrame == true && mounted) {
            setState(() {
              _controller = null;
              _askHost = true;
              _error = 'Không mở được trang bảo trì: {e}'.trArgs({'e': e.description});
            });
          }
        },
      ))
      ..loadRequest(url);

    setState(() {
      _controller = controller;
      _connecting = false;
      _askHost = false;
      _error = null;
      _progress = 0;
      _title = title;
    });
  }

  Future<void> _reload() async {
    final c = _controller;
    if (c != null) return c.reload();
    if (_realGateway != null) return _openSaved();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // Back walks the web page history first, then leaves the screen.
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final c = _controller;
        if (c != null && await c.canGoBack()) {
          await c.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: AppBackground(
          child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bảo trì Gateway'.tr,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (_title.isNotEmpty)
                Text(_title,
                    overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            ],
          ),
          actions: [
            if (_controller != null)
              IconButton(
                tooltip: 'Đổi địa chỉ Gateway'.tr,
                icon: const Icon(Icons.edit_location_alt_outlined),
                onPressed: () => setState(() {
                  _controller = null;
                  _askHost = true;
                }),
              ),
            IconButton(
              tooltip: 'Tải lại'.tr,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _reload,
            ),
          ],
          bottom: _controller != null && _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress / 100,
                    minHeight: 2,
                    color: AppColors.accent,
                    backgroundColor: Colors.transparent,
                  ),
                )
              : null,
        ),
        body: _connecting
            ? Center(child: CircularProgressIndicator(color: AppColors.accent))
            : _askHost || _controller == null
                ? _HostForm(controller: _hostCtl, error: _error, onOpen: _openHost)
                : WebViewWidget(controller: _controller!),
      )),
    );
  }
}

class _HostForm extends StatelessWidget {
  final TextEditingController controller;
  final String? error;
  final VoidCallback onOpen;
  const _HostForm({required this.controller, required this.error, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      children: [
        Icon(Icons.admin_panel_settings_outlined, size: 48, color: AppColors.accent),
        const SizedBox(height: 12),
        Text('Mở web quản trị Gateway'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Nhập IP của Gateway trong cùng mạng WiFi với điện thoại.'.tr,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5)),
        if (error != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(error!, style: TextStyle(fontSize: 12.5, color: AppColors.danger, height: 1.4)),
          ),
        ],
        const SizedBox(height: 18),
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => onOpen(),
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: 'Địa chỉ Gateway'.tr,
            hintText: '192.168.1.189',
            helperText:
                'Port mặc định {port}. Port khác thì nhập kèm, VD 192.168.1.189:8080'.trArgs({'port': kGatewayPort}),
            helperMaxLines: 2,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onOpen,
          icon: const Icon(Icons.open_in_browser_rounded),
          label: Text('Mở trang bảo trì'.tr),
        ),
      ],
    );
  }
}
