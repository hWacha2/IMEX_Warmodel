// lib/widgets/total_force_graph.dart
import 'package:fluent_ui/fluent_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/simulation_results.dart';

/// Простой график суммарной численности (без интерактива)
class TotalForceGraph extends StatelessWidget {
  final SimulationResults results;
  final List<String> unitNamesA;
  final List<String> unitNamesB;

  const TotalForceGraph({
    super.key,
    required this.results,
    required this.unitNamesA,
    required this.unitNamesB,
  });

  /// Суммирует все типы войск стороны
  List<FlSpot> _getTotalForceSpots(List<List<double>> data) {
    final time = results.time;
    if (time.isEmpty || data.isEmpty) return [];

    final total = List<double>.filled(time.length, 0.0);
    for (final unitData in data) {
      for (var t = 0; t < time.length; t++) {
        total[t] += unitData[t];
      }
    }
    return time.asMap().entries.map((e) => FlSpot(e.value, total[e.key])).toList();
  }

  double _getMaxY() {
    final spotsA = _getTotalForceSpots(results.aCounts);
    final spotsB = _getTotalForceSpots(results.bCounts);
    final maxA = spotsA.isNotEmpty ? spotsA.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 0;
    final maxB = spotsB.isNotEmpty ? spotsB.map((s) => s.y).reduce((a, b) => a > b ? a : b) : 0;
    final max = maxA > maxB ? maxA : maxB;
    return max > 0 ? max * 1.05 : 10;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Суммарная численность', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: _getMaxY() / 5,
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
                        interval: results.time.isNotEmpty ? results.time.length / 5 : 1,
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
                        interval: _getMaxY() / 5,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(color: theme.inactiveColor, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: theme.resources.cardStrokeColorDefault)),
                  minX: 0,
                  maxX: results.time.isNotEmpty ? results.time.last : 10,
                  minY: 0,
                  maxY: _getMaxY(),
                  lineBarsData: [
                    // Сторона A — красная
                    LineChartBarData(
                      spots: _getTotalForceSpots(results.aCounts),
                      isCurved: false,
                      color: const Color(0xFFEF5350),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    // Сторона B — синяя
                    LineChartBarData(
                      spots: _getTotalForceSpots(results.bCounts),
                      isCurved: false,
                      color: const Color(0xFF42A5F5),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final isA = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isA ? 'A' : 'B'}: ${spot.y.toStringAsFixed(1)}',
                          TextStyle(color: isA ? const Color(0xFFEF5350) : const Color(0xFF42A5F5), fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Простая легенда без интерактива
            Wrap(
              spacing: 24,
              children: [
                _buildSimpleLegendItem('A (сумма)', const Color(0xFFEF5350), theme),
                _buildSimpleLegendItem('B (сумма)', const Color(0xFF42A5F5), theme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleLegendItem(String label, Color color, FluentThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 24, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: theme.resources.textFillColorPrimary)),
      ],
    );
  }
}