import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/statemanager.dart';
import '../models/unit_type.dart';
import '../widgets/unit_card.dart';

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
          const Text(
            'Управление типами войск',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Выбор стороны - используем SegmentedButton
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
                          'Нет типов войск',
                          style: TextStyle(
                            color: FluentTheme.of(context).inactiveColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите "Добавить" для создания',
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

          // Кнопка добавления
          Button(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FluentIcons.add),
                SizedBox(width: 8),
                Text('Добавить тип войск'),
              ],
            ),
            onPressed: () => _showAddUnitDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAddUnitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddUnitDialog(isSideA: _selectedSide == 0),
    );
  }
}

/// Диалог добавления типа войск
class _AddUnitDialog extends StatefulWidget {
  final bool isSideA;

  const _AddUnitDialog({required this.isSideA});

  @override
  State<_AddUnitDialog> createState() => _AddUnitDialogState();
}

class _AddUnitDialogState extends State<_AddUnitDialog> {
  final _nameController = TextEditingController(text: 'Пехота');
  final _countController = TextEditingController(text: '1000');
  final _combatPowerController = TextEditingController(text: '0.7');
  final _defenseController = TextEditingController(text: '0.5');
  final _moraleController = TextEditingController(text: '0.9');
  final _supplyController = TextEditingController(text: '1.0');
  final _moraleDecayController = TextEditingController(text: '0.02');
  final _supplyDecayController = TextEditingController(text: '0.01');
  final _cpSupplySensController = TextEditingController(text: '0.3');

  // === Флаги для БПЛА/FPV ===
  bool _isUav = false;
  bool _isFpv = false;

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

  // === Методы для управления взаимно исключающими флагами ===
  void _setUav(bool value) {
    setState(() {
      _isUav = value;
      if (value) {
        _isFpv = false;
        _moraleController.text = '1.0';
        _moraleDecayController.text = '0.0';
        _combatPowerController.text = '0.0';
        _defenseController.text = '1.0';
        // Для БПЛА чувствительность важна (влияет на активность разведки), оставляем редактируемой
        if (_cpSupplySensController.text == '0.0') {
           _cpSupplySensController.text = '0.5'; // Дефолт для БПЛА
        }
      }
    });
  }

  void _setFpv(bool value) {
    setState(() {
      _isFpv = value;
      if (value) {
        _isUav = false;
        _moraleController.text = '1.0';
        _moraleDecayController.text = '0.0';
        _defenseController.text = '1.0';
        _supplyController.text = '1.0';
        _supplyDecayController.text = '0.0';
        
        // Для FPV чувствительность не используется (расход через lambda_use)
        _cpSupplySensController.text = '0.0';

        if (_combatPowerController.text.isEmpty ||
            double.tryParse(_combatPowerController.text) == 0.0) {
          _combatPowerController.text = '0.8';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDrone = _isUav || _isFpv;
    final isFpvOnly = _isFpv;
    final isUavOnly = _isUav;
    
    // === Единый стиль для акцентного цвета ===
    const accentColor = Color(0xFF448AFF);
    final accentColorFaded = accentColor.withValues(alpha: 0.8);

    return ContentDialog(
      title: Text(
          'Добавить тип войск (${widget.isSideA ? 'Сторона A' : 'Сторона B'})'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Название', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextBox(
                controller: _nameController,
                placeholder: 'например, Пехота',
              ),
              const SizedBox(height: 16),

              const Text('Начальная численность', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextBox(
                controller: _countController,
                placeholder: '0',
              ),
              const SizedBox(height: 16),

              const Text('Боевая мощь (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (_isUav)
                TextBox(
                  controller: TextEditingController(text: '0.0'),
                  placeholder: '0.0',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _combatPowerController,
                  placeholder: _isFpv ? '0.8' : '0.7',
                ),
              if (_isUav)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'БПЛА не наносят прямого урона',
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                )
              else if (_isFpv)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'FPV-дроны наносят урон, но быстро расходуются',
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              const Text('Защита (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
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
                    'Защита дронов фиксирована (исключены из матрицы потерь)',
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // === Секция тегов БПЛА/FPV ===
              const Text('Тип подразделения', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              InfoBar(
                title: const Text('Специализированные средства'),
                content: const Text(
                  'БПЛА и FPV дроны имеют особую динамику: '
                  'они не подвержены моральному фактору и исключены из огневой матрицы.',
                ),
                severity: InfoBarSeverity.info,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Checkbox(
                      checked: _isUav,
                      onChanged: (value) => _setUav(value ?? false),
                      content: const Text('БПЛА'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Checkbox(
                      checked: _isFpv,
                      onChanged: (value) => _setFpv(value ?? false),
                      content: const Text('FPV-дрон'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // === Поле морали с блокировкой ===
              const Text('Мораль (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
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
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // === Поле снабжения ===
              const Text('Снабжение (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isFpvOnly)
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
              if (isFpvOnly)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Снабжение FPV фиксировано (расход моделируется отдельно)',
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              const SizedBox(height: 16),

              // === Поле затухания морали ===
              const Text('Затухание морали', style: TextStyle(fontWeight: FontWeight.w500)),
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

              // === Поле затухания снабжения ===
              const Text('Затухание снабжения', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isFpvOnly)
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
              if (isFpvOnly)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Логистическое истощение для FPV отключено',
                    style: TextStyle(fontSize: 12, color: FluentTheme.of(context).inactiveColor),
                  ),
                ),
              
              // === НОВОЕ: Поле чувствительности к снабжению с динамической подсказкой ===
              const SizedBox(height: 16),
              const Text('Чувствительность к снабжению (0-1)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              
              if (isFpvOnly)
                // Для FPV поле заблокировано и равно 0
                TextBox(
                  controller: TextEditingController(text: '0.0'),
                  placeholder: '0.0',
                  readOnly: true,
                  enabled: false,
                )
              else
                // Для Пехоты и БПЛА поле активно
                TextBox(
                  controller: _cpSupplySensController,
                  placeholder: isUavOnly ? '0.5' : '0.3',
                ),
              const SizedBox(height: 4),
              // Динамическая подсказка
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  isFpvOnly
                      ? 'Для FPV-дронов параметр неактивен (равен 0).'
                      : isUavOnly
                          ? 'Влияет на эффективность разведки: чем выше, тем сильнее падает активность БПЛА при потере снабжения.'
                          : 'Насколько сильно падение снабжения снижает боевую мощь.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isFpvOnly 
                        ? FluentTheme.of(context).inactiveColor 
                        : (isUavOnly ? accentColorFaded : FluentTheme.of(context).inactiveColor),
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
          child: const Text('Добавить'),
        ),
      ],
    );
  }

  void _addUnit() {
    final provider = context.read<StateManager>();

    final isDrone = _isUav || _isFpv;
    final effectiveMorale = isDrone ? 1.0 : (double.tryParse(_moraleController.text) ?? 1.0);
    final effectiveMoraleDecay = isDrone ? 0.0 : (double.tryParse(_moraleDecayController.text) ?? 0.01);

    // БПЛА всегда имеют боевую мощь 0
    final effectiveCombatPower = _isUav ? 0.0 : (double.tryParse(_combatPowerController.text) ?? 1.0);

    // Защита для дронов всегда 1.0
    final effectiveDefense = isDrone ? 1.0 : (double.tryParse(_defenseController.text) ?? 0.5);

    // Снабжение и его затухание для FPV фиксированы
    final effectiveSupply = _isFpv ? 1.0 : (double.tryParse(_supplyController.text) ?? 1.0);
    final effectiveSupplyDecay = _isFpv ? 0.0 : (double.tryParse(_supplyDecayController.text) ?? 0.01);

    // Чувствительность к снабжению
    // Если это FPV, то принудительно 0.0, иначе берем из поля ввода
    final effectiveCpSupplySens = _isFpv 
        ? 0.0 
        : (double.tryParse(_cpSupplySensController.text) ?? 0.3);

    final unit = UnitType(
      name: _nameController.text.trim().isEmpty ? 'Новый тип' : _nameController.text,
      count: double.tryParse(_countController.text) ?? 0.0,
      combatPower: effectiveCombatPower,
      defense: effectiveDefense,
      morale: effectiveMorale,
      supply: effectiveSupply,
      moraleDecay: effectiveMoraleDecay,
      supplyDecay: effectiveSupplyDecay,
      cpSupplySensitivity: effectiveCpSupplySens,
      // === Теги ===
      isUav: _isUav,
      isFpv: _isFpv,
    );

    provider.addUnit(widget.isSideA, unit);
    Navigator.pop(context);
  }
}
