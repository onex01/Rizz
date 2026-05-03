import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/settings/settings_provider.dart';

class WallpaperPickerDialog extends StatefulWidget {
  const WallpaperPickerDialog({super.key});

  @override
  State<WallpaperPickerDialog> createState() => _WallpaperPickerDialogState();
}

class _WallpaperPickerDialogState extends State<WallpaperPickerDialog> {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return AlertDialog(
      title: const Text('Выберите фон чата'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(context, title: 'Сплошной цвет', icon: Icons.format_paint,
                selected: settings.chatBgType == ChatBackgroundType.color, onTap: () async {
              final color = await showDialog<Color>(context: context, builder: (_) => _ColorPickerDialog());
              if (color != null) {
                await settings.setChatSolidColor(color);
                await settings.setChatBackgroundType(ChatBackgroundType.color);
              }
            }),
            _buildOption(context, title: 'Градиент', icon: Icons.gradient,
                selected: settings.chatBgType == ChatBackgroundType.gradient, onTap: () async {
              final colors = await showDialog<Pair<Color, Color>?>(
                  context: context, builder: (_) => _GradientPickerDialog());
              if (colors != null) {
                await settings.setChatGradientColors(colors.item1, colors.item2);
                await settings.setChatBackgroundType(ChatBackgroundType.gradient);
              }
            }),
            _buildOption(context, title: 'Своя картинка', icon: Icons.image,
                selected: settings.chatBgType == ChatBackgroundType.image, onTap: () async {
              final result = await FilePicker.pickFiles(type: FileType.image);
              if (result != null && result.files.single.path != null) {
                await settings.setChatImagePath(result.files.single.path!);
                await settings.setChatBackgroundType(ChatBackgroundType.image);
              }
            }),
            _buildOption(context, title: 'Динамический градиент', icon: Icons.auto_awesome,
                selected: settings.chatBgType == ChatBackgroundType.procedural, onTap: () async {
              await settings.setChatBackgroundType(ChatBackgroundType.procedural);
            }),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
      ],
    );
  }

  Widget _buildOption(BuildContext context, {required String title, required IconData icon, required bool selected, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: onTap,
    );
  }
}

// Вспомогательные диалоги выбора цвета и градиента (без стекла)
class _ColorPickerDialog extends StatefulWidget {
  @override
  _ColorPickerDialogState createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  Color selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите цвет'),
      content: Wrap(
        spacing: 8, runSpacing: 8,
        children: Colors.primaries.map((color) => GestureDetector(
          onTap: () => setState(() => selectedColor = color),
          child: Container(width: 40, height: 40,
            decoration: BoxDecoration(
              color: color, shape: BoxShape.circle,
              border: selectedColor == color ? Border.all(color: Colors.white, width: 3) : null,
            ),
          ),
        )).toList(),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, selectedColor), child: const Text('Выбрать'))],
    );
  }
}

class Pair<T1, T2> {
  final T1 item1;
  final T2 item2;
  Pair(this.item1, this.item2);
}

class _GradientPickerDialog extends StatefulWidget {
  @override
  _GradientPickerDialogState createState() => _GradientPickerDialogState();
}

class _GradientPickerDialogState extends State<_GradientPickerDialog> {
  Color color1 = Colors.blue;
  Color color2 = Colors.purple;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Выберите два цвета'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildColorRow('Цвет 1', color1, (c) => setState(() => color1 = c)),
        const SizedBox(height: 12),
        _buildColorRow('Цвет 2', color2, (c) => setState(() => color2 = c)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context, Pair(color1, color2)), child: const Text('Готово'))],
    );
  }

  Widget _buildColorRow(String label, Color color, ValueChanged<Color> onChanged) {
    return Wrap(children: Colors.primaries.map((c) => GestureDetector(
      onTap: () => onChanged(c),
      child: Container(width: 30, height: 30, margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: c, shape: BoxShape.circle,
          border: color == c ? Border.all(color: Colors.white, width: 2) : null,
        ),
      ),
    )).toList());
  }
}