import 'package:flutter/material.dart';
import '../../../../shared/services/icon_service.dart';

class IconPickerDialog extends StatefulWidget {
  const IconPickerDialog({super.key});

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  String _currentAlias = 'MainActivityDefault';
  bool _loading = false;

  // Список иконок с отображаемым названием и именем ассета (для картинки)
  final _icons = [
    _IconEntry('MainActivityDefault', 'Стандартная', Icons.phone_android, 'assets/icons/default.png'),
    _IconEntry('MainActivityBlack', 'Чёрная', Icons.dark_mode, 'assets/icons/black.png'),
    _IconEntry('MainActivityDark', 'Тёмная', Icons.nightlight_round, 'assets/icons/black.png'),
    _IconEntry('MainActivityWhite', 'Белая', Icons.light_mode, 'assets/icons/white.png'),
    _IconEntry('MainActivityBlackWhite', 'Чёрно-белая', Icons.contrast, 'assets/icons/black_white.png'),
    _IconEntry('MainActivityBrize', 'Бриз', Icons.waves, 'assets/icons/brize.png'),
    _IconEntry('MainActivityIngYang', 'Инь-Ян', Icons.balance, 'assets/icons/ing_yang.png'),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final alias = await IconService.getCurrentAlias();
    setState(() => _currentAlias = alias);
  }

  Future<void> _apply(String alias) async {
    setState(() => _loading = true);
    try {
      await IconService.setIcon(alias);
      if (mounted) {
        Navigator.pop(context, true); // сигнал, что иконка изменена
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Иконка изменена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Выберите иконку',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _icons.map((entry) {
              final selected = entry.alias == _currentAlias;
              return GestureDetector(
                onTap: _loading ? null : () => _apply(entry.alias),
                child: Container(
                  width: 90,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(entry.imageAsset, width: 48, height: 48, fit: BoxFit.contain),
                      const SizedBox(height: 8),
                      Text(
                        entry.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _IconEntry {
  final String alias;
  final String title;
  final IconData icon; // запасной вариант
  final String imageAsset;
  const _IconEntry(this.alias, this.title, this.icon, this.imageAsset);
}