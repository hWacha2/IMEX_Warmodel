import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../models/simulation_results.dart';
import '../widgets/result_graph.dart';
import '../widgets/stats_card.dart';
import '../widgets/loading_overlay.dart';
import '../providers/statemanager.dart';
import 'dart:ffi';
import 'package:flutter/foundation.dart';
import '../services/simulation_service.dart';
import '../models/combat_params.dart';
import '../widgets/total_force_graph.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _selectedTab = 0;
  SimulationResults? _results;
  Pointer<Void>? _resultsPtr;

  bool _isSimulating = false;
  final _simService = SimulationService();

  void _showNotification(BuildContext context, String message,
      {InfoBarSeverity severity = InfoBarSeverity.success}) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        severity: severity,
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

  @override
  Widget build(BuildContext context) {
    // Получаем высоту экрана для расчета размера графика
    final screenHeight = MediaQuery.of(context).size.height;
    // График займет 75% высоты экрана, но не менее 400px и не более 800px
    final graphHeight = (screenHeight * 0.75).clamp(400.0, 800.0);

    return LoadingOverlay(
      isLoading: _isSimulating,
      message: 'Выполнение расчёта...',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;

                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Результаты моделирования',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          // кнопки под текстом, справа
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildRunButton(),
                                _buildExportButton(),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Результаты моделирования',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),

                          // кнопки справа в одну линию
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 8,
                            children: [
                              _buildRunButton(),
                              _buildExportButton(),
                            ],
                          ),
                        ],
                      );
              },
            ),

            // Заголовок и кнопки управления

            const SizedBox(height: 16),

            // Вкладки
            _buildTabSelector(),
            const SizedBox(height: 16),

            // ✅ СКРОЛЛИРУЕМАЯ ОБЛАСТЬ
            Expanded(
              child: _results == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(FluentIcons.line_chart,
                              size: 64,
                              color: FluentTheme.of(context).inactiveColor),
                          const SizedBox(height: 16),
                          Text(
                            'Запустите моделирование для просмотра результатов',
                            style: TextStyle(
                                color: FluentTheme.of(context).inactiveColor,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: graphHeight,
                            child: _buildGraphForTab(_selectedTab),
                          ),

                          const SizedBox(height: 24),

                          // ✅ СТАТИСТИКА: Ниже графика
                          const Text(
                            'Статистика боя',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          _buildStatsPanel(),

                          // Дополнительный отступ снизу для удобства скролла
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunButton() {
    return Button(
      onPressed: _isSimulating ? null : _runSimulation,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.play),
          SizedBox(width: 8),
          Text('Запустить'),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Button(
      onPressed: _results != null ? () => _exportCsv(context) : null,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.export),
          SizedBox(width: 8),
          Text('Экспорт CSV'),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Wrap(
        spacing: 4,
        children: [
          ToggleButton(
            checked: _selectedTab == 0,
            onChanged: (checked) {
              if (checked) setState(() => _selectedTab = 0);
            },
            child: const Text('Общая'),
          ),
          ToggleButton(
            checked: _selectedTab == 1,
            onChanged: (checked) {
              if (checked) setState(() => _selectedTab = 1);
            },
            child: const Text('По типам'),
          ),
          ToggleButton(
            checked: _selectedTab == 2,
            onChanged: (checked) {
              if (checked) setState(() => _selectedTab = 2);
            },
            child: const Text('Мораль'),
          ),
          ToggleButton(
            checked: _selectedTab == 3,
            onChanged: (checked) {
              if (checked) setState(() => _selectedTab = 3);
            },
            child: const Text('Снабжение'),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphForTab(int tab) {
    switch (tab) {
      case 0:
        return TotalForceGraph(
          results: _results!,
          unitNamesA:
              context.read<StateManager>().sideA.map((u) => u.name).toList(),
          unitNamesB:
              context.read<StateManager>().sideB.map((u) => u.name).toList(),
        );
      case 1:
      case 2:
      case 3:
        return ResultGraph(
          results: _results!,
          unitNamesA:
              context.read<StateManager>().sideA.map((u) => u.name).toList(),
          unitNamesB:
              context.read<StateManager>().sideB.map((u) => u.name).toList(),
          graphType: tab - 1,
        );
      default:
        return const SizedBox.shrink();
    }
  }

Widget _buildStatsPanel() {
  // Используем Wrap для адаптивности карточек
  return Wrap(
    spacing: 16,
    runSpacing: 16,
    children: [
      // ─────────────────────────────────────────────────────
      // 📊 Основные метрики
      // ─────────────────────────────────────────────────────
      SizedBox(
        width: 200,
        child: StatsCard(
          title: 'Время счета',
          value: '${_results!.executionTimeMs.toStringAsFixed(2)} мс',
          icon: FluentIcons.timer,
        ),
      ),
      
      // ➕ НОВАЯ: Среднее итераций Ньютона
      SizedBox(
        width: 200,
        child: StatsCard(
          title: 'Среднее итераций',
          value: _results!.avgNewtonIterations.toStringAsFixed(2),
          subtitle: 'на шаг времени',
          icon: FluentIcons.chart_series,
          color: _getConvergenceColor(_results!.avgNewtonIterations),
        ),
      ),
      
      // ➕ НОВАЯ: Максимум итераций Ньютона
      SizedBox(
        width: 200,
        child: StatsCard(
          title: 'Макс. итераций',
          value: _results!.maxNewtonIterations.toString(),
          subtitle: 'пиковое значение',
          icon: FluentIcons.sort_up,
          color: _results!.maxNewtonIterations > 50 
              ? const Color(0xFFFFB74D)  // оранжевый для тревоги
              : const Color(0xFF66BB6A),  // зелёный для нормы
        ),
      ),
      
      // ➕ НОВАЯ: Сбои сходимости
      SizedBox(
        width: 200,
        child: StatsCard(
          title: 'Сбои сходимости',
          value: _results!.convergenceFailures.toString(),
          subtitle: _results!.convergenceFailures == 0 
              ? '✓ Все шаги сошлись' 
              : '⚠ Требует внимания',
          icon: _results!.convergenceFailures == 0 
              ? FluentIcons.check_mark 
              : FluentIcons.error,
          color: _results!.convergenceFailures == 0 
              ? const Color(0xFF66BB6A) 
              : const Color(0xFFEF5350),
        ),
      ),
      
      // ─────────────────────────────────────────────────────
      // ⚔️ Силы сторон
      // ─────────────────────────────────────────────────────
      SizedBox(
        width: 200,
        child: StatsCard(
          title: 'Силы A',
          value: _results!.finalForceA.toStringAsFixed(1),
          subtitle: 'Изначально: ${_results!.initialForceA.toStringAsFixed(1)}',
          icon: FluentIcons.shield,
          color: const Color(0xFFEF5350),
        ),
      ),
      SizedBox(
        width: 200,
        child: StatsCard(
          title: 'Силы B',
          value: _results!.finalForceB.toStringAsFixed(1),
          subtitle: 'Изначально: ${_results!.initialForceB.toStringAsFixed(1)}',
          icon: FluentIcons.shield,
          color: const Color(0xFF42A5F5),
        ),
      ),
      
      // ─────────────────────────────────────────────────────
      // 🏆 Итог
      // ─────────────────────────────────────────────────────
      SizedBox(
        width: 200,
        child: StatsCard(
          title: 'Победитель',
          value: _results!.winner == 1
              ? 'A'
              : _results!.winner == 2
                  ? 'B'
                  : 'Ничья',
          icon: FluentIcons.favorite_star,
          color: const Color(0xFFFFA726),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// 🎨 Вспомогательный метод: цвет в зависимости от качества сходимости
// ─────────────────────────────────────────────────────────────
Color _getConvergenceColor(double avgIters) {
  if (avgIters < 5) return const Color(0xFF43A047);   // тёмно-зелёный: отлично
  if (avgIters < 10) return const Color(0xFF66BB6A);   // зелёный: хорошо
  if (avgIters < 20) return const Color(0xFFFFB74D);   // оранжевый: терпимо
  return const Color(0xFFEF5350);                       // красный: плохо
}
  Future<void> _runSimulation() async {
    setState(() => _isSimulating = true);

    try {
      final provider = context.read<StateManager>();

      if (provider.sideA.isEmpty || provider.sideB.isEmpty) {
        throw Exception('Добавьте типы войск для обеих сторон');
      }

      final params = provider.getCombatParams();

      final resultWithPtr = await compute((CombatParams p) {
        final service = SimulationService();
        return service.runWithPointer(p);
      }, params);

      if (!mounted) return;

      setState(() {
        _results = resultWithPtr.results;
        _resultsPtr = resultWithPtr.nativePtr;
        _isSimulating = false;
      });
      _showNotification(context,
          'Моделирование завершено за ${_results!.executionTimeMs.toStringAsFixed(2)} мс');
    } catch (e, stack) {
      debugPrint('❌ Simulation error: $e\n$stack');
      if (!mounted) return;
      setState(() => _isSimulating = false);
      _showNotification(
        context,
        'Ошибка расчёта: ${e.toString()}',
        severity: InfoBarSeverity.error,
      );
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    if (_resultsPtr == null) {
      if (!mounted) return;
      _showNotification(context, 'Нет данных для экспорта',
          severity: InfoBarSeverity.warning);
      return;
    }

    try {
      final provider = context.read<StateManager>();
      final namesA = provider.sideA.map((u) => u.name).toList();
      final namesB = provider.sideB.map((u) => u.name).toList();

      final success =
          await _simService.exportResultsToCsv(_resultsPtr!, namesA, namesB);

      if (!context.mounted) return;

      if (success) {
        _showNotification(context, 'Результаты экспортированы в CSV');
      } else {
        throw Exception('Не удалось записать файл');
      }
    } catch (e) {
      if (!mounted) return;
      _showNotification(
        context,
        'Ошибка экспорта: ${e.toString()}',
        severity: InfoBarSeverity.error,
      );
    }
  }
}
