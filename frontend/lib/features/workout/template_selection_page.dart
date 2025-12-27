import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../../providers/workout_providers.dart';
import 'active_workout_page.dart';

class TemplateSelectionPage extends ConsumerWidget {
  const TemplateSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Start Workout')),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return const Center(
              child: Text('No templates found. Create one first!'),
            );
          }
          return ListView.builder(
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(template.name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () async {
                    // Start the session
                    final sessionId = await ref
                        .read(databaseProvider)
                        .startSession(template.id);

                    if (context.mounted) {
                      // Navigate to active workout
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ActiveWorkoutPage(sessionId: sessionId),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
