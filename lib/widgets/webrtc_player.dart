import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../theme/app_colors.dart';

class WebRTCPlayerWidget extends StatefulWidget {
  final String app;
  final String stream;

  const WebRTCPlayerWidget({super.key, required this.app, required this.stream});

  @override
  State<WebRTCPlayerWidget> createState() => _WebRTCPlayerWidgetState();
}

class _WebRTCPlayerWidgetState extends State<WebRTCPlayerWidget> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  bool _initialized = false;
  bool _connecting = false;
  String? _error;

  String _iceState = 'unknown';
  String _connState = 'unknown';

  @override
  void initState() {
    super.initState();
    _initWebRTC();
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
          if (mounted) setState(() => _initialized = true);
        }
      };

      _peerConnection!.onIceConnectionState = (state) {
        if (mounted) {
          setState(() {
            _iceState = state.name;
            if (state == RTCIceConnectionState.RTCIceConnectionStateFailed || 
                state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
              _error = 'ICE Connection Failed (Có thể do mạng Simulator chặn UDP)';
            }
          });
        }
      };
      
      _peerConnection!.onConnectionState = (state) {
        if (mounted) {
          setState(() {
            _connState = state.name;
            if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
              _error = 'WebRTC Connection Failed';
            }
          });
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
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      _connecting = false;
    }
  }

  void _cleanup() {
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
                'Đang kết nối WebRTC…',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      );
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
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            color: Colors.black54,
            child: Text(
              'ICE: $_iceState | Conn: $_connState',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }
}
