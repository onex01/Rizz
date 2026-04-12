import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/logger/app_logger.dart';

class LogEntry {
  final String timestamp;
  final String level;
  final String summary;
  final String? details;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.summary,
    this.details,
  });
}

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<LogEntry> _logs = [];
  bool _isLoading = true;
  final _logger = GetIt.I<AppLogger>();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      final file = _logger.getLogFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        final lines = content.split('\n');
        final List<LogEntry> entries = [];
        LogEntry? currentEntry;

        for (var line in lines) {
          if (line.startsWith('[') && line.contains(' - ')) {
            if (currentEntry != null) entries.add(currentEntry);
            final parts = line.split(' - ');
            final header = parts[0];
            final level = header.substring(1, header.indexOf(']'));
            final timestamp = header.substring(header.indexOf(']') + 2);
            final summary = parts.sublist(1).join(' - ').trim();
            currentEntry = LogEntry(
              timestamp: timestamp,
              level: level,
              summary: summary,
            );
          } else if (line.startsWith('  Details: ') && currentEntry != null) {
            currentEntry = LogEntry(
              timestamp: currentEntry.timestamp,
              level: currentEntry.level,
              summary: currentEntry.summary,
              details: line.substring(10),
            );
          }
        }
        if (currentEntry != null) entries.add(currentEntry);

        setState(() {
          _logs = entries;
          _isLoading = false;
        });
      } else {
        setState(() {
          _logs = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _logs = [
          LogEntry(
            timestamp: DateTime.now().toIso8601String(),
            level: 'ERROR',
            summary: 'Ошибка загрузки лога: $e',
          )
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _copyAllLogs() async {
    final buffer = StringBuffer();
    for (var log in _logs) {
      buffer.writeln('[${log.level}] ${log.timestamp} - ${log.summary}');
      if (log.details != null) {
        buffer.writeln('  Details: ${log.details}');
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Все логи скопированы в буфер обмена')),
      );
    }
  }

  Future<void> _saveLogsToFile() async {
    try {
      // Сохраняем в Download/Rizz/
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download/Rizz');
      } else {
        downloadsDir = await getDownloadsDirectory();
      }
      if (downloadsDir == null) {
        _showError('Не удалось получить доступ к папке загрузок');
        return;
      }
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final buffer = StringBuffer();
      for (var log in _logs) {
        buffer.writeln('[${log.level}] ${log.timestamp} - ${log.summary}');
        if (log.details != null) {
          buffer.writeln('  Details: ${log.details}');
        }
      }
      final file = File('${downloadsDir.path}/rizz_logs_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(buffer.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Логи сохранены: ${file.path}')),
        );
      }
    } catch (e) {
      _showError('Ошибка сохранения: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи приложения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyAllLogs,
            tooltip: 'Копировать все',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _saveLogsToFile,
            tooltip: 'Сохранить в файл',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('Логи отсутствуют'))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final color = _getLevelColor(log.level);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: isLight ? Colors.white : Colors.grey[900],
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Text(log.level[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          log.summary,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          log.timestamp,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        children: [
                          if (log.details != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              color: isLight ? Colors.grey[100] : Colors.grey[800],
                              child: SelectableText(
                                log.details!,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                            ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                    text: '[${log.level}] ${log.timestamp} - ${log.summary}\n${log.details ?? ""}',
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Скопировано')),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Копировать'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'ERROR':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      case 'INFO':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}