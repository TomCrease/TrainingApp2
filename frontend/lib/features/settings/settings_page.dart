import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/database_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export History to CSV'),
            subtitle: const Text('Save your workout data to a CSV file'),
            onTap: () => _exportHistory(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import History from CSV'),
            subtitle: const Text('Load workout data from a CSV file'),
            onTap: () => _importHistory(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportHistory(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(databaseProvider);
      final data = await db.getExportData();

      if (data.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No history to export')));
        }
        return;
      }

      final List<List<dynamic>> rows = [];
      // Add header
      rows.add(['date', 'workoutName', 'exercise', 'weight', 'reps']);

      for (var item in data) {
        rows.add([
          item['date'],
          item['workoutName'],
          item['exercise'],
          item['weight'],
          item['reps'],
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/workout_history.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(path)], text: 'My Workout History');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importHistory(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvString,
      );

      if (csvData.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('CSV file is empty')));
        }
        return;
      }

      await ref.read(databaseProvider).importWorkoutData(csvData);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Import successful')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}
