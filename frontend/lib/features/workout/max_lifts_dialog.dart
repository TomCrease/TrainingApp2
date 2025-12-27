import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../providers/workout_providers.dart';
import '../../database/database.dart';

class MaxLiftsDialog extends ConsumerStatefulWidget {
  const MaxLiftsDialog({super.key});

  @override
  ConsumerState<MaxLiftsDialog> createState() => _MaxLiftsDialogState();
}

class _MaxLiftsDialogState extends ConsumerState<MaxLiftsDialog> {
  int? _selectedExerciseId;
  final TextEditingController _repsController = TextEditingController(
    text: '1',
  );
  double? _maxWeight;
  bool _searching = false;
  bool _searched = false;

  @override
  void dispose() {
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_selectedExerciseId == null) return;

    final reps = int.tryParse(_repsController.text);
    if (reps == null || reps <= 0) return;

    setState(() {
      _searching = true;
      _searched = false;
    });

    final weight = await ref
        .read(databaseProvider)
        .getMaxWeight(_selectedExerciseId!, reps);

    setState(() {
      _maxWeight = weight;
      _searching = false;
      _searched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return AlertDialog(
      title: const Text('Max Lifts Search'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            exercisesAsync.when(
              data: (exercises) => DropdownButtonFormField<int>(
                value: _selectedExerciseId,
                decoration: const InputDecoration(labelText: 'Exercise'),
                items: exercises
                    .map(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.name)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedExerciseId = val),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Text('Error loading exercises: $err'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repsController,
              decoration: const InputDecoration(
                labelText: 'Reps',
                helperText: 'Search for personal best at this rep count',
              ),
              keyboardType: TextInputType.number,
            ),
            if (_searched) ...[
              const SizedBox(height: 24),
              if (_maxWeight != null)
                Text(
                  'Personal Best: ${_maxWeight}kg',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text('No records found for this exercise and reps.'),
            ],
            if (_searching)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _selectedExerciseId != null && !_searching
              ? _search
              : null,
          child: const Text('Search'),
        ),
      ],
    );
  }
}
