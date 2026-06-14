import 'package:flutter/foundation.dart';

class RedesignDataRefresh {
  RedesignDataRefresh._();

  static final instance = RedesignDataRefresh._();

  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  final ValueNotifier<int> syncQueueRevision = ValueNotifier<int>(0);

  void notifyRestored() {
    revision.value += 1;
  }

  void notifySyncQueueChanged() {
    syncQueueRevision.value += 1;
  }
}
