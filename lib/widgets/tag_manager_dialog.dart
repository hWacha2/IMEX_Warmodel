// lib/widgets/tag_manager_dialog.dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/statemanager.dart';

class TagManagerDialog extends StatefulWidget {
  const TagManagerDialog({super.key});

  @override
  State<TagManagerDialog> createState() => _TagManagerDialogState();
}

class _TagManagerDialogState extends State<TagManagerDialog> {
  final _newTagController = TextEditingController();
  final _editController = TextEditingController();
  String? _selectedTag;

  // Список защищённых (системных) тегов
  static const _protectedTags = {'пехота', 'бпла', 'фпв', 'uav', 'fpv', 'дрон'};

  bool _isProtected(String tag) => _protectedTags.contains(tag.toLowerCase());

  @override
  void dispose() {
    _newTagController.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StateManager>();
    final tags = provider.tags;

    return ContentDialog(
      title: const Text('Управление типами войск (тегами)'),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  final isSelected = _selectedTag == tag;
                  final isProtected = _isProtected(tag);

                  return ListTile.selectable(
                    title: Row(
                      children: [
                        Text(tag),
                        if (isProtected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: FluentTheme.of(context)
                                  .accentColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'системный',
                              style: TextStyle(
                                fontSize: 10,
                                color: FluentTheme.of(context).accentColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    selected: isSelected,
                    onSelectionChange: (value) {
                      setState(() {
                        _selectedTag = value == true ? tag : null;
                      });
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: isProtected
                              ? 'Системные теги нельзя переименовывать'
                              : 'Переименовать тип',
                          child: IconButton(
                            icon: const Icon(FluentIcons.edit),
                            onPressed: isProtected
                                ? null
                                : () {
                                    _editController.text = tag;
                                    _showEditDialog(context, provider, tag);
                                  },
                          ),
                        ),
                        Tooltip(
                          message: isProtected
                              ? 'Системные теги нельзя удалять'
                              : 'Удалить тип и все отряды с этим тегом',
                          child: IconButton(
                            icon: const Icon(FluentIcons.delete),
                            onPressed: isProtected
                                ? null
                                : () => _confirmRemoveTag(
                                      context,
                                      provider,
                                      tag,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            Row(
              children: [
                Expanded(
                  child: TextBox(
                    controller: _newTagController,
                    placeholder: 'Название нового типа (например, "танки")',
                    onSubmitted: (_) => _addTag(provider),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _addTag(provider),
                  child: const Text('Добавить'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  void _addTag(StateManager provider) {
    final tag = _newTagController.text.trim().toLowerCase();
    if (tag.isEmpty) return;

    if (_isProtected(tag)) {
      displayInfoBar(
        context,
        builder: (ctx, close) => InfoBar(
          severity: InfoBarSeverity.warning,
          title: const Text('Тег уже существует'),
          content: const Text(
            'Этот тип войск является системным и уже доступен.',
          ),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        ),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    provider.addTag(tag);
    _newTagController.clear();
  }

  void _showEditDialog(
    BuildContext context,
    StateManager provider,
    String oldTag,
  ) {
    if (_isProtected(oldTag)) return;

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Переименовать тип войск'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextBox(
              controller: _editController,
              placeholder: 'Новое название типа',
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Все отряды и значения матрицы с тегом "$oldTag" будут обновлены.',
              style: TextStyle(
                fontSize: 12,
                color: FluentTheme.of(context).inactiveColor,
              ),
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final newTag = _editController.text.trim().toLowerCase();
              if (newTag.isNotEmpty &&
                  newTag != oldTag &&
                  !_isProtected(newTag)) {
                provider.editTag(oldTag, newTag);
              }
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveTag(
    BuildContext context,
    StateManager provider,
    String tag,
  ) {
    if (_isProtected(tag)) return;

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Удалить тип войск?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Будут выполнены следующие действия:\n'
              '• Удалены все отряды с тегом "$tag"\n'
              '• Удалены соответствующие строки/столбцы из матрицы эффективности',
            ),
            const SizedBox(height: 8),
            Text(
              'Это действие нельзя отменить.',
              style: TextStyle(
                color: FluentTheme.of(context).accentColor,
              ),
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              provider.removeTag(tag);
              Navigator.pop(context);
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
