import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:tkbank/config/api_config.dart';
import 'package:tkbank/services/token_storage_service.dart';

class AgoraCallScreen extends StatefulWidget {
  final String voiceSessionId; // TEST_SESSION_APP_XXXX
  final String agoraChannel;   // 서버가 내려준 채널(없으면 fallback 가능)
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
  final TokenStorageService _tokenStorage = TokenStorageService();

  // ✅ status-with-token: POST /api/call/{sid}/status-with-token
  Uri _statusUri(String sid) =>
      Uri.parse('${ApiConfig.baseUrl}/api/call/$sid/status-with-token');

  // ✅ 고객 end: POST /api/call/{sid}/end (CallEndController)
  Uri _endUri(String sid) =>
      Uri.parse('${ApiConfig.baseUrl}/api/call/$sid/end');

  RtcEngine? _engine;
  Timer? _pollTimer;

  bool _joined = false;
  bool _muted = false;
  bool _loading = true;
  bool _ending = false;

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
    if (!mounted) return;
    setState(() => _log = '$_log\n$s');
  }

  Future<void> _boot() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() {
        _loading = false;
        _status = '마이크 권한이 필요합니다.';
      });
      return;
    }

    setState(() {
      _status = '토큰 대기 중...';
      _loading = false;
    });

    int tick = 0;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      tick++;
      if (tick > 30) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          _status = '토큰 대기 시간 초과';
          _loading = false;
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
      final jwt = await _tokenStorage.readToken();

      final res = await http.post(
        _statusUri(widget.voiceSessionId),
        headers: {
          'Content-Type': 'application/json',
          if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'role': 'CUSTOMER'}),
      );

      final body = utf8.decode(res.bodyBytes);
      debugPrint('📌 [status-with-token] status=${res.statusCode} body=$body');

      if (res.statusCode != 200) return null;

      final data = jsonDecode(body) as Map<String, dynamic>;
      final tokenObj = data['token'];
      if (tokenObj == null) return null; // 아직 발급 전

      final appId = (tokenObj['appId'] ?? '').toString();
      final channel = (tokenObj['channel'] ?? widget.agoraChannel).toString();
      final token = (tokenObj['token'] ?? '').toString();

      final uidDynamic = tokenObj['uid'];
      final uid = (uidDynamic is int) ? uidDynamic : (int.tryParse('$uidDynamic') ?? 0);

      if (appId.isEmpty || channel.isEmpty || token.isEmpty) return null;

      return _TokenInfo(appId: appId, channel: channel, uid: uid, token: token);
    } catch (e) {
      debugPrint('📌 [status-with-token] error=$e');
      return null;
    }
  }

  Future<void> _joinAgora(_TokenInfo info) async {
    setState(() {
      _loading = true;
      _status = 'Agora 입장 중...';
    });

    _localUid = info.uid;

    final engine = createAgoraRtcEngine();
    _engine = engine;

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (!mounted) return;
          setState(() {
            _joined = true;
            _loading = false;
            _status = '통화 중';
          });
        },

        onConnectionStateChanged: (
            RtcConnection connection,
            ConnectionStateType state,
            ConnectionChangedReasonType reason,
            ) {
          if (!mounted) return;

          if (state == ConnectionStateType.connectionStateConnected) {
            setState(() {
              _joined = true;
              _loading = false;
              _status = '통화 중';
            });
          }

          _append('[agora] connState=$state reason=$reason');
        },

        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (!mounted) return;
          setState(() => _remoteUid = remoteUid);
        },

        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          if (!mounted) return;
          setState(() => _remoteUid = null);
        },

        onError: (ErrorCodeType err, String msg) {
          _append('[agora][ERR] $err $msg');
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

    // ✅ 핵심: 여기서 '채널 연결 중...'으로 덮어쓰면 안 됨
    // 대신, 잠깐 기다렸다가 아직 joined가 아니면 그때만 표시(선택)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (!_joined) {
        setState(() {
          _status = '채널 연결 중...';
          _loading = true;
        });
      }
    });
  }

  Future<void> _leaveAgora() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
    } catch (_) {}
    _engine = null;
  }

  Future<void> _toggleMute() async {
    if (_engine == null) return;
    _muted = !_muted;
    await _engine!.muteLocalAudioStream(_muted);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _hangup() async {
    if (_ending) return;
    _ending = true;

    // 1) Agora leave
    await _leaveAgora();

    // 2) 서버 end (JWT 포함)
    try {
      final jwt = await _tokenStorage.readToken();
      final res = await http.post(
        _endUri(widget.voiceSessionId),
        headers: {
          'Content-Type': 'application/json',
          if (jwt != null && jwt.isNotEmpty) 'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({'reason': 'CUSTOMER_HANGUP'}),
      );

      final body = utf8.decode(res.bodyBytes);
      debugPrint('📌 [end] status=${res.statusCode} body=$body');
    } catch (e) {
      debugPrint('📌 [end] error=$e');
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<bool> _confirmExit() async {
    if (_ending) return true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('통화를 종료할까요?'),
        content: const Text('나가면 통화가 종료됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('종료')),
        ],
      ),
    );

    if (ok == true) {
      await _hangup();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('전화 통화'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _confirmExit();
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_status, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('voiceSessionId: ${widget.voiceSessionId}'),
              Text('channel: ${widget.agoraChannel}'),
              const SizedBox(height: 12),
              Text('localUid=$_localUid / remoteUid=${_remoteUid ?? "-"}'),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_joined && !_loading) ? _toggleMute : null,
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
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(_log.isEmpty ? '(log empty)' : _log, style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
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
