import 'package:fluent_ui/fluent_ui.dart';
import 'dart:async';

/// Диалог подтверждения действия
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final Color? confirmColor;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Подтвердить',
    this.cancelText = 'Отмена',
    required this.onConfirm,
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),  // ← child должен быть последним
        ),
        Button(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.hovered)) {
                return (confirmColor ?? FluentTheme.of(context).accentColor)
                    .withValues(alpha: 0.8);
              }
              return confirmColor ?? FluentTheme.of(context).accentColor;
            }),
          ),
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          },
          child: Text(confirmText),  // ← child должен быть последним
        ),
      ],
    );
  }

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Подтвердить',
    String cancelText = 'Отмена',
    Color? confirmColor,
    required VoidCallback onConfirm,  // ← Добавлен параметр
  }) {
    final completer = Completer<bool>();

    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        onConfirm: () {
          completer.complete(true);
          onConfirm();  // ← Вызываем onConfirm
        },
      ),
    ).then((_) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });

    return completer.future;
  }
}