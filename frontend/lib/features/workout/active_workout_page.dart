import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../providers/workout_providers.dart';
import '../../database/database.dart';

class ActiveWorkoutPage extends ConsumerWidget {
  final int sessionId;

  const ActiveWorkoutPage({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionSetsAsync = ref.watch(activeSessionSetsProvider(sessionId));
    final exercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              await ref.read(databaseProvider).finishSession(sessionId);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: sessionSetsAsync.when(
        data: (sets) {
          return exercisesAsync.when(
            data: (exercises) {
              final groupedSets = <int, List<SessionSet>>{};
              for (final s in sets) {
                groupedSets.putIfAbsent(s.exerciseId, () => []).add(s);
              }

              return ListView.builder(
                itemCount: groupedSets.keys.length,
                itemBuilder: (context, index) {
                  final exerciseId = groupedSets.keys.elementAt(index);
                  final exerciseSets = groupedSets[exerciseId]!;
                  final exercise = exercises.firstWhere(
                    (e) => e.id == exerciseId,
                    orElse: () => const Exercise(id: 0, name: 'Unknown'),
                  );

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        ...exerciseSets.map((s) => SetRow(sessionSet: s)),
                        TextButton(
                          onPressed: () => ref
                              .read(databaseProvider)
                              .addSetToSession(
                                sessionId,
                                exerciseId,
                                exerciseSets.isNotEmpty
                                    ? exerciseSets.last.reps
                                    : 10,
                                exerciseSets.isNotEmpty
                                    ? exerciseSets.last.weight
                                    : 0,
                              ),
                          child: const Text('Add Set'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class SetRow extends ConsumerStatefulWidget {
  final SessionSet sessionSet;
  const SetRow({super.key, required this.sessionSet});

  @override
  ConsumerState<SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.sessionSet.weight.toString(),
    );
    _repsController = TextEditingController(
      text: widget.sessionSet.reps.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update controller text if the value from upstream has changed
    // AND it's not currently being edited (to avoid overwriting user input)
    if (oldWidget.sessionSet.weight != widget.sessionSet.weight &&
        double.tryParse(_weightController.text) != widget.sessionSet.weight) {
      _weightController.text = widget.sessionSet.weight.toString();
    }
    if (oldWidget.sessionSet.reps != widget.sessionSet.reps &&
        int.tryParse(_repsController.text) != widget.sessionSet.reps) {
      _repsController.text = widget.sessionSet.reps.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          Checkbox(
            value: widget.sessionSet.isCompleted,
            onChanged: (val) => ref
                .read(databaseProvider)
                .updateSet(widget.sessionSet.id, isCompleted: val),
          ),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                ref
                    .read(databaseProvider)
                    .updateSet(
                      widget.sessionSet.id,
                      weight: double.tryParse(val),
                    );
              },
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _repsController,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                ref
                    .read(databaseProvider)
                    .updateSet(widget.sessionSet.id, reps: int.tryParse(val));
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () =>
                ref.read(databaseProvider).deleteSet(widget.sessionSet.id),
          ),
        ],
      ),
    );
  }
}
