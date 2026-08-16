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
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }
  
  Future<void> _initWebRTC() async {
    try {
      await _renderer.initialize();
      
      _peerConnection = await createPeerConnection({
        'sdpSemantics': 'unified-plan',
        'iceServers': [{'urls': 'stun:stun.l.google.com:19302'}]
      });
      
      _peerConnection!.onTrack = (event) {
        if (event.track.kind == 'video' && event.streams.isNotEmpty) {
          _renderer.srcObject = event.streams[0];
          if (mounted) setState(() { _initialized = true; });
        }
      };
      
      RTCSessionDescription offer = await _peerConnection!.createOffer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      await _peerConnection!.setLocalDescription(offer);
      
      // We must strip http:// or https:// from mediaBase for ZLMediaKit API
      // Since ApiConfig.mediaBase is http://xxx, the endpoint is directly on it.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      
      final uri = Uri.parse('${ApiConfig.mediaBase}/index/api/webrtc?app=${widget.app}&stream=${widget.stream}&type=play');
      final res = await http.post(uri, 
        headers: {
          'Content-Type': 'text/plain;charset=utf-8',
          if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: offer.sdp,
      );
      
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['sdp'] != null) {
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(json['sdp'], 'answer')
          );
        } else {
          throw Exception("Invalid WebRTC response from server");
        }
      } else {
        throw Exception("Server responded with ${res.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); });
      }
    }
  }
  
  @override
  void dispose() {
    _renderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text('WebRTC Error: $_error', style: const TextStyle(color: AppColors.danger)),
      );
    }
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    return RTCVideoView(
      _renderer, 
      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    );
  }
}
