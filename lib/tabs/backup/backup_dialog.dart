import 'package:flutter/material.dart';
import 'package:records_keeper/database_helper.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class BackupDialog extends StatefulWidget {
  const BackupDialog({super.key});

  @override
  State<BackupDialog> createState() => _BackupDialogState();
}

class _BackupDialogState extends State<BackupDialog> {
  bool _loading = false;

  Future<void> _exportData(BuildContext context) async {
    setState(() => _loading = true);
    try {
      final data = await DatabaseHelper.instance.exportDatabaseToJson();
      final jsonStr = jsonEncode(data);
      final directory = await getDownloadsDirectory();
      final file = File('${directory!.path}/records_keeper_backup.json');
      await file.writeAsString(jsonStr);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported to Downloads folder.')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: \\${e.toString()}')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _importData(BuildContext context) async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonStr = await file.readAsString();
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final backupMeta = data['backup_meta'] as Map<String, dynamic>?;
        final currentSchema = DatabaseHelper.schemaVersion;
        final backupSchema = backupMeta != null ? backupMeta['schema_version'] : null;
        final versionMismatch = backupSchema != null && backupSchema != currentSchema;
        bool proceed = true;
        if (versionMismatch) {
          proceed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Version Mismatch'),
                  content: Text('Backup schema version: \\$backupSchema\nCurrent schema version: \\$currentSchema\n\nImporting may cause data loss or errors. Proceed?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Proceed')),
                  ],
                ),
              ) ?? false;
        } else {
          proceed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Import'),
                  content: const Text('Importing will overwrite all current data. Continue?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Import')),
                  ],
                ),
              ) ?? false;
        }
        if (!proceed) {
          setState(() => _loading = false);
          return;
        }
        await DatabaseHelper.instance.importDatabaseFromJson(data);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup imported successfully.')),
          );
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: \\${e.toString()}')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Backup & Restore'),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: _loading
          ? const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                  onPressed: () => _exportData(context),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Import'),
                  onPressed: () => _importData(context),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(160, 48)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Export will save all your data as a JSON file.\nImport will restore data from a previously exported JSON file.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
    );
  }
} 