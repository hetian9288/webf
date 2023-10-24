
import 'dart:async';

Future<void> sleep(Duration duration) {
  Completer completer = Completer();
  Timer(duration, () async {
    completer.complete();
  });
  return completer.future;
}
