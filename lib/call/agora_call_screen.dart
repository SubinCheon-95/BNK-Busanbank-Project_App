import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:tkbank/services/token_storage_service.dart';


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

  // ✅ 당신 서버 컨트롤러 기준: POST /api/call/{sid}/status-with-token
  Uri _statusUri(String sid) => Uri.parse('$baseUrl/api/call/$sid/status-with-token');

  // ✅ 고객 종료 API (제가 이전에 안내한 형태로 맞춤)
  // POST /api/call/voice/{sid}/end
  Uri _endUri(String sid) => Uri.parse('$baseUrl/api/call/voice/$sid/end');

  final TokenStorageService _tokenStorage = TokenStorageService();

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
    // 1) 마이크 권한
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() {
        _loading = false;
        _status = '마이크 권한 필요';
      });
      return;
    }

    setState(() {
      _loading = true;
      _status = '토큰 대기 중...';
    });

    // 2) 토큰 폴링 (30초)
    int tick = 0;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      tick++;

      final info = await _fetchTokenOnce();
      if (info != null) {
        t.cancel();
        await _joinAgora(info);
        return;
      }

      // ✅ 401/403 같은 경우는 계속 폴링하면 의미 없어서 중단하는 게 좋음
      // _fetchTokenOnce 내부에서 로그를 남기니, 여기서는 시간만 체크
      if (tick >= 30) {
        t.cancel();
        if (!mounted) return;
        setState(() {
          _loading = false;
          _status = '토큰 대기 시간 초과 (서버에서 token이 내려오지 않음)';
        });
      }
    });
  }

  /// ✅ status-with-token 한 번 조회
  Future<_TokenInfo?> _fetchTokenOnce() async {
    try {
      final jwt = await _tokenStorage.readToken();
      if (jwt == null || jwt.isEmpty) {
        _append('[token] JWT 없음(로그인 필요)');
        return null;
      }

      final res = await http.post(
        _statusUri(widget.voiceSessionId),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt', // ✅ 핵심: 인증 붙이기
        },
        body: jsonEncode({'role': 'CUSTOMER'}),
      );

      // ✅ 응답 코드 로그 남기기 (원인 파악용)
      if (res.statusCode != 200) {
        _append('[status] http=${res.statusCode} body=${res.body}');
        // 401/403이면 폴링해도 계속 실패 -> 바로 종료
        if (res.statusCode == 401 || res.statusCode == 403) {
          if (mounted) {
            setState(() {
              _loading = false;
              _status = '인증 실패(로그인 토큰 확인 필요)';
            });
          }
          _pollTimer?.cancel();
        }
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(res.body);

      // ✅ 서버가 token을 "token" 또는 "callToken" 등으로 내려줄 수 있어 방어적으로 처리
      final dynamic tokenObj = data['token'] ?? data['callToken'] ?? data['agoraToken'];

      if (tokenObj == null) {
        // callStatus 힌트가 있으면 UI 반영
        final cs = (data['callStatus'] ?? '').toString();
        if (cs.isNotEmpty) _append('[status] callStatus=$cs');

        return null;
      }

      final String appId = (tokenObj['appId'] ?? '').toString();
      final String channel =
      (tokenObj['channel'] ?? data['agoraChannel'] ?? widget.agoraChannel).toString();
      final dynamic uidRaw = tokenObj['uid'];
      final String token = (tokenObj['token'] ?? '').toString();

      int uid = 0;
      if (uidRaw is int) uid = uidRaw;
      if (uidRaw is String) uid = int.tryParse(uidRaw) ?? 0;

      if (appId.isEmpty || channel.isEmpty || token.isEmpty) {
        _append('[token] invalid payload: $tokenObj');
        return null;
      }

      return _TokenInfo(appId: appId, channel: channel, uid: uid, token: token);
    } catch (e) {
      _append('[status] parse error: $e');
      return null;
    }
  }

  Future<void> _joinAgora(_TokenInfo info) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _status = 'Agora 초기화/입장 중...';
    });

    final engine = createAgoraRtcEngine();
    _engine = engine;
    _localUid = info.uid;

    // 1) initialize 먼저
    await engine.initialize(RtcEngineContext(appId: info.appId));

    // 2) 그 다음 이벤트 등록 (중요)
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection c, int elapsed) {
          if (!mounted) return;
          setState(() {
            _joined = true;
            _loading = false;
            _status = '채널 입장 완료(통화 중)';
          });
          _append('[agora] join success channel=${c.channelId} uid=${c.localUid}');
        },
        onUserJoined: (RtcConnection c, int uid, int elapsed) {
          if (!mounted) return;
          setState(() => _remoteUid = uid);
          _append('[agora] remote joined uid=$uid');
        },
        onUserOffline: (RtcConnection c, int uid, UserOfflineReasonType reason) {
          if (!mounted) return;
          setState(() => _remoteUid = null);
          _append('[agora] remote offline uid=$uid reason=$reason');
        },
        onError: (ErrorCodeType err, String msg) {
          _append('[agora][ERR] $err $msg');
        },
      ),
    );

    // 3) 오디오/역할 설정
    await engine.enableAudio();
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // 4) join
    await engine.joinChannel(
      token: info.token,
      channelId: info.channel,
      uid: info.uid,
      options: const ChannelMediaOptions(),
    );

    if (!mounted) return;
    setState(() {
      _status = '입장 요청 완료... (상대 대기)';
    });
  }

  Future<void> _leaveAgora() async {
    try {
      await _engine?.leaveChannel();
      await _engine?.release();
      _engine = null;
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

    // ✅ end도 JWT 필요할 가능성이 높아서 Authorization 포함 권장
    try {
      final jwt = await _tokenStorage.readToken();
      await http.post(
        _endUri(widget.voiceSessionId),
        headers: jwt == null || jwt.isEmpty
            ? null
            : {'Authorization': 'Bearer $jwt'},
      );
    } catch (_) {}

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
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _log.isEmpty ? '(log empty)' : _log,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
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
