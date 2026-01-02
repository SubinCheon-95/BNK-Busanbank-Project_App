import 'dart:async';

class IdleManager {
  IdleManager._();
  static final IdleManager instance = IdleManager._();

  Timer? _timer;
  Duration _timeout = const Duration(minutes: 20);

  bool _enabled = false;
  bool _handled = false;

  Future<void> Function()? _onTimeout;

  void configure({
    Duration? timeout,
    required Future<void> Function() onTimeout,
  }) {
    if (timeout != null) _timeout = timeout;
    _onTimeout = onTimeout;
  }

  void enable() {
    _enabled = true;
    _handled = false;
    _reset();
  }

  void disable() {
    _enabled = false;
    _timer?.cancel();
    _timer = null;
  }

  void activity() {
    if (!_enabled) return;
    _reset();
  }

  void _reset() {
    _timer?.cancel();
    _timer = Timer(_timeout, () async {
      if (!_enabled || _handled) return;
      _handled = true;
      final cb = _onTimeout;
      if (cb != null) {
        await cb();
      }
    });
  }
}
