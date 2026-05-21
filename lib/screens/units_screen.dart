// lib/screens/units_screen.dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/statemanager.dart';
import '../models/unit_type.dart';
import '../widgets/unit_card.dart';
import '../widgets/tag_manager_dialog.dart'; // ← НОВОЕ: импорт диалога

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  int _selectedSide = 0; // 0 = A, 1 = B

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой управления тегами
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Управление войсками',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              // ← НОВОЕ: Кнопка управления тегами
              Tooltip(
                message: 'Управление типами войск (тегами)',
                child: Button(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const TagManagerDialog(),
                    );
                  },
                  child: Row(
                    children: const [
                      Icon(FluentIcons.tag),
                      SizedBox(width: 6),
                      Text('Теги'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Сначала создайте тип войск, затем добавляйте отряды',
            style: TextStyle(
              color: FluentTheme.of(context).inactiveColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Выбор стороны
          Row(
            children: [
              ToggleButton(
                checked: _selectedSide == 0,
                onChanged: (checked) {
                  if (checked) setState(() => _selectedSide = 0);
                },
                child: const Text('Сторона A'),
              ),
              const SizedBox(width: 8),
              ToggleButton(
                checked: _selectedSide == 1,
                onChanged: (checked) {
                  if (checked) setState(() => _selectedSide = 1);
                },
                child: const Text('Сторона B'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Список типов войск
          Expanded(
            child: Consumer<StateManager>(
              builder: (context, provider, child) {
                final units =
                    _selectedSide == 0 ? provider.sideA : provider.sideB;

                if (units.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FluentIcons.people,
                          size: 64,
                          color: FluentTheme.of(context).inactiveColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет отрядов',
                          style: TextStyle(
                            color: FluentTheme.of(context).inactiveColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите "Добавить отряд" для создания',
                          style: TextStyle(
                            color: FluentTheme.of(context).inactiveColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    return UnitCard(
                      unit: units[index],
                      isSideA: _selectedSide == 0,
                      index: index,
                      onUpdate: (updated) {
                        provider.updateUnit(_selectedSide, index, updated);
                      },
                      onDelete: () {
                        provider.removeUnit(_selectedSide, index);
                      },
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Кнопка добавления отряда
          Button(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.add),
                SizedBox(width: 8),
                Text('Добавить отряд'),
              ],
            ),
            onPressed: () => _showAddUnitDialog(context),
          ),
        ],
      ),
    );
  }

  /// Диалог добавления отряда
  void _showAddUnitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddUnitDialog(isSideA: _selectedSide == 0),
    );
  }
}

/// Диалог добавления отряда
class _AddUnitDialog extends StatefulWidget {
  final bool isSideA;

  const _AddUnitDialog({required this.isSideA});

  @override
  State<_AddUnitDialog> createState() => _AddUnitDialogState();
}
// lib/screens/units_screen.dart (фрагмент _AddUnitDialog)

class _AddUnitDialogState extends State<_AddUnitDialog> {
  // Контроллеры полей
  final _nameController = TextEditingController(text: '1-й батальон');
  final _countController = TextEditingController(text: '100');
  final _combatPowerController = TextEditingController(text: '0.7');
  final _defenseController = TextEditingController(text: '0.5');
  final _moraleController = TextEditingController(text: '0.9');
  final _supplyController = TextEditingController(text: '1.0');
  final _moraleDecayController = TextEditingController(text: '0.02');
  final _supplyDecayController = TextEditingController(text: '0.01');
  final _cpSupplySensController = TextEditingController(text: '0.3');

  // ← НОВОЕ: Выбранный тег (включая спец. типы)
  String _selectedTag = 'пехота';

  @override
  void initState() {
    super.initState();
    final provider = context.read<StateManager>();
    if (provider.tags.isNotEmpty) {
      _selectedTag = provider.tags.first;
      _applyTagDefaults(_selectedTag); // ← Применяем дефолты при инициализации
    }
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
    final provider = context.watch<StateManager>();
    
    // ← Определяем, является ли выбранный тег спец. типом
    final lowerTag = _selectedTag.toLowerCase();
    final isSpecialTag = lowerTag == 'бпла' || lowerTag == 'uav' || 
                         lowerTag == 'дрон' || lowerTag == 'фпв' || lowerTag == 'fpv';
    final isFpvTag = lowerTag == 'фпв' || lowerTag == 'fpv';
    final isUavTag = lowerTag == 'бпла' || lowerTag == 'uav' || lowerTag == 'дрон';

    const accentColor = Color(0xFF448AFF);
    final accentColorFaded = accentColor.withValues(alpha: 0.8);

    return ContentDialog(
      title: Text('Добавить отряд (${widget.isSideA ? "Сторона A" : "B"})'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Выбор тега с иконкой
              const Text('Тип войск', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: ComboBox<String>(
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
                              )))
                          .toList(),
                      onChanged: provider.tags.length < 2
                          ? null
                          : (tag) {
                              if (tag != null) {
                                setState(() {
                                  _selectedTag = tag;
                                  _applyTagDefaults(tag); // ← Применяем дефолты при смене тега
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
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Управление типами войск',
                    child: IconButton(
                      icon: const Icon(FluentIcons.settings),
                      onPressed: () {
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
              const Text('Название отряда', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextBox(
                controller: _nameController,
                placeholder: 'например, "1-й батальон"',
              ),
              const SizedBox(height: 16),

              // Численность
              const Text('Начальная численность', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextBox(
                controller: _countController,
                placeholder: '0',
              ),
              const SizedBox(height: 16),

              // Боевая мощь
              const Text('Боевая мощь (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
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
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                )
              else if (isFpvTag)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'FPV-дроны наносят урон, но быстро расходуются',
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // Защита
              const Text('Защита (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isSpecialTag)
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
              if (isSpecialTag)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Защита дронов фиксирована',
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // ← УБРАНО: чекбоксы специализации (теперь это теги)

              // Мораль
              const Text('Мораль (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Opacity(
                opacity: isSpecialTag ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: isSpecialTag,
                  child: TextBox(
                    controller: _moraleController,
                    placeholder: '0.9',
                    readOnly: isSpecialTag,
                  ),
                ),
              ),
              if (isSpecialTag)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Мораль дронов фиксирована на 1.0',
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // Снабжение
              const Text('Снабжение (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
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
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // Затухание морали
              const Text('Затухание морали', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Opacity(
                opacity: isSpecialTag ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: isSpecialTag,
                  child: TextBox(
                    controller: _moraleDecayController,
                    placeholder: '0.02',
                    readOnly: isSpecialTag,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Затухание снабжения
              const Text('Затухание снабжения', style: TextStyle(fontWeight: FontWeight.w500)),
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
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // Чувствительность к снабжению
              const Text('Чувствительность к снабжению (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
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
                        : (isUavTag ? accentColorFaded : FluentTheme.of(context).inactiveColor),
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
          onPressed: _addUnit,
          child: const Text('Добавить отряд'),
        ),
      ],
    );
  }

  /// Создаёт юнита с выбранным тегом и соответствующими флагами
  void _addUnit() {
    final provider = context.read<StateManager>();
    final tag = _selectedTag.isEmpty ? 'пехота' : _selectedTag;
    final lowerTag = tag.toLowerCase();
    
    // ← Определяем флаги на основе тега
    final isUav = lowerTag == 'бпла' || lowerTag == 'uav' || lowerTag == 'дрон';
    final isFpv = lowerTag == 'фпв' || lowerTag == 'fpv';
    final isDrone = isUav || isFpv;

    final effectiveMorale = isDrone ? 1.0 : (double.tryParse(_moraleController.text) ?? 1.0);
    final effectiveMoraleDecay = isDrone ? 0.0 : (double.tryParse(_moraleDecayController.text) ?? 0.01);
    final effectiveCombatPower = isUav ? 0.0 : (double.tryParse(_combatPowerController.text) ?? 1.0);
    final effectiveDefense = isDrone ? 1.0 : (double.tryParse(_defenseController.text) ?? 0.5);
    final effectiveSupply = isFpv ? 1.0 : (double.tryParse(_supplyController.text) ?? 1.0);
    final effectiveSupplyDecay = isFpv ? 0.0 : (double.tryParse(_supplyDecayController.text) ?? 0.01);
    final effectiveCpSupplySens = isFpv ? 0.0 : (double.tryParse(_cpSupplySensController.text) ?? 0.3);

    final unit = UnitType(
      name: _nameController.text.trim().isEmpty ? tag : _nameController.text,
      tag: tag,
      count: double.tryParse(_countController.text) ?? 0.0,
      combatPower: effectiveCombatPower,
      defense: effectiveDefense,
      morale: effectiveMorale,
      supply: effectiveSupply,
      moraleDecay: effectiveMoraleDecay,
      supplyDecay: effectiveSupplyDecay,
      cpSupplySensitivity: effectiveCpSupplySens,
      isUav: isUav,  // ← Устанавливаем флаги на основе тега
      isFpv: isFpv,
    );

    provider.addUnit(widget.isSideA, unit);
    Navigator.pop(context);
  }
}