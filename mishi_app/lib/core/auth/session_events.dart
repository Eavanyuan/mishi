import 'package:flutter/foundation.dart';

final ValueNotifier<int> authSessionVersionNotifier = ValueNotifier<int>(0);

void notifyAuthSessionInvalidated() {
  authSessionVersionNotifier.value = authSessionVersionNotifier.value + 1;
}
