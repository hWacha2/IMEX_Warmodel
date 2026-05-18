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

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Матрицы эффективности',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
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
            // ✅ АДАПТИВНАЯ КОМПОНОВКА: горизонтально на широких, вертикально на узких
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Порог переключения: 900px (можно настроить)
                  final isNarrow = constraints.maxWidth < 600;

                  return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final fade = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    );

                    final scale = Tween<double>(
                      begin: 0.97,
                      end: 1.0,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ));

                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.01),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ));

                    return FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: slide,
                        child: ScaleTransition(
                          scale: scale,
                          child: child,
                        ),
                      ),
                    );
                  },
                  
                  child: isNarrow
                      ? _buildVerticalLayout(context, provider)
                      : _buildHorizontalLayout(context, provider),
                );


                  
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
          const InfoBar(
            title: Text('Справка'),
            content: Text(
              'Матрица показывает эффективность атаки типа войск строки против типа войск столбца. '
              'Значение > 1 означает повышенную эффективность, < 1 — пониженную.',
            ),
          ),
          const SizedBox(height: 16),
          Button(
            onPressed: (m > 0 && n > 0) ? () => _resetMatrices(context) : null,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.refresh),
                SizedBox(width: 8),
                Text('Сбросить матрицы'),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildVerticalLayout(BuildContext context, StateManager provider) {
    return SingleChildScrollView(
      key: const ValueKey('vertical'),
      child: Column(
        children: [
          _buildSingleMatrix(context, provider, true),
          const SizedBox(height: 24),
          _buildSingleMatrix(context, provider, false),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout(BuildContext context, StateManager provider) {
    return Row(
      key: const ValueKey('horizontal'),
      children: [
        Expanded(child: _buildSingleMatrix(context, provider, true)),
        const SizedBox(width: 32),
        Expanded(child: _buildSingleMatrix(context, provider, false)),
      ],
    );
  }

  // ✅ Хелпер для отрисовки одной матрицы
  Widget _buildSingleMatrix(
    BuildContext context,
    StateManager provider,
    bool isAvsB,
  ) {
    return AspectRatio(
      aspectRatio: 1, // ← делает область квадратной
      child: EffectivenessMatrix(
        matrix:
            isAvsB ? provider.effectivenessAvsB : provider.effectivenessBvsA,
        rowNames: isAvsB
            ? provider.sideA.map((u) => u.name).toList()
            : provider.sideB.map((u) => u.name).toList(),
        columnNames: isAvsB
            ? provider.sideB.map((u) => u.name).toList()
            : provider.sideA.map((u) => u.name).toList(),
        title: isAvsB ? 'A vs B' : 'B vs A',
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

  void _resetMatrices(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Сброс матриц'),
        content: const Text(
          'Вы уверены, что хотите сбросить все значения матриц эффективности к 1.0?',
        ),
        actions: [
          Button(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<StateManager>().resetEffectivenessMatrices();
              _showNotification(
                  context, 'Матрицы сброшены к значениям по умолчанию');
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
