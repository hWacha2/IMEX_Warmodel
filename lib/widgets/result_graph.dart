// lib/widgets/result_graph.dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../models/simulation_results.dart';

/// График с детализацией по типам войск + интерактивная легенда
class ResultGraph extends StatefulWidget {
  final SimulationResults results;
  final List<String> unitNamesA;
  final List<String> unitNamesB;
  final int graphType; // 0=численность, 1=мораль, 2=снабжение

  const ResultGraph({
    super.key,
    required this.results,
    required this.unitNamesA,
    required this.unitNamesB,
    this.graphType = 0,
  });

  @override
  State<ResultGraph> createState() => _ResultGraphState();
}

class _ResultGraphState extends State<ResultGraph> {
  // ✅ Состояние видимости для каждого типа войск
  late Map<int, bool> _visibleA;
  late Map<int, bool> _visibleB;

  @override
  void initState() {
    super.initState();
    _visibleA = {for (var i = 0; i < widget.unitNamesA.length; i++) i: true};
    _visibleB = {for (var i = 0; i < widget.unitNamesB.length; i++) i: true};
  }

  /// Переключает видимость типа войск
  void _toggleVisibility(bool isSideA, int index) {
    setState(() {
      if (isSideA) {
        _visibleA[index] = !(_visibleA[index] ?? true);
      } else {
        _visibleB[index] = !(_visibleB[index] ?? true);
      }
    });
  }

  /// 🎨 Генерация оттенков цвета (основной цвет + вариации яркости)
  Color _getVariantColor(Color baseColor, int index, int totalCount) {
    if (totalCount <= 1) return baseColor;
    
    // Разброс яркости: от -0.3 до +0.3 относительно базового
    final factor = -0.3 + (index / (totalCount - 1)) * 0.6;
    final hsl = HSLColor.fromColor(baseColor);
    
    // Меняем lightness, сохраняем hue и saturation
    final newLightness = math.max(0.2, math.min(0.9, hsl.lightness + factor * 0.3));
    
    return hsl.withLightness(newLightness).toColor();
  }

  /// Получает данные для графика с учётом видимости
  List<FlSpot>? _getDataForSide(int index, bool isSideA) {
    if (isSideA && !(_visibleA[index] ?? true)) return null;
    if (!isSideA && !(_visibleB[index] ?? true)) return null;

    final List<List<double>> data = isSideA
        ? (widget.graphType == 0 ? widget.results.aCounts : widget.graphType == 1 ? widget.results.aMorale : widget.results.aSupply)
        : (widget.graphType == 0 ? widget.results.bCounts : widget.graphType == 1 ? widget.results.bMorale : widget.results.bSupply);

    if ( index >= data.length) return null;

    return widget.results.time.asMap().entries.map((entry) {
      return FlSpot(entry.value, data[index][entry.key]);
    }).toList();
  }

  double _getGridInterval() => _getMaxY() / 5;

  double _getMaxY() {
    switch (widget.graphType) {
      case 1: // мораль
      case 2: // снабжение
        return 1.0;
      default: // численность
        double maxA = 0, maxB = 0;
        for (var i = 0; i < (widget.results.aCounts.length); i++) {
          if (_visibleA[i] ?? true) {
            final m = widget.results.aCounts[i].reduce((a, b) => a > b ? a : b);
            if (m > maxA) maxA = m;
          }
        }
        for (var i = 0; i < (widget.results.bCounts.length); i++) {
          if (_visibleB[i] ?? true) {
            final m = widget.results.bCounts[i].reduce((a, b) => a > b ? a : b);
            if (m > maxB) maxB = m;
          }
        }
        final max = maxA > maxB ? maxA : maxB;
        return max > 0 ? max * 1.1 : 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    // Базовые цвета сторон
    const baseColorA = Color(0xFFEF5350);
    const baseColorB = Color(0xFF42A5F5);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGraphTitle(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _getGridInterval(),
                    verticalInterval: widget.results.time.isNotEmpty ? widget.results.time.length / 5 : 1,
                    getDrawingHorizontalLine: (_) => FlLine(color: theme.resources.cardStrokeColorDefault, strokeWidth: 1),
                    getDrawingVerticalLine: (_) => FlLine(color: theme.resources.cardStrokeColorDefault, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: widget.results.time.isNotEmpty ? widget.results.time.length / 5 : 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 2 != 0) return const Text('');
                          return Text(value.toStringAsFixed(1), style: TextStyle(color: theme.inactiveColor, fontSize: 12));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        interval: _getGridInterval(),
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(color: theme.inactiveColor, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: theme.resources.cardStrokeColorDefault)),
                  minX: 0,
                  maxX: widget.results.time.isNotEmpty ? widget.results.time.last : 10,
                  minY: 0,
                  maxY: _getMaxY(),
                  lineBarsData: _buildLineBars(baseColorA, baseColorB),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                      final isA = spot.barIndex < widget.unitNamesA.length;
                      final names = isA ? widget.unitNamesA : widget.unitNamesB;
                      final idx = isA ? spot.barIndex : spot.barIndex - widget.unitNamesA.length;
                      final name = idx < names.length ? names[idx] : (isA ? 'A' : 'B');
                      
                      // ✅ Вычисляем тот же цвет, что использовался при построении линии
                      final baseColor = isA ? const Color(0xFFEF5350) : const Color(0xFF42A5F5);
                      final color = _getVariantColor(baseColor, idx, isA ? widget.unitNamesA.length : widget.unitNamesB.length);
                      
                      return LineTooltipItem('$name: ${spot.y.toStringAsFixed(1)}', TextStyle(color: color, fontWeight: FontWeight.bold));
                    }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            _buildInteractiveLegend(baseColorA, baseColorB, theme),
          ],
        ),
      ),
    );
  }

  String _getGraphTitle() {
    switch (widget.graphType) {
      case 1: return 'Динамика морали';
      case 2: return 'Динамика снабжения';
      default: return 'Динамика численности';
    }
  }

  List<LineChartBarData> _buildLineBars(Color baseA, Color baseB) {
    final bars = <LineChartBarData>[];
    
    // Сторона A
    for (var i = 0; i < widget.results.aCounts.length; i++) {
      final spots = _getDataForSide(i, true);
      if (spots != null && spots.isNotEmpty) {
        bars.add(LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _getVariantColor(baseA, i, widget.unitNamesA.length),
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ));
      }
    }
    
    // Сторона B
    for (var i = 0; i < widget.results.bCounts.length; i++) {
      final spots = _getDataForSide(i, false);
      if (spots != null && spots.isNotEmpty) {
        bars.add(LineChartBarData(
          spots: spots,
          isCurved: true,
          color: _getVariantColor(baseB, i, widget.unitNamesB.length),
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ));
      }
    }
    
    return bars;
  }

  /// Интерактивная легенда с переключением видимости
  Widget _buildInteractiveLegend(Color baseA, Color baseB, FluentThemeData theme) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        // Сторона A
        ...widget.unitNamesA.asMap().entries.map((e) => _buildToggleItem(
          e.value,
          _getVariantColor(baseA, e.key, widget.unitNamesA.length),
          true,
          e.key,
          theme,
          isVisible: _visibleA[e.key] ?? true,
        )),
        // Сторона B
        ...widget.unitNamesB.asMap().entries.map((e) => _buildToggleItem(
          e.value,
          _getVariantColor(baseB, e.key, widget.unitNamesB.length),
          false,
          e.key,
          theme,
          isVisible: _visibleB[e.key] ?? true,
        )),
      ],
    );
  }

  Widget _buildToggleItem(String label, Color color, bool isSideA, int index, FluentThemeData theme, {required bool isVisible}) {
    return GestureDetector(
      onTap: () => _toggleVisibility(isSideA, index),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: isVisible ? color : color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isVisible ? theme.resources.textFillColorPrimary : theme.inactiveColor,
              decoration: isVisible ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}