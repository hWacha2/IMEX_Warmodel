// lib/screens/matrix_screen.dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/statemanager.dart';
import '../widgets/effectiveness_matrix.dart';

class MatrixScreen extends StatelessWidget {
  const MatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StateManager>();
    final m = provider.sideA.length;
    final n = provider.sideB.length;
    final tags = provider.tags;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === НЕСКРОЛЛИРУЕМАЯ ШАПКА ===
          const Text(
            'Матрицы эффективности',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Настройте базовые значения по типам войск, затем при необходимости отредактируйте конкретные отряды',
            style: TextStyle(
              color: FluentTheme.of(context).inactiveColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // === ВСЁ ДАЛЬШЕ — В СКРОЛЛЕ ===
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m == 0 || n == 0) ...[
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FluentIcons.view_all,
                              size: 64,
                              color: FluentTheme.of(context).inactiveColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Добавьте типы войск для обеих сторон',
                              style: TextStyle(
                                color: FluentTheme.of(context).inactiveColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // === АДАПТИВНАЯ КОМПОНОВКА МАТРИЦ ===
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 700;

                          if (isNarrow) {
                            // ✅ ВЕРТИКАЛЬНЫЙ РЕЖИМ: все матрицы в одном потоке
                            return IntrinsicWidth(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Большая матрица: A vs B
                                  _buildUnitMatrixVertical(
                                      context, provider, true),
                                  const SizedBox(height: 24),

                                  // Большая матрица: B vs A
                                  _buildUnitMatrixVertical(
                                      context, provider, false),

                                  // Малая матрица тегов (если есть)
                                  if (tags.length >= 2) ...[
                                    const SizedBox(height: 24),
                                    const Divider(),
                                    const SizedBox(height: 24),
                                    _buildTagMatrixSection(
                                        context, provider, tags),
                                  ],
                                ],
                              ),
                            );
                          } else {
                            // ✅ ГОРИЗОНТАЛЬНЫЙ РЕЖИМ: две большие рядом + малая ниже
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ Две матрицы: без IntrinsicHeight, с Flexible
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start, // ← start вместо stretch
                                  children: [
                                    Flexible(
                                      // ← Flexible вместо Expanded
                                      flex: 1,
                                      fit: FlexFit
                                          .loose, // ← позволяет сжиматься по контенту
                                      child: _buildUnitMatrixHorizontal(
                                          context, provider, true),
                                    ),
                                    const SizedBox(width: 32),
                                    Flexible(
                                      flex: 1,
                                      fit: FlexFit.loose,
                                      child: _buildUnitMatrixHorizontal(
                                          context, provider, false),
                                    ),
                                  ],
                                ),
                                // Малая матрица тегов ниже (если есть)
                                if (tags.length >= 2) ...[
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 24),
                                  _buildTagMatrixSection(
                                      context, provider, tags),
                                ],
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // === КНОПКИ ===
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Кнопки
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Button(
                    onPressed: (m > 0 && n > 0 && tags.length > 1)
                        ? () => _syncFromTags(context, provider)
                        : null,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.sync),
                        SizedBox(width: 8),
                        Text('Применить матрицу по типам'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Button(
                    onPressed: (m > 0 && n > 0)
                        ? () => _resetMatrices(context, provider)
                        : null,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.refresh),
                        SizedBox(width: 8),
                        Text('Сбросить'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // InfoBar занимает оставшееся пространство
              // InfoBar с иконкой-подсказкой вместо длинного текста
              Expanded(
                child: InfoBar(
                  title: const Text('Справка'),
                  content: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Маленькая матрица задаёт значения по типам войск.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                  severity: InfoBarSeverity.info,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Маленькая матрица по тегам
  // ─────────────────────────────────────────────────────────────

  Widget _buildTagMatrixSection(
    BuildContext context,
    StateManager provider,
    List<String> tags,
  ) {
    return Padding(
      padding: const EdgeInsets.all(0.0),
      child: EffectivenessMatrix(
        matrix: _buildTagMatrixData(provider, tags),
        rowNames: tags,
        columnNames: tags,
        title: 'Матрица по типам войск',
        onCellChanged: (row, col, value) {
          final attackerTag = tags[row];
          final defenderTag = tags[col];

          // ✅ Обновляем ОБЕ матрицы тегов одинаковым значением:
          provider.updateTagAvsBCell(
              attackerTag, defenderTag, value); // для A→B
          provider.updateTagBvsACell(
              attackerTag, defenderTag, value); // для B→A
        },
      ),
    );
  }

  /// Вспомогательный метод: преобразует Map тегов в 2D-список
  List<List<double>> _buildTagMatrixData(
    StateManager provider,
    List<String> tags,
  ) {
    return List<List<double>>.generate(
      tags.length,
      (i) => List.generate(
        tags.length,
        (j) => provider.tagEffectivenessAvsB[tags[i]]?[tags[j]] ?? 1.0,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Большая матрица по юнитам для ВЕРТИКАЛЬНОГО режима
  // ─────────────────────────────────────────────────────────────

  Widget _buildUnitMatrixVertical(
    BuildContext context,
    StateManager provider,
    bool isAvsB,
  ) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: EffectivenessMatrix(
        matrix:
            isAvsB ? provider.effectivenessAvsB : provider.effectivenessBvsA,
        rowNames: isAvsB
            ? provider.sideA.map((u) => '${u.name} (${u.tag})').toList()
            : provider.sideB.map((u) => '${u.name} (${u.tag})').toList(),
        columnNames: isAvsB
            ? provider.sideB.map((u) => '${u.name} (${u.tag})').toList()
            : provider.sideA.map((u) => '${u.name} (${u.tag})').toList(),
        title: isAvsB ? 'A vs B (по отрядам)' : 'B vs A (по отрядам)',
        onCellChanged: (row, col, value) {
          if (isAvsB) {
            provider.updateAvsBCell(row, col, value);
          } else {
            provider.updateBvsACell(row, col, value);
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Большая матрица по юнитам для ГОРИЗОНТАЛЬНОГО режима
  // ─────────────────────────────────────────────────────────────

  Widget _buildUnitMatrixHorizontal(
    BuildContext context,
    StateManager provider,
    bool isAvsB,
  ) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        width: double.infinity,
        child: EffectivenessMatrix(
          matrix:
              isAvsB ? provider.effectivenessAvsB : provider.effectivenessBvsA,
          rowNames: isAvsB
              ? provider.sideA.map((u) => '${u.name} (${u.tag})').toList()
              : provider.sideB.map((u) => '${u.name} (${u.tag})').toList(),
          columnNames: isAvsB
              ? provider.sideB.map((u) => '${u.name} (${u.tag})').toList()
              : provider.sideA.map((u) => '${u.name} (${u.tag})').toList(),
          title: isAvsB ? 'A vs B (по отрядам)' : 'B vs A (по отрядам)',
          onCellChanged: (row, col, value) {
            if (isAvsB) {
              provider.updateAvsBCell(row, col, value);
            } else {
              provider.updateBvsACell(row, col, value);
            }
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Кнопки управления
  // ─────────────────────────────────────────────────────────────

  /// Синхронизирует полную матрицу с матрицей по тегам
  void _syncFromTags(BuildContext context, StateManager provider) {
    provider.syncEffectivenessFromTags();
    _showNotification(
        context, 'Матрица по отрядам обновлена значениями из матрицы по типам');
  }

  /// Сбрасывает матрицы к значениям по умолчанию
  void _resetMatrices(BuildContext context, StateManager provider) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Сброс матриц'),
        content: const Text(
          'Сбросить все значения матриц эффективности к 1.0?',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          Button(
            onPressed: () {
              Navigator.of(context).pop();
              provider.resetEffectivenessMatrices();
              _showNotification(
                  context, 'Матрицы сброшены к значениям по умолчанию');
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }

  /// Показывает уведомление
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
