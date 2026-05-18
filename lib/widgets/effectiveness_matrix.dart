import 'package:fluent_ui/fluent_ui.dart';
import 'matrix_cell.dart';

/// Виджет матрицы эффективности с точным выравниванием через Table
class EffectivenessMatrix extends StatelessWidget {
  final List<List<double>> matrix;
  final List<String> rowNames;
  final List<String> columnNames;
  final String title;
  final Function(int, int, double) onCellChanged;

  // ✅ Фиксированные размеры для точного выравнивания
  static const double _headerWidth = 120.0;  // Ширина заголовков строк
  static const double _cellWidth = 80.0;     // Ширина ячейки
  static const double _cellHeight = 40.0;    // Высота ячейки

  const EffectivenessMatrix({
    super.key,
    required this.matrix,
    required this.rowNames,
    required this.columnNames,
    required this.title,
    required this.onCellChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // ✅ Горизонтальный скролл для широких матриц
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildMatrixTable(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixTable(BuildContext context) {
    return Table(
      // ✅ Фиксированная ширина колонок — гарантия выравнивания
      columnWidths: {
        0: const FixedColumnWidth(_headerWidth), // Заголовки строк
        for (var i = 0; i < columnNames.length; i++)
          i + 1: const FixedColumnWidth(_cellWidth), // Ячейки данных
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // 🔹 Заголовок таблицы (названия столбцов)
        TableRow(
          children: [
            // Пустая ячейка в левом верхнем углу
            const SizedBox.shrink(),
            ...columnNames.map((name) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: SizedBox(
                height: _cellHeight,
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis, // ✅ Обрезаем длинные названия
                ),
              ),
            )),
          ],
        ),
        
        // 🔹 Строки матрицы
        ...matrix.asMap().entries.map((rowEntry) => TableRow(
          children: [
            // Заголовок строки (название типа войск)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                height: _cellHeight,
                child: Text(
                  
                  rowNames[rowEntry.key],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // Ячейки строки
            ...rowEntry.value.asMap().entries.map((cellEntry) => Padding(
              padding: const EdgeInsets.all(2.0), // ✅ Минимальный отступ
              child: SizedBox(
                height: _cellHeight,
                child: MatrixCell(
                  value: cellEntry.value,
                  onChanged: (value) => onCellChanged(
                    rowEntry.key, 
                    cellEntry.key, 
                    value,
                  ),
                ),
              ),
            )),
          ],
        )),
      ],
    );
  }
}