import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraCallScreen extends StatefulWidget {
  final String voiceSessionId;
  final String agoraChannel;
  final String consultantId;

  const AgoraCallScreen({
    super.key,
    required this.voiceSessionId,
    required this.agoraChannel,
    required this.consultantId,
  });

  @override
  State<AgoraCallScreen> createState() => _AgoraCallScreenState();
}

class _AgoraCallScreenState extends State<AgoraCallScreen> {
  static const String baseUrl = 'http://10.0.2.2:8080/busanbank';

  Uri _statusUri(String sid) =>
      Uri.parse('$baseUrl/api/call/$sid/status-with-token');

  Uri _endUri(String sid) =>
      Uri.parse('$baseUrl/api/call/voice/end/$sid');

  RtcEngine? _engine;
  Timer? _pollTimer;

  bool _joined = false;
  bool _muted = false;
  bool _loading = true;

  int _localUid = 0;
  int? _remoteUid;

  String _status = '초기화 중...';
  String _log = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _leaveAgora();
    super.dispose();
  }

  void _append(String s) {
    setState(() => _log = '$_log\n$s');
  }

  Future<void> _boot() async {
    // 1. 마이크 권한
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() {
        _loading = false;
        _status = '마이크 권한 필요';
      });
      return;
    }

    // 2. 토큰 폴링
    _status = '토큰 대기 중...';
    int tick = 0;

    _pollTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      tick++;
      if (tick > 30) {
        t.cancel();
        setState(() {
          _loading = false;
          _status = '토큰 대기 시간 초과';
        });
        return;
      }

      final info = await _fetchTokenOnce();
      if (info != null) {
        t.cancel();
        await _joinAgora(info);
      }
    });
  }

  Future<_TokenInfo?> _fetchTokenOnce() async {
    try {
      final res = await http.post(
        _statusUri(widget.voiceSessionId),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': 'CUSTOMER'}),
      );

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body);
      final tokenObj = data['token'];
      if (tokenObj == null) return null;

      return _TokenInfo(
        appId: tokenObj['appId'],
        channel: tokenObj['channel'],
        uid: tokenObj['uid'] is int
            ? tokenObj['uid']
            : int.tryParse('${tokenObj['uid']}') ?? 0,
        token: tokenObj['token'],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _joinAgora(_TokenInfo info) async {
    setState(() {
      _loading = true;
      _status = 'Agora 입장 중...';
    });

    final engine = createAgoraRtcEngine();
    _engine = engine;
    _localUid = info.uid;

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (_, __) {
          setState(() {
            _joined = true;
            _loading = false;
            _status = '통화 중';
          });
        },
        onUserJoined: (_, uid, __) {
          setState(() => _remoteUid = uid);
        },
        onUserOffline: (_, __, ___) {
          setState(() => _remoteUid = null);
        },
      ),
    );

    await engine.initialize(RtcEngineContext(appId: info.appId));
    await engine.enableAudio();
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await engine.joinChannel(
      token: info.token,
      channelId: info.channel,
      uid: info.uid,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> _leaveAgora() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}
  }

  Future<void> _toggleMute() async {
    if (_engine == null) return;
    _muted = !_muted;
    await _engine!.muteLocalAudioStream(_muted);
    setState(() {});
  }

  Future<void> _hangup() async {
    await _leaveAgora();
    await http.post(_endUri(widget.voiceSessionId));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전화 통화')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_status, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('localUid=$_localUid / remoteUid=${_remoteUid ?? "-"}'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _joined ? _toggleMute : null,
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                    label: Text(_muted ? '마이크 켜기' : '마이크 끄기'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _hangup,
                    icon: const Icon(Icons.call_end),
                    label: const Text('통화 종료'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenInfo {
  final String appId;
  final String channel;
  final int uid;
  final String token;

  _TokenInfo({
    required this.appId,
    required this.channel,
    required this.uid,
    required this.token,
  });
}
