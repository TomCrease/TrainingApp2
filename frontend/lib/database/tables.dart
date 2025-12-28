import 'package:drift/drift.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class WorkoutTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class TemplateExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(WorkoutTemplates, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get targetSets => integer()();
  IntColumn get targetReps => integer()();
}

class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId =>
      integer().nullable().references(WorkoutTemplates, #id)();
  TextColumn get workoutName => text().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
}

class SessionSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WorkoutSessions, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  RealColumn get weight => real()();
  IntColumn get reps => integer()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get orderIndex => integer()();
}
