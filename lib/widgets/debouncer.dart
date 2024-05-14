import 'dart:async';
import 'dart:ui';

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer? _timer;

  Debouncer({required this.milliseconds, required this.action});

  void dispose() {
    if (_timer != null) {
      _timer?.cancel();
    }
  }

  void run() {
    if (_timer != null) {
      _timer?.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
