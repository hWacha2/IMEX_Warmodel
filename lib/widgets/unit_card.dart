import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart'; // ← Обязательно!
import '../providers/statemanager.dart';
import '../models/unit_type.dart';
import 'confirm_dialog.dart';
import '../widgets/tag_manager_dialog.dart'; // ← Обязательно!// из lib/widgets/unit_card.dart

/// Карточка типа войск для отображения и редактирования
class UnitCard extends StatefulWidget {
  final UnitType unit;
  final bool isSideA;
  final int index;
  final Function(UnitType) onUpdate;
  final VoidCallback onDelete;

  const UnitCard({
    super.key,
    required this.unit,
    required this.isSideA,
    required this.index,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<UnitCard> {
  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final sideColor =
        widget.isSideA ? const Color(0xFFEF5350) : const Color(0xFF42A5F5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок карточки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Цвет стороны
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: sideColor,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Имя отряда
                        Text(
                          widget.unit.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Тег (всегда показываем)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: FluentTheme.of(context)
                                .resources
                                .cardBackgroundFillColorDefault,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FluentIcons.tag,
                                size: 14,
                                color: FluentTheme.of(context).accentColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.unit.tag,
                                style: TextStyle(
                                  color: FluentTheme.of(context).accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Button(
                      child: const Icon(FluentIcons.edit),
                      onPressed: () => _showEditDialog(context),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      child: const Icon(FluentIcons.delete),
                      onPressed: () => _showDeleteConfirm(context),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              height: 1,
              color: theme.resources.cardStrokeColorDefault,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            const SizedBox(height: 8),

            // Основная информация
            _buildInfoRow('Численность:',
                '${widget.unit.count.toStringAsFixed(0)} ед.', context),
            _buildInfoRow('Боевая мощь:',
                widget.unit.combatPower.toStringAsFixed(2), context),
            _buildInfoRow(
                'Защита:', widget.unit.defense.toStringAsFixed(2), context),
            _buildInfoRow(
                'Мораль:', widget.unit.morale.toStringAsFixed(2), context),
            _buildInfoRow(
                'Снабжение:', widget.unit.supply.toStringAsFixed(2), context),

            Expander(
              header: const Text('Подробные параметры'),
              content: Column(
                children: [
                  _buildInfoRow('Затухание морали:',
                      widget.unit.moraleDecay.toStringAsFixed(3), context),
                  _buildInfoRow('Затухание снабжения:',
                      widget.unit.supplyDecay.toStringAsFixed(3), context),
                  _buildInfoRow(
                      'Чувств. к снабжению:',
                      widget.unit.cpSupplySensitivity.toStringAsFixed(2),
                      context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    final theme = FluentTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: theme.inactiveColor,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EditUnitDialog(
        unit: widget.unit,
        onSave: (updated) {
          widget.onUpdate(updated);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Удаление типа войск',
        message: 'Вы уверены, что хотите удалить "${widget.unit.name}"?',
        confirmText: 'Удалить',
        cancelText: 'Отмена',
        confirmColor: const Color(0xFFEF5350),
        onConfirm: widget.onDelete,
      ),
    );
  }
}

/// Диалог редактирования типа войск
class _EditUnitDialog extends StatefulWidget {
  final UnitType unit;
  final Function(UnitType) onSave;

  const _EditUnitDialog({
    required this.unit,
    required this.onSave,
  });

  @override
  State<_EditUnitDialog> createState() => _EditUnitDialogState();
}

class _EditUnitDialogState extends State<_EditUnitDialog> {
  // Контроллеры полей
  late TextEditingController _nameController;
  late TextEditingController _countController;
  late TextEditingController _combatPowerController;
  late TextEditingController _defenseController;
  late TextEditingController _moraleController;
  late TextEditingController _supplyController;
  late TextEditingController _moraleDecayController;
  late TextEditingController _supplyDecayController;
  late TextEditingController _cpSupplySensController;

  // ← НОВОЕ: Выбранный тег (вместо отдельных флагов)
  late String _selectedTag;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.unit.name);
    _countController =
        TextEditingController(text: widget.unit.count.toString());
    _combatPowerController =
        TextEditingController(text: widget.unit.combatPower.toString());
    _defenseController =
        TextEditingController(text: widget.unit.defense.toString());
    _moraleController =
        TextEditingController(text: widget.unit.morale.toString());
    _supplyController =
        TextEditingController(text: widget.unit.supply.toString());
    _moraleDecayController =
        TextEditingController(text: widget.unit.moraleDecay.toString());
    _supplyDecayController =
        TextEditingController(text: widget.unit.supplyDecay.toString());
    _cpSupplySensController =
        TextEditingController(text: widget.unit.cpSupplySensitivity.toString());

    // ← Инициализируем выбранный тег из юнита
    _selectedTag = widget.unit.tag.isEmpty ? 'пехота' : widget.unit.tag;

    // Применяем дефолты в зависимости от тега
    _applyTagDefaults(_selectedTag);
  }

  // ← НОВОЕ: Применяет дефолтные значения в зависимости от тега
  void _applyTagDefaults(String tag) {
    final lowerTag = tag.toLowerCase();

    if (lowerTag == 'бпла' || lowerTag == 'uav' || lowerTag == 'дрон') {
      // БПЛА: фиксированные параметры
      _moraleController.text = '1.0';
      _moraleDecayController.text = '0.0';
      _combatPowerController.text = '0.0';
      _defenseController.text = '1.0';
      if (_cpSupplySensController.text == '0.0') {
        _cpSupplySensController.text = '0.5';
      }
    } else if (lowerTag == 'фпв' || lowerTag == 'fpv') {
      // FPV: фиксированные параметры
      _moraleController.text = '1.0';
      _moraleDecayController.text = '0.0';
      _defenseController.text = '1.0';
      _supplyController.text = '1.0';
      _supplyDecayController.text = '0.0';
      _cpSupplySensController.text = '0.0';
      if (_combatPowerController.text.isEmpty ||
          double.tryParse(_combatPowerController.text) == 0.0) {
        _combatPowerController.text = '0.8';
      }
    }
    // Для 'пехота' и других тегов оставляем значения как есть
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countController.dispose();
    _combatPowerController.dispose();
    _defenseController.dispose();
    _moraleController.dispose();
    _supplyController.dispose();
    _moraleDecayController.dispose();
    _supplyDecayController.dispose();
    _cpSupplySensController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDrone = _isSpecialTag(_selectedTag);
    final isFpvTag = _isFpvTagValue(_selectedTag);
    final isUavTag = _isUavTagValue(_selectedTag);

    const accentColor = Color(0xFF448AFF);
    final accentColorFaded = accentColor.withValues(alpha: 0.8);

    return ContentDialog(
      title: const Text('Редактирование отряда'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ← НОВОЕ: Выбор тега с иконкой и кнопкой управления
              const Text('Тип войск',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Consumer<StateManager>(
                      builder: (context, provider, _) {
                        return ComboBox<String>(
                          value: _selectedTag,
                          items: provider.tags
                              .map((tag) => ComboBoxItem<String>(
                                    value: tag,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(FluentIcons.tag, size: 14),
                                        const SizedBox(width: 4),
                                        Text(tag),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (tag) {
                            if (tag != null) {
                              setState(() {
                                _selectedTag = tag;
                                _applyTagDefaults(tag);
                              });
                            }
                          },
                          selectedItemBuilder: (context) {
                            return provider.tags.map((tag) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(FluentIcons.tag, size: 14),
                                  const SizedBox(width: 4),
                                  Text(tag),
                                ],
                              );
                            }).toList();
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Управление типами войск',
                    child: IconButton(
                      icon: const Icon(FluentIcons.settings),
                      onPressed: () {
                        // ← Открываем менеджер тегов поверх, не закрывая этот диалог
                        showDialog(
                          context: context,
                          builder: (_) => const TagManagerDialog(),
                        ).then((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Название отряда
              const Text('Название отряда',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextBox(
                controller: _nameController,
                placeholder: 'например, "1-й батальон"',
              ),
              const SizedBox(height: 16),

              // Численность
              const Text('Начальная численность',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextBox(
                controller: _countController,
                placeholder: '0',
              ),
              const SizedBox(height: 16),

              // Боевая мощь
              const Text('Боевая мощь (0-1)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isUavTag)
                TextBox(
                  controller: TextEditingController(text: '0.0'),
                  placeholder: '0.0',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _combatPowerController,
                  placeholder: isFpvTag ? '0.8' : '0.7',
                ),
              if (isUavTag)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'БПЛА не наносят прямого урона',
                    style: TextStyle(
                        fontSize: 12,
                        color: FluentTheme.of(context).inactiveColor),
                  ),
                )
              else if (isFpvTag)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'FPV-дроны наносят урон, но быстро расходуются',
                    style: TextStyle(
                        fontSize: 12,
                        color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // Защита
              const Text('Защита (0-1)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isDrone)
                TextBox(
                  controller: TextEditingController(text: '1.0'),
                  placeholder: '1.0',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _defenseController,
                  placeholder: '0.5',
                ),
              if (isDrone)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Защита дронов фиксирована',
                    style: TextStyle(
                        fontSize: 12,
                        color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // ← УБРАНО: чекбоксы специализации (теперь это теги)

              // Мораль
              const Text('Мораль (0-1)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Opacity(
                opacity: isDrone ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: isDrone,
                  child: TextBox(
                    controller: _moraleController,
                    placeholder: '0.9',
                    readOnly: isDrone,
                  ),
                ),
              ),
              if (isDrone)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Мораль дронов фиксирована на 1.0',
                    style: TextStyle(
                        fontSize: 12,
                        color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // Снабжение
              const Text('Снабжение (0-1)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isFpvTag)
                TextBox(
                  controller: TextEditingController(text: '1.0'),
                  placeholder: '1.0',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _supplyController,
                  placeholder: '1.0',
                ),
              if (isFpvTag)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Снабжение FPV фиксировано',
                    style: TextStyle(
                        fontSize: 12,
                        color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // Затухание морали
              const Text('Затухание морали',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Opacity(
                opacity: isDrone ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: isDrone,
                  child: TextBox(
                    controller: _moraleDecayController,
                    placeholder: '0.02',
                    readOnly: isDrone,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Затухание снабжения
              const Text('Затухание снабжения',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isFpvTag)
                TextBox(
                  controller: TextEditingController(text: '0.0'),
                  placeholder: '0.0',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _supplyDecayController,
                  placeholder: '0.01',
                ),
              if (isFpvTag)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Логистическое истощение для FPV отключено',
                    style: TextStyle(
                        fontSize: 12,
                        color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // Чувствительность к снабжению
              const Text('Чувствительность к снабжению (0-1)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isFpvTag)
                TextBox(
                  controller: TextEditingController(text: '0.0'),
                  placeholder: '0.0',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _cpSupplySensController,
                  placeholder: isUavTag ? '0.5' : '0.3',
                ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isFpvTag
                      ? 'Для FPV-дронов параметр неактивен.'
                      : isUavTag
                          ? 'Влияет на эффективность разведки.'
                          : 'Насколько сильно падение снабжения снижает боевую мощь.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFpvTag
                        ? FluentTheme.of(context).inactiveColor
                        : (isUavTag
                            ? accentColorFaded
                            : FluentTheme.of(context).inactiveColor),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        Button(
          child: const Text('Отмена'),
          onPressed: () => Navigator.pop(context),
        ),
        Button(
          onPressed: _saveChanges,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  // ← Вспомогательные методы для проверки тега
  bool _isSpecialTag(String tag) {
    final lower = tag.toLowerCase();
    return lower == 'бпла' ||
        lower == 'uav' ||
        lower == 'дрон' ||
        lower == 'фпв' ||
        lower == 'fpv';
  }

  bool _isUavTagValue(String tag) {
    final lower = tag.toLowerCase();
    return lower == 'бпла' || lower == 'uav' || lower == 'дрон';
  }

  bool _isFpvTagValue(String tag) {
    final lower = tag.toLowerCase();
    return lower == 'фпв' || lower == 'fpv';
  }

  void _saveChanges() {
    final tag = _selectedTag.isEmpty ? 'пехота' : _selectedTag;

    // ← Определяем флаги на основе тега
    final isUav = _isUavTagValue(tag);
    final isFpv = _isFpvTagValue(tag);
    final isDrone = isUav || isFpv;

    final effectiveMorale =
        isDrone ? 1.0 : (double.tryParse(_moraleController.text) ?? 1.0);
    final effectiveMoraleDecay =
        isDrone ? 0.0 : (double.tryParse(_moraleDecayController.text) ?? 0.01);
    final effectiveCombatPower =
        isUav ? 0.0 : (double.tryParse(_combatPowerController.text) ?? 1.0);
    final effectiveDefense =
        isDrone ? 1.0 : (double.tryParse(_defenseController.text) ?? 0.5);
    final effectiveSupply =
        isFpv ? 1.0 : (double.tryParse(_supplyController.text) ?? 1.0);
    final effectiveSupplyDecay =
        isFpv ? 0.0 : (double.tryParse(_supplyDecayController.text) ?? 0.01);
    final effectiveCpSupplySens =
        isFpv ? 0.0 : (double.tryParse(_cpSupplySensController.text) ?? 0.3);

    final updated = UnitType(
      name: _nameController.text.trim().isEmpty ? tag : _nameController.text,
      tag: tag, // ← Обновляем тег
      count: double.tryParse(_countController.text) ?? 0.0,
      combatPower: effectiveCombatPower,
      defense: effectiveDefense,
      morale: effectiveMorale,
      supply: effectiveSupply,
      moraleDecay: effectiveMoraleDecay,
      supplyDecay: effectiveSupplyDecay,
      cpSupplySensitivity: effectiveCpSupplySens,
      isUav: isUav, // ← Устанавливаем флаги на основе тега
      isFpv: isFpv,
    );

    widget.onSave(updated);
  }
}
