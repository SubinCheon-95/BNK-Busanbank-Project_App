import 'dart:math';
import 'package:flutter/material.dart';

import 'package:tkbank/config/api_config.dart';

import 'voice_call_api.dart';
import 'voice_call_controller.dart';
import 'voice_websocket_service.dart';
import 'agora_call_screen.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final VoiceCallController controller;

  String _log = '';
  bool _navigatedToAgora = false; // ✅ Agora 중복 이동 방지

  @override
  void initState() {
    super.initState();

    controller = VoiceCallController(
      api: VoiceCallApi(baseUrl: ApiConfig.baseUrl),
      ws: VoiceWebSocketService(),
    )
      ..addListener(() => setState(() {}))
      ..onAccepted = _moveToAgora
      ..onEnded = _onEndedByServer;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // =========================
  // Util
  // =========================
  void _append(String s) {
    setState(() => _log = '$_log\n$s');
  }

  String _newSessionId() {
    final r = Random().nextInt(900000) + 100000;
    return 'TEST_SESSION_APP_$r';
  }

  // =========================
  // Agora 이동 (1회만)
  // =========================
  Future<void> _moveToAgora() async {
    if (_navigatedToAgora) return;
    _navigatedToAgora = true;

    final sid = controller.sessionId;
    final channel = controller.agoraChannel;

    _append('[VOICE] ACCEPTED → Agora 이동 (sid=$sid, channel=$channel)');

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgoraCallScreen(
          voiceSessionId: sid,
          agoraChannel: channel,
          consultantId: controller.consultantId,
        ),
      ),
    );

    // Agora 화면 종료 후 복귀
    _append('[UI] back from Agora');
    _navigatedToAgora = false;
  }

  // =========================
  // 서버에서 VOICE_ENDED 수신
  // =========================
  void _onEndedByServer() {
    _append('[VOICE] 서버에서 종료 이벤트 수신');
    _navigatedToAgora = false;
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    return Scaffold(
      appBar: AppBar(title: const Text('전화 상담 (고객)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatusCard(
              state: state,
              sessionId: controller.sessionId,
              wsOn: controller.ws.isConnected,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // =========================
                // 전화 요청
                // =========================
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: const Text('전화 요청'),
                    onPressed: (state == UiVoiceCallState.idle)
                        ? () async {
                            final sid = _newSessionId();
                            _append('[REQ] enqueue $sid');

                            await controller.requestCall(
                              newSessionId: sid,
                            );

                            _append('[OK] WAITING...');
                            controller.attachWs(
                              baseWs: ApiConfig.wsBase,
                            );
                          }
                        : null,
                  ),
                ),

                const SizedBox(width: 10),

                // =========================
                // 종료 (Agora 들어가기 전까지만)
                // =========================
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.call_end),
                    label: const Text('종료'),
                    onPressed: (controller.sessionId.isNotEmpty &&
                            state != UiVoiceCallState.accepted)
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

            // =========================
            // Log
            // =========================
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

            if (state == UiVoiceCallState.error) ...[
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

// =========================
// 상태 카드
// =========================
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
        label = '요청 중';
        icon = Icons.sync;
        break;
      case UiVoiceCallState.waiting:
        label = '상담사 연결 대기';
        icon = Icons.support_agent;
        break;
      case UiVoiceCallState.accepted:
        label = '연결됨 (통화 화면 이동)';
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
                Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
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
