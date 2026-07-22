part of '../local_training_repository.dart';

class _LocalWorkoutRecordStore
    with _WorkoutSessionWriteMixin, _WorkoutQueryMixin, _WorkoutEditMixin {
  _LocalWorkoutRecordStore(this.database, this._syncQueue);

  @override
  final LocalTrainingDatabase database;
  @override
  final LocalSyncQueueRepository _syncQueue;
}
