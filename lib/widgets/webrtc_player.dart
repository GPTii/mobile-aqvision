import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../theme/app_colors.dart';

/// How long we wait for the WebRTC handshake/ICE to actually produce video
/// before treating it as failed. Some failure modes (blocked UDP, server
/// misconfig) never fire an explicit error — they just hang forever.
const Duration _kConnectTimeout = Duration(seconds: 8);

class WebRTCPlayerWidget extends StatefulWidget {
  final String app;
  final String stream;

  /// Called once when WebRTC playback fails or times out. When provided,
  /// this widget stays silent (no red error UI) since the caller is
  /// expected to swap to a fallback player instead.
  final VoidCallback? onError;

  const WebRTCPlayerWidget({
    super.key,
    required this.app,
    required this.stream,
    this.onError,
  });

  @override
  State<WebRTCPlayerWidget> createState() => _WebRTCPlayerWidgetState();
}

class _WebRTCPlayerWidgetState extends State<WebRTCPlayerWidget> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool _initialized = false;
  bool _connecting = false;
  String? _error;
  bool _reportedError = false;
  Timer? _connectTimeoutTimer;

  String _iceState = 'unknown';
  String _connState = 'unknown';

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  /// Records the failure and — once — notifies the caller so it can fall
  /// back to another player. Never shows the visible error UI when a
  /// fallback handler is set.
  void _fail(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    if (!_reportedError) {
      _reportedError = true;
      widget.onError?.call();
    }
  }

  @override
  void didUpdateWidget(covariant WebRTCPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.app != widget.app || oldWidget.stream != widget.stream) {
      _cleanup();
      _initWebRTC();
    }
  }

  Future<void> _initWebRTC() async {
    if (_connecting) return;
    _connecting = true;
    _error = null;
    _initialized = false;
    _iceState = 'new';
    _connState = 'new';
    if (mounted) setState(() {});

    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = Timer(_kConnectTimeout, () {
      if (!_initialized) {
        _fail('Kết nối WebRTC quá thời gian chờ');
      }
    });

    try {
      await _renderer.initialize();

      _peerConnection = await createPeerConnection({
        'sdpSemantics': 'unified-plan',
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'}
        ],
      });

      _peerConnection!.onTrack = (event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          _renderer.srcObject = event.streams[0];
          _connectTimeoutTimer?.cancel();
          if (mounted) setState(() => _initialized = true);
        }
      };

      _peerConnection!.onIceConnectionState = (state) {
        if (mounted) setState(() => _iceState = state.name);
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
            state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
          _fail('ICE Connection Failed (Có thể do mạng chặn UDP)');
        }
      };

      _peerConnection!.onConnectionState = (state) {
        if (mounted) setState(() => _connState = state.name);
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _fail('WebRTC Connection Failed');
        }
      };

      // Receive-only: add transceiver for video + audio
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );
      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final uri = Uri.parse(
        '${ApiConfig.mediaBase}/index/api/webrtc'
        '?app=${Uri.encodeComponent(widget.app)}&stream=${Uri.encodeComponent(widget.stream)}&type=play',
      );
      final res = await http.post(
        uri,
        headers: {
          'Content-Type': 'text/plain;charset=utf-8',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: offer.sdp,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['sdp'] != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(json['sdp'], 'answer'),
          );
        } else {
          throw Exception(json['msg'] ?? 'Server không trả SDP answer');
        }
      } else {
        throw Exception('Server lỗi ${res.statusCode}');
      }
    } catch (e) {
      _fail(e.toString());
    } finally {
      _connecting = false;
    }
  }

  void _cleanup() {
    _connectTimeoutTimer?.cancel();
    _renderer.srcObject = null;
    _peerConnection?.close();
    _peerConnection = null;
    _initialized = false;
    _connecting = false;
  }

  @override
  void dispose() {
    _cleanup();
    _renderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A fallback handler means the caller is about to swap this widget out
    // for another player — stay on the connecting look, never show the red
    // error box, so the failure is invisible to the user.
    if (_error != null && widget.onError != null) {
      return _buildConnecting();
    }
    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.danger, size: 34),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  _cleanup();
                  _initWebRTC();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Thử lại'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (!_initialized) {
      return _buildConnecting();
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: Colors.grey[900], // Dark gray background to see if widget is rendering
          child: RTCVideoView(
            _renderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
        ),
      ],
    );
  }

  Widget _buildConnecting() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Đang kết nối…',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
