import 'dart:math';
import 'package:flutter/material.dart';
import 'voice_call_api.dart';
import 'voice_call_controller.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late final VoiceCallController controller;

  String _log = '';

  // ✅ 에뮬레이터면 10.0.2.2, 실기기면 PC IP로 바꾸세요.
  static const String baseUrl = 'http://10.0.2.2:8080/busanbank';

  @override
  void initState() {
    super.initState();
    controller = VoiceCallController(api: VoiceCallApi(baseUrl: baseUrl))
      ..addListener(() => setState(() {}));
  }

  String _newSessionId() {
    final r = Random().nextInt(999999);
    return 'TEST_SESSION_APP_${r + 100}';
  }

  void _append(String s) {
    setState(() => _log = '$_log\n$s');
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
      appBar: AppBar(title: const Text('전화상담 (Customer -> Web Agent)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('state: $s'),
            const SizedBox(height: 6),
            Text('sessionId: ${controller.sessionId}'),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final sid = _newSessionId();
                    _append('[REQ] enqueue $sid');
                    await controller.requestCall(newSessionId: sid);
                    _append('[OK] waiting (agent web list should show it)');
                  },
                  child: const Text('1) REQUEST CALL (enqueue)'),
                ),
                ElevatedButton(
                  onPressed: controller.sessionId.isEmpty
                      ? null
                      : () async {
                    _append('[END] ${controller.sessionId}');
                    await controller.endCall();
                    _append('[OK] ended');
                  },
                  child: const Text('END'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // 디버깅용: 서버 waiting list 확인
                    try {
                      final list = await controller.api.waiting();
                      _append('[WAITING] ${list.map((e) => e["sessionId"]).toList()}');
                    } catch (e) {
                      _append('[WAITING] error $e');
                    }
                  },
                  child: const Text('DEBUG: GET waiting'),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text('log:'),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_log.isEmpty ? '(empty)' : _log),
                ),
              ),
            ),

            if (s == UiVoiceCallState.error) ...[
              const SizedBox(height: 10),
              Text('ERROR: ${controller.errorMsg}',
                  style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}
