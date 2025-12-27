import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(databaseProvider).watchExercises();
});

final templatesProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  return ref.watch(databaseProvider).watchTemplates();
});

final templateExercisesProvider =
    StreamProvider.family<List<TemplateExercise>, int>((ref, templateId) {
      return ref.watch(databaseProvider).watchTemplateExercises(templateId);
    });

final activeSessionSetsProvider = StreamProvider.family<List<SessionSet>, int>((
  ref,
  sessionId,
) {
  return ref.watch(databaseProvider).watchSessionSets(sessionId);
});

final sessionsProvider = StreamProvider<List<WorkoutSession>>((ref) {
  return ref.watch(databaseProvider).watchSessions();
});

final sessionsWithDetailsProvider = StreamProvider<List<SessionWithTemplate>>((
  ref,
) {
  return ref.watch(databaseProvider).watchSessionsWithDetails();
});
