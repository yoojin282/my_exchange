import 'dart:async';
import 'dart:ui';

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer? _timer;

  Debouncer({required this.milliseconds, required this.action});

  void dispose() {
    _timer?.cancel();
  }

  void run() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void cancel() {
    _timer?.cancel();
  }
}
