import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/statemanager.dart';
import '../widgets/param_field.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StateManager>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Параметры модели',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSection(
                    'Влияние потерь на мораль',
                    [
                      ParamField(
                        label: 'Влияние потерь на мораль стороны А',
                        value: provider.moralDebaffA,
                        onChanged: (v) => provider.updateGlobalParams(
                          moralDebaffA: v,
                        ),
                        minValue: 0,
                        maxValue: 5,
                        step: 0.1,
                      ),
                      ParamField(
                        label: 'Влияние потерь на мораль стороны B',
                        value: provider.moralDebaffB,
                        onChanged: (v) => provider.updateGlobalParams(
                          moralDebaffB: v,
                        ),
                        minValue: 0,
                        maxValue: 5,
                        step: 0.1,
                      ),
                      // === НОВОЕ: Влияние успехов противника на мораль ===
                      ParamField(
                        label: 'Влияние успехов противника',
                        description:
                            'Рост морали при превосходстве над противником',
                        value: provider.epsilonSuccess,
                        onChanged: (v) => provider.updateGlobalParams(
                          epsilonSuccess: v,
                        ),
                        minValue: 0,
                        maxValue: 5,
                        step: 0.1,
                      ),
                    ],
                  ),

                  _buildSection(
                    'Влияние морали',
                    [
                      ParamField(
                        label: 'Влияние морали на атаку',
                        description: 'Экспонента для атакующей способности',
                        value: provider.gammaAtt,
                        onChanged: (v) => provider.updateGlobalParams(
                          gammaAtt: v,
                        ),
                        minValue: 0,
                        maxValue: 5,
                        step: 0.1,
                      ),
                      ParamField(
                        label: 'Влияние морали на уязвимость',
                        description: 'Экспонента для уязвимости',
                        value: provider.gammaExp,
                        onChanged: (v) => provider.updateGlobalParams(
                          gammaExp: v,
                        ),
                        minValue: 0,
                        maxValue: 5,
                        step: 0.1,
                      ),
                      ParamField(
                        label: 'Базовая уязвимость',
                        description:
                            'Минимальная уязвимость при высокой морали',
                        value: provider.epsilonExp,
                        onChanged: (v) => provider.updateGlobalParams(
                          epsilonExp: v,
                        ),
                        minValue: 0,
                        maxValue: 1,
                        step: 0.01,
                      ),
                    ],
                  ),

                  // === НОВОЕ: Параметры БПЛА/FPV ===
                  _buildSection(
                    'Параметры БПЛА/FPV',
                    [
                      ParamField(
                        label: 'Влияние БПЛА на уязвимость (κ)',
                        description:
                            'Насколько превосходство в БПЛА увеличивает уязвимость',
                        value: provider.kappaUav,
                        onChanged: (v) => provider.updateGlobalParams(
                          kappaUav: v,
                        ),
                        minValue: 0,
                        maxValue: 2,
                        step: 0.1,
                      ),
                      ParamField(
                        label: 'Техдеградация БПЛА (λₜ)',
                        description:
                            'Скорость потери разведывательных дронов (РЭБ, отказы)',
                        value: provider.lambdaTech,
                        onChanged: (v) => provider.updateGlobalParams(
                          lambdaTech: v,
                        ),
                        minValue: 0,
                        maxValue: 0.1,
                        step: 0.001,
                        decimalPlaces: 4,
                      ),
                      ParamField(
                        label: 'Расходование FPV (λᵤ)',
                        description:
                            'Скорость боевого расходования ударных дронов',
                        value: provider.lambdaUse,
                        onChanged: (v) => provider.updateGlobalParams(
                          lambdaUse: v,
                        ),
                        minValue: 0,
                        maxValue: 1,
                        step: 0.01,
                        decimalPlaces: 3,
                      ),
                      ParamField(
                        label: 'Бонус за залп (κᵦ)',
                        description:
                            'Максимальное усиление урона при массированном применении FPV',
                        value: provider.kBurst,
                        onChanged: (v) =>
                            provider.updateGlobalParams(kBurst: v),
                        minValue: 0,
                        maxValue: 3,
                        step: 0.1,
                      ),
                      ParamField(
                        label: 'Порог насыщения (R½)',
                        description:
                            'Скорость расхода (дронов/мин) для 50% бонуса',
                        value: provider.rHalf,
                        onChanged: (v) => provider.updateGlobalParams(rHalf: v),
                        minValue: 0.1,
                        maxValue: 20,
                        step: 0.5,
                        decimalPlaces: 2,
                      ),
                    ],
                  ),

                  _buildSection(
                    'Параметры интегрирования',
                    [
                      ParamField(
                        label: 'Δt (dt)',
                        description: 'Шаг интегрирования',
                        value: provider.dt,
                        onChanged: (v) => provider.updateGlobalParams(
                          dt: v,
                        ),
                        minValue: 0.001,
                        maxValue: 0.1,
                        step: 0.001,
                        decimalPlaces: 6,
                      ),
                      ParamField(
                        label: 'Шаги (steps)',
                        description: 'Количество шагов моделирования',
                        value: provider.steps.toDouble(),
                        isInteger: true,
                        onChanged: (v) => provider.updateGlobalParams(
                          steps: v.toInt(),
                        ),
                        minValue: 100,
                        maxValue: 10000,
                        step: 100,
                      ),
                      ParamField(
                        label: 'Точность (tolerance)',
                        description: 'Точность метода Ньютона',
                        value: provider.tolerance,
                        onChanged: (v) => provider.updateGlobalParams(
                          tolerance: v,
                        ),
                        minValue: 1e-10,
                        maxValue: 1e-3,
                        step: 1e-7,
                        decimalPlaces: 8,
                      ),
                      ParamField(
                        label: 'Макс. итераций Ньютона',
                        description: 'Ограничение итераций метода Ньютона',
                        value: provider.maxNewtonIter.toDouble(),
                        isInteger: true,
                        onChanged: (v) => provider.updateGlobalParams(
                          maxNewtonIter: v.toInt(),
                        ),
                        minValue: 100,
                        maxValue: 50000,
                        step: 100,
                      ),
                    ],
                  ),

                  _buildSection(
                    'Масштабирование',
                    [
                      ParamField(
                        label: 'Эталонная численность',
                        description:
                            'Эталонная численность для масштабирования',
                        value: provider.dRef,
                        onChanged: (v) => provider.updateGlobalParams(
                          dRef: v,
                        ),
                        minValue: 100,
                        maxValue: 10000,
                        step: 100,
                      ),
                      ParamField(
                        label: 'Показатель чувствительности',
                        description: 'Показатель степени масштабирования',
                        value: provider.pScale,
                        onChanged: (v) => provider.updateGlobalParams(
                          pScale: v,
                        ),
                        minValue: 0.5,
                        maxValue: 3,
                        step: 0.1,
                      ),
                      // === НОВОЕ: Границы масштабирования ===
                      ParamField(
                        label: 'Мин. множитель (Sₘᵢₙ)',
                        description: 'Нижняя граница масштабирующего множителя',
                        value: provider.sMin,
                        onChanged: (v) => provider.updateGlobalParams(
                          sMin: v,
                        ),
                        minValue: 1e-6,
                        maxValue: 0.1,
                        step: 1e-5,
                        decimalPlaces: 6,
                      ),
                      ParamField(
                        label: 'Макс. множитель (Sₘₐₓ)',
                        description:
                            'Верхняя граница масштабирующего множителя',
                        value: provider.sMax,
                        onChanged: (v) => provider.updateGlobalParams(
                          sMax: v,
                        ),
                        minValue: 0.1,
                        maxValue: 10,
                        step: 0.1,
                        decimalPlaces: 3,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const InfoBar(
            title: Text('Рекомендуемые значения'),
            content: Text(
              'Значения по умолчанию настроены для валидации с MATLAB. '
              'Изменяйте параметры только при наличии обоснования. '
              'Для БПЛА: κ≈0.3–0.7, λₜ≈0.01, λᵤ≈0.1–0.2.',
            ),
          ),
          const SizedBox(height: 16),
          Button(
            onPressed: () => _resetSettings(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.refresh),
                SizedBox(width: 8),
                Text('Сбросить к значениям по умолчанию'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...fields,
          ],
        ),
      ),
    );
  }

  void _resetSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Сброс параметров'),
        content: const Text(
          'Вы уверены, что хотите сбросить все параметры к значениям по умолчанию?',
        ),
        actions: [
          Button(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<StateManager>().resetGlobalParams();
              _showNotification(context, 'Параметры сброшены');
            },
            child: const Text('Сбросить'),
          ),
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showNotification(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        severity: InfoBarSeverity.success,
        title: const Text('Успешно'),
        content: Text(message),
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
      duration: const Duration(seconds: 2),
    );
  }
}
