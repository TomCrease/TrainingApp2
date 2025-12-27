import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../providers/workout_providers.dart';
import '../../database/database.dart';

class TemplateEditorPage extends ConsumerWidget {
  final WorkoutTemplate template;

  const TemplateEditorPage({super.key, required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(templateExercisesProvider(template.id));
    final allExercisesAsync = ref.watch(exercisesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Edit ${template.name}')),
      body: exercisesAsync.when(
        data: (templateExercises) {
          return allExercisesAsync.when(
            data: (allExercises) {
              return ListView.builder(
                itemCount: templateExercises.length,
                itemBuilder: (context, index) {
                  final te = templateExercises[index];
                  final exerciseName = allExercises
                      .firstWhere(
                        (e) => e.id == te.exerciseId,
                        orElse: () => const Exercise(id: 0, name: 'Unknown'),
                      )
                      .name;
                  return ListTile(
                    title: Text(exerciseName),
                    subtitle: Text(
                      '${te.targetSets} sets x ${te.targetReps} reps',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(databaseProvider)
                            .deleteTemplateExercise(te.id);
                      },
                    ),
                    onTap: () => _showEditExerciseInTemplateDialog(
                      context,
                      ref,
                      te,
                      exerciseName,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showAddExerciseToTemplateDialog(context, ref, allExercisesAsync),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditExerciseInTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    TemplateExercise te,
    String exerciseName,
  ) {
    final setsController = TextEditingController(
      text: te.targetSets.toString(),
    );
    final repsController = TextEditingController(
      text: te.targetReps.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $exerciseName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              decoration: const InputDecoration(labelText: 'Sets'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: repsController,
              decoration: const InputDecoration(labelText: 'Reps'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(databaseProvider)
                  .updateTemplateExercise(
                    id: te.id,
                    sets: int.tryParse(setsController.text) ?? te.targetSets,
                    reps: int.tryParse(repsController.text) ?? te.targetReps,
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseToTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Exercise>> allExercisesAsync,
  ) {
    Exercise? selectedExercise;
    final setsController = TextEditingController(text: '3');
    final repsController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Exercise to Template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              allExercisesAsync.when(
                data: (exercises) => DropdownButton<Exercise>(
                  value: selectedExercise,
                  hint: const Text('Select Exercise'),
                  items: exercises
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => selectedExercise = val),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (err, stack) => Text('Error: $err'),
              ),
              TextField(
                controller: setsController,
                decoration: const InputDecoration(labelText: 'Sets'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: repsController,
                decoration: const InputDecoration(labelText: 'Reps'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (selectedExercise != null) {
                  ref
                      .read(databaseProvider)
                      .addExerciseToTemplate(
                        templateId: template.id,
                        exerciseId: selectedExercise!.id,
                        sets: int.tryParse(setsController.text) ?? 0,
                        reps: int.tryParse(repsController.text) ?? 0,
                        orderIndex: 0, // Simplified for now
                      );
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
