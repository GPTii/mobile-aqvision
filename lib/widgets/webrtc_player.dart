import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../data/video_preload_cache.dart';
import '../theme/app_colors.dart';
import '../utils/app_strings.dart';

class WebRTCPlayerWidget extends StatefulWidget {
  final String app;
  final String stream;

  /// Called once when WebRTC can't play (signaling error, ICE / connection
  /// failure, or no video within [_connectTimeout]). When set, the parent
  /// switches to HLS by itself and no error screen is shown.
  final VoidCallback? onFallback;

  const WebRTCPlayerWidget({
    super.key,
    required this.app,
    required this.stream,
    this.onFallback,
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

  /// No first video frame by then → treat WebRTC as broken (UDP blocked…).
  static const _connectTimeout = Duration(seconds: 12);
  Timer? _timeout;
  bool _fellBack = false;

  @override
  void initState() {
    super.initState();
    // Background HLS warm-up competes with WebRTC for the hardware decoder,
    // CPU and bandwidth and makes playback stutter; hold it while we play.
    VideoPreloadCache.instance.suspend();
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
    if (mounted) setState(() {});
    _timeout?.cancel();
    _timeout = Timer(_connectTimeout, () {
      if (!_initialized) _fail('Kết nối WebRTC thất bại'.tr);
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
          if (mounted) setState(() => _initialized = true);
        }
      };

      _peerConnection!.onIceConnectionState = (state) {
        // "Disconnected" is often a brief blip on mobile networks that
        // ICE recovers from by itself; only give up on "Failed".
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          _fail('Kết nối WebRTC thất bại'.tr);
        }
      };

      _peerConnection!.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _fail('Kết nối WebRTC thất bại'.tr);
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

      final base = ApiConfig.isLocal
          ? ApiConfig.mediaBase
          : ApiConfig.mediaBase.replaceFirst('http://', 'https://');
      final uri = Uri.parse(
        '$base/index/api/webrtc'
        '?app=${Uri.encodeComponent(widget.app)}&stream=${Uri.encodeComponent(widget.stream)}&type=play',
      );

      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 10);

      final request = await httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'text/plain');
      request.headers.set('User-Agent',
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
      if (token.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $token');
      }

      final sdpBytes = utf8.encode(offer.sdp!);
      request.headers.set('Content-Length', sdpBytes.length.toString());
      request.add(sdpBytes);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (!mounted) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(responseBody);
        if (json['sdp'] != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(json['sdp'], 'answer'),
          );
        } else {
          throw Exception(json['msg'] ?? 'Server không trả SDP answer'.tr);
        }
      } else {
        throw Exception('Server lỗi {code}'.trArgs({'code': response.statusCode}));
      }
    } catch (e) {
      _fail(e.toString());
    } finally {
      _connecting = false;
    }
  }

  /// WebRTC can't play: hand over to HLS if the parent allows, otherwise
  /// show the error with a retry button.
  void _fail(String message) {
    if (!mounted) return;
    _timeout?.cancel();
    final fallback = widget.onFallback;
    if (fallback != null) {
      if (_fellBack) return;
      _fellBack = true;
      _cleanup();
      // Parent rebuilds with the HLS player; don't setState mid-callback.
      WidgetsBinding.instance.addPostFrameCallback((_) => fallback());
      return;
    }
    setState(() => _error = message);
  }

  void _cleanup() {
    _timeout?.cancel();
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
    VideoPreloadCache.instance.resume();
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
              Icon(Icons.error_outline, color: AppColors.danger, size: 34),
              SizedBox(height: 8),
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
              SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  _cleanup();
                  _initWebRTC();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text('Thử lại'.tr),
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
        child: Center(
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
                'Đang kết nối…'.tr,
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
      ],
    );
  }
}
