import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    WorkoutTemplates,
    TemplateExercises,
    WorkoutSessions,
    SessionSets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Exercises
  Stream<List<Exercise>> watchExercises() => select(exercises).watch();
  Future<int> addExercise(String name) =>
      into(exercises).insert(ExercisesCompanion.insert(name: name));
  Future<void> deleteExercise(int id) =>
      (delete(exercises)..where((t) => t.id.equals(id))).go();

  // Templates
  Stream<List<WorkoutTemplate>> watchTemplates() =>
      select(workoutTemplates).watch();
  Future<int> addTemplate(String name) => into(
    workoutTemplates,
  ).insert(WorkoutTemplatesCompanion.insert(name: name));

  Stream<List<TemplateExercise>> watchTemplateExercises(int templateId) {
    return (select(
      templateExercises,
    )..where((t) => t.templateId.equals(templateId))).watch();
  }

  Future<void> addExerciseToTemplate({
    required int templateId,
    required int exerciseId,
    required int sets,
    required int reps,
    required int orderIndex,
  }) {
    return into(templateExercises).insert(
      TemplateExercisesCompanion.insert(
        templateId: templateId,
        exerciseId: exerciseId,
        targetSets: sets,
        targetReps: reps,
        orderIndex: orderIndex,
      ),
    );
  }

  // Sessions
  Future<int> startSession(int? templateId) async {
    final sessionId = await into(workoutSessions).insert(
      WorkoutSessionsCompanion.insert(
        templateId: Value(templateId),
        startTime: DateTime.now(),
      ),
    );

    if (templateId != null) {
      final templates = await (select(
        templateExercises,
      )..where((t) => t.templateId.equals(templateId))).get();
      for (final te in templates) {
        for (int i = 0; i < te.targetSets; i++) {
          await into(sessionSets).insert(
            SessionSetsCompanion.insert(
              sessionId: sessionId,
              exerciseId: te.exerciseId,
              weight: 0,
              reps: te.targetReps,
              orderIndex: i,
            ),
          );
        }
      }
    }
    return sessionId;
  }

  Stream<List<WorkoutSession>> watchSessions() =>
      select(workoutSessions).watch();

  Stream<List<SessionSet>> watchSessionSets(int sessionId) {
    return (select(
      sessionSets,
    )..where((t) => t.sessionId.equals(sessionId))).watch();
  }

  Future<void> updateSet(
    int setId, {
    double? weight,
    int? reps,
    bool? isCompleted,
  }) {
    return (update(sessionSets)..where((t) => t.id.equals(setId))).write(
      SessionSetsCompanion(
        weight: weight != null ? Value(weight) : const Value.absent(),
        reps: reps != null ? Value(reps) : const Value.absent(),
        isCompleted: isCompleted != null
            ? Value(isCompleted)
            : const Value.absent(),
      ),
    );
  }

  Future<void> addSetToSession(
    int sessionId,
    int exerciseId,
    int lastReps,
    double lastWeight,
  ) {
    return into(sessionSets).insert(
      SessionSetsCompanion.insert(
        sessionId: sessionId,
        exerciseId: exerciseId,
        weight: lastWeight,
        reps: lastReps,
        orderIndex: 0, // Should be calculated
      ),
    );
  }

  Future<void> finishSession(int sessionId) {
    return (update(workoutSessions)..where((t) => t.id.equals(sessionId)))
        .write(WorkoutSessionsCompanion(endTime: Value(DateTime.now())));
  }

  Future<void> deleteSet(int setId) {
    return (delete(sessionSets)..where((t) => t.id.equals(setId))).go();
  }

  // History with Templates
  Stream<List<SessionWithTemplate>> watchSessionsWithDetails() {
    final query = select(workoutSessions).join([
      leftOuterJoin(
        workoutTemplates,
        workoutTemplates.id.equalsExp(workoutSessions.templateId),
      ),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return SessionWithTemplate(
          session: row.readTable(workoutSessions),
          template: row.readTableOrNull(workoutTemplates),
        );
      }).toList();
    });
  }

  Future<void> deleteSession(int sessionId) async {
    await (delete(
      sessionSets,
    )..where((t) => t.sessionId.equals(sessionId))).go();
    await (delete(workoutSessions)..where((t) => t.id.equals(sessionId))).go();
  }

  Future<void> deleteTemplate(int templateId) async {
    // Delete associated exercises first
    await (delete(
      templateExercises,
    )..where((t) => t.templateId.equals(templateId))).go();
    // Delete the template
    await (delete(
      workoutTemplates,
    )..where((t) => t.id.equals(templateId))).go();
  }

  Future<double?> getMaxWeight(int exerciseId, int reps) async {
    final result =
        await (select(sessionSets)
              ..where(
                (t) =>
                    t.exerciseId.equals(exerciseId) &
                    t.reps.equals(reps) &
                    t.isCompleted.equals(true),
              )
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.weight, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();
    return result?.weight;
  }
}

class SessionWithTemplate {
  final WorkoutSession session;
  final WorkoutTemplate? template;

  SessionWithTemplate({required this.session, this.template});
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
