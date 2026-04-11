import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/logger/app_logger.dart';

class LogViewerScreen extends StatefulWidget {
  const LogViewerScreen({super.key});

  @override
  State<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends State<LogViewerScreen> {
  List<String> _logLines = [];
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
        setState(() {
          _logLines = content.split('\n');
          _isLoading = false;
        });
      } else {
        setState(() {
          _logLines = ['Лог-файл не найден'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _logLines = ['Ошибка загрузки лога: $e'];
        _isLoading = false;
      });
    }
  }

  Future<void> _copyLogsToClipboard() async {
    final fullLog = _logLines.join('\n');
    await Clipboard.setData(ClipboardData(text: fullLog));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Логи скопированы в буфер обмена')),
      );
    }
  }

  Future<void> _saveLogsToFile() async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        _showError('Не удалось получить доступ к папке загрузок');
        return;
      }
      final file = File('${downloadsDir.path}/rizz_logs_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(_logLines.join('\n'));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи приложения'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'Копировать все логи',
          ),
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _saveLogsToFile,
            tooltip: 'Сохранить в файл',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _logLines.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SelectableText(
                  _logLines[index],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
    );
  }
}