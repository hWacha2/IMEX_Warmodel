import 'package:fluent_ui/fluent_ui.dart';
import '../models/unit_type.dart';
import 'confirm_dialog.dart';

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
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: sideColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.unit.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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

                  // === Отображение тегов ===
                  if (widget.unit.isUav || widget.unit.isFpv) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: FluentTheme.of(context)
                            .resources
                            .cardBackgroundFillColorDefault,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.unit.isUav
                                ? FluentIcons.airplane
                                : FluentIcons.rocket,
                            size: 16,
                            color: FluentTheme.of(context).accentColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.unit.isUav
                                ? 'Разведывательный БПЛА'
                                : 'Ударный FPV-дрон',
                            style: TextStyle(
                              color: FluentTheme.of(context).accentColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
  late TextEditingController _nameController;
  late TextEditingController _countController;
  late TextEditingController _combatPowerController;
  late TextEditingController _defenseController;
  late TextEditingController _moraleController;
  late TextEditingController _supplyController;
  late TextEditingController _moraleDecayController;
  late TextEditingController _supplyDecayController;
  late TextEditingController _cpSupplySensController;

  // === Флаги для БПЛА/FPV ===
  late bool _isUav;
  late bool _isFpv;

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

    // === Инициализация флагов ===
    _isUav = widget.unit.isUav;
    _isFpv = widget.unit.isFpv;

    _applyDroneLogic();
  }

  // Применяет логику блокировки полей в зависимости от типа дрона
  void _applyDroneLogic() {
    // 1. Мораль и её затухание фиксированы для всех дронов
    if (_isUav || _isFpv) {
      _moraleController.text = '1.0';
      _moraleDecayController.text = '0.0';
    }

    // 2. Защита фиксирована на 1.0 для всех дронов
    if (_isUav || _isFpv) {
      _defenseController.text = '1.0';
    }

    // 3. Боевая мощь фиксирована на 0.0 для разведывательных БПЛА
    if (_isUav) {
      _combatPowerController.text = '0.0';
    }

    // 4. Снабжение и его затухание фиксированы для FPV
    if (_isFpv) {
      _supplyController.text = '1.0';
      _supplyDecayController.text = '0.0';
    }
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

  // === Методы для управления флагами ===
  void _setUav(bool value) {
    setState(() {
      _isUav = value;
      if (value) {
        _isFpv = false;
      }
      _applyDroneLogic();
    });
  }

  void _setFpv(bool value) {
    setState(() {
      _isFpv = value;
      if (value) {
        _isUav = false;
      }
      _applyDroneLogic();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDrone = _isUav || _isFpv;
    final isFpvOnly = _isFpv;

    return ContentDialog(
      title: const Text('Редактирование типа войск'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextBox(
                controller: _nameController,
                placeholder: 'Название',
              ),
              const SizedBox(height: 12),
              TextBox(
                controller: _countController,
                placeholder: 'Начальная численность',
              ),
              const SizedBox(height: 12),

              // Боевая мощь (блокируется для UAV)
              if (_isUav)
                TextBox(
                  controller: TextEditingController(text: '0.0'),
                  placeholder: 'Боевая мощь (0-1)',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _combatPowerController,
                  placeholder: 'Боевая мощь (0-1)',
                ),
              if (_isUav)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'БПЛА не наносят прямого урона',
                    style: TextStyle(
                        fontSize: 12,
                        color: FluentTheme.of(context).inactiveColor),
                  ),
                ),

              const SizedBox(height: 12),

              // Защита (блокируется для всех дронов)
              if (isDrone)
                TextBox(
                  controller: TextEditingController(text: '1.0'),
                  placeholder: 'Защита (0-1)',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _defenseController,
                  placeholder: 'Защита (0-1)',
                ),
              if (isDrone)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    'Дроны исключены из матрицы потерь (защита 1.0)',
                    style: TextStyle(
                        fontSize: 12,
                        color: FluentTheme.of(context).inactiveColor),
                  ),
                ),

              const SizedBox(height: 12),

              // === Секция тегов ===
              const Text('Тип подразделения',
                  style: TextStyle(fontWeight: FontWeight.w500)),
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
              const SizedBox(height: 12),

              // === Поле морали с блокировкой ===
              const Text('Мораль (0-1)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Opacity(
                opacity: isDrone ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: isDrone,
                  child: TextBox(
                    controller: _moraleController,
                    placeholder: 'Мораль',
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
                      color: FluentTheme.of(context).inactiveColor,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // === Поле снабжения с блокировкой для FPV ===
              const Text('Снабжение (0-1)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isFpvOnly)
                TextBox(
                  controller: TextEditingController(text: '1.0'),
                  placeholder: 'Снабжение (0-1)',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _supplyController,
                  placeholder: 'Снабжение (0-1)',
                ),
              if (isFpvOnly)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Снабжение FPV фиксировано (расход через lambda_use)',
                    style: TextStyle(
                      fontSize: 12,
                      color: FluentTheme.of(context).inactiveColor,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // === Затухание морали с блокировкой ===
              const Text('Затухание морали',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Opacity(
                opacity: isDrone ? 0.5 : 1.0,
                child: IgnorePointer(
                  ignoring: isDrone,
                  child: TextBox(
                    controller: _moraleDecayController,
                    placeholder: 'Затухание морали',
                    readOnly: isDrone,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // === Затухание снабжения с блокировкой для FPV ===
              const Text('Затухание снабжения',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              if (isFpvOnly)
                TextBox(
                  controller: TextEditingController(text: '0.0'),
                  placeholder: 'Затухание снабжения',
                  readOnly: true,
                  enabled: false,
                )
              else
                TextBox(
                  controller: _supplyDecayController,
                  placeholder: 'Затухание снабжения',
                ),
              const Text('Чувствительность к снабжению (0-1)',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextBox(
                controller: _cpSupplySensController,
                placeholder: '0.3',
              ),
              const SizedBox(height: 12),
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

  void _saveChanges() {
    // === Принудительная установка значений для дронов ===

    // 1. Мораль и её затухание
    final effectiveMorale = (_isUav || _isFpv)
        ? 1.0
        : (double.tryParse(_moraleController.text) ?? 1.0);
    final effectiveMoraleDecay = (_isUav || _isFpv)
        ? 0.0
        : (double.tryParse(_moraleDecayController.text) ?? 0.01);

    // 2. Защита
    final effectiveDefense = (_isUav || _isFpv)
        ? 1.0
        : (double.tryParse(_defenseController.text) ?? 1.0);

    // 3. Боевая мощь
    final effectiveCombatPower =
        _isUav ? 0.0 : (double.tryParse(_combatPowerController.text) ?? 1.0);

    // 4. Снабжение и его затухание
    final effectiveSupply =
        _isFpv ? 1.0 : (double.tryParse(_supplyController.text) ?? 1.0);
    final effectiveSupplyDecay =
        _isFpv ? 0.0 : (double.tryParse(_supplyDecayController.text) ?? 0.01);
    final effectiveCpSupplySens =
        double.tryParse(_cpSupplySensController.text) ?? 0.3;

    final updated = UnitType(
      name: _nameController.text,
      count: double.tryParse(_countController.text) ?? 0.0,
      combatPower: effectiveCombatPower,
      defense: effectiveDefense,
      morale: effectiveMorale,
      supply: effectiveSupply,
      moraleDecay: effectiveMoraleDecay,
      supplyDecay: effectiveSupplyDecay,
      cpSupplySensitivity: effectiveCpSupplySens,
      isUav: _isUav,
      isFpv: _isFpv,
    );
    widget.onSave(updated);
  }
}
