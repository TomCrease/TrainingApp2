import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/workout_providers.dart';
import '../../providers/database_provider.dart';
import '../../database/database.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsWithDetailsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: sessionsAsync.when(
        data: (sessions) {
          final completedSessions = sessions
              .where((s) => s.session.endTime != null)
              .toList()
              .reversed
              .toList();

          if (completedSessions.isEmpty) {
            return const Center(child: Text('No workout history yet.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: completedSessions.length,
                  itemBuilder: (context, index) {
                    final item = completedSessions[index];
                    final session = item.session;
                    final displayName =
                        (session.workoutName != null &&
                            session.workoutName!.isNotEmpty)
                        ? session.workoutName!
                        : (item.template?.name ?? 'Workout');

                    return Dismissible(
                      key: Key(session.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Confirm"),
                              content: const Text(
                                "Are you sure you want to delete this workout?",
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      onDismissed: (direction) {
                        ref.read(databaseProvider).deleteSession(session.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Workout deleted')),
                        );
                      },
                      child: ListTile(
                        title: Text(
                          '$displayName on ${session.startTime.toString().split('.')[0].split(' ')[0]}',
                        ),
                        subtitle: Text(
                          'Duration: ${session.endTime!.difference(session.startTime).inMinutes} mins',
                        ),
                        onTap: () =>
                            _showSessionDetails(context, ref, session.id),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => _showDeleteAllConfirmation(context, ref),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete all history'),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _showDeleteAllConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    bool? firstConfirm = await _showConfirmDialog(
      context,
      "Are you sure you want to delete all history? (1/3)",
    );
    if (firstConfirm != true) return;

    if (!context.mounted) return;
    bool? secondConfirm = await _showConfirmDialog(
      context,
      "Are you REALLY sure? This cannot be undone. (2/3)",
    );
    if (secondConfirm != true) return;

    if (!context.mounted) return;
    bool? thirdConfirm = await _showConfirmDialog(
      context,
      "LAST WARNING: Delete EVERYTHING? (3/3)",
    );
    if (thirdConfirm == true) {
      await ref.read(databaseProvider).deleteAllHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All history deleted')));
      }
    }
  }

  Future<bool?> _showConfirmDialog(BuildContext context, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete All History"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(BuildContext context, WidgetRef ref, int sessionId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, controller) => SessionDetailsView(
          sessionId: sessionId,
          scrollController: controller,
        ),
      ),
    );
  }
}

class SessionDetailsView extends ConsumerWidget {
  final int sessionId;
  final ScrollController scrollController;
  const SessionDetailsView({
    super.key,
    required this.sessionId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(activeSessionSetsProvider(sessionId));
    final exercisesAsync = ref.watch(exercisesProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: setsAsync.when(
        data: (sets) => exercisesAsync.when(
          data: (exercises) {
            final groupedSets = <int, List<SessionSet>>{};
            for (final s in sets) {
              groupedSets.putIfAbsent(s.exerciseId, () => []).add(s);
            }
            return ListView(
              controller: scrollController,
              children: groupedSets.entries.map((entry) {
                final exerciseName = exercises
                    .firstWhere(
                      (e) => e.id == entry.key,
                      orElse: () => const Exercise(id: 0, name: 'Unknown'),
                    )
                    .name;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exerciseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    ...entry.value.map(
                      (s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('${s.weight ?? 0}kg x ${s.reps ?? 0} reps'),
                      ),
                    ),
                    const Divider(),
                  ],
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error: $err'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Text('Error: $err'),
      ),
    );
  }
}
