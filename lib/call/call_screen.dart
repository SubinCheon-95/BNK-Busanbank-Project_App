import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tkbank/call/agora_call_screen.dart';
import 'package:tkbank/config/api_config.dart';

import 'voice_call_api.dart';
import 'voice_call_controller.dart';
import 'voice_websocket_service.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final VoiceCallController controller;

  String _log = '';

  // ✅ 에뮬레이터면 10.0.2.2, 실기기면 PC IP
  static const String baseUrl = 'http://10.0.2.2:8080/busanbank';
  final String baseUrl = ApiConfig.baseUrl;
  final String baseWs  = ApiConfig.wsBase;

  @override
  void initState() {
    super.initState();

    controller = VoiceCallController(
      api: VoiceCallApi(baseUrl: ApiConfig.baseUrl),
      ws: VoiceWebSocketService(),
    )
      ..addListener(() => setState(() {}))
      ..onAccepted = _goAgora
      ..onEnded = () => _append('[VOICE] ended pushed')
    ;
  }

  String _newSessionId() {
    final r = Random().nextInt(900000) + 100000;
    return 'TEST_SESSION_APP_$r';
  }

  void _append(String s) {
    setState(() => _log = '$_log\n$s');
  }

  void _goAgora() {
    final ch = controller.agoraChannel;
    _append('[VOICE] ACCEPTED -> move Agora (channel=$ch)');

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgoraCallScreen(
          voiceSessionId: controller.sessionId,
          agoraChannel: controller.agoraChannel,
          consultantId: controller.consultantId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('전화 상담 (고객)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatusCard(
              state: s,
              sessionId: controller.sessionId,
              wsOn: controller.ws.isConnected,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text('전화 요청'),
                    onPressed: (s == UiVoiceCallState.idle)
                        ? () async {
                      final sid = _newSessionId();
                      _append('[REQ] enqueue $sid');

                      await controller.requestCall(newSessionId: sid);
                      _append('[OK] WAITING... (WS connect)');

                      // ✅ enqueue 성공 후 고객 WS 연결
                      controller.attachWs(baseWs: ApiConfig.wsBase);
                    }
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.call_end),
                    label: const Text('종료'),
                    onPressed: controller.sessionId.isNotEmpty
                        ? () async {
                      _append('[END] ${controller.sessionId}');
                      await controller.endCall();
                      _append('[OK] end requested');
                    }
                        : null,
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
                  child: Text(
                    _log.isEmpty ? '(log empty)' : _log,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),

            if (s == UiVoiceCallState.error) ...[
              const SizedBox(height: 8),
              Text(
                'ERROR: ${controller.errorMsg}',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final UiVoiceCallState state;
  final String sessionId;
  final bool wsOn;

  const _StatusCard({
    required this.state,
    required this.sessionId,
    required this.wsOn,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    IconData icon;

    switch (state) {
      case UiVoiceCallState.idle:
        label = '대기';
        icon = Icons.hourglass_empty;
        break;
      case UiVoiceCallState.requesting:
        label = '요청 중...';
        icon = Icons.sync;
        break;
      case UiVoiceCallState.waiting:
        label = '상담사 연결 대기';
        icon = Icons.support_agent;
        break;
      case UiVoiceCallState.accepted:
        label = '연결됨';
        icon = Icons.check_circle;
        break;
      case UiVoiceCallState.ended:
        label = '종료됨';
        icon = Icons.call_end;
        break;
      case UiVoiceCallState.error:
        label = '오류';
        icon = Icons.error;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('sessionId: ${sessionId.isEmpty ? "-" : sessionId}'),
              ],
            ),
          ),
          Text('WS: ${wsOn ? "ON" : "OFF"}'),
        ],
      ),
    );
  }
}

/// ✅ 실제 Agora Flutter 화면이 있으면 이 Stub 대신 그 화면으로 이동만 바꾸면 됩니다.
class AgoraStubScreen extends StatelessWidget {
  final String voiceSessionId;
  final String agoraChannel;
  final String consultantId;

  const AgoraStubScreen({
    super.key,
    required this.voiceSessionId,
    required this.agoraChannel,
    required this.consultantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agora (자동 이동됨)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'VOICE_ACCEPTED 수신으로 자동 이동됨\n\n'
              'voiceSessionId=$voiceSessionId\n'
              'agoraChannel=$agoraChannel\n'
              'consultantId=$consultantId\n\n'
              '※ 여기서 실제 Agora join 화면으로 교체하시면 됩니다.',
        ),
      ),
    );
  }
}
