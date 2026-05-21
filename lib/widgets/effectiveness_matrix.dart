import 'package:fluent_ui/fluent_ui.dart';
import 'matrix_cell.dart';

class EffectivenessMatrix extends StatelessWidget {
  final List<List<double>> matrix;
  final List<String> rowNames;
  final List<String> columnNames;
  final String title;
  final Function(int, int, double) onCellChanged;

  // ✅ Ограничения для контента ячеек
  static const double _headerMaxWidth = 110.0;
  static const double _cellMaxWidth = 80.0;
  static const double _cellMinHeight = 40.0;

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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 800),
                child: _buildMatrixTable(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrixTable(BuildContext context) {
    return Table(
      // ✅ IntrinsicColumnWidth() без параметров — ширина по контенту
      columnWidths: {
        0: const FixedColumnWidth(_headerMaxWidth),
        for (var i = 0; i < columnNames.length; i++)
          i + 1: const FixedColumnWidth(_cellMaxWidth),
      },

      defaultVerticalAlignment: TableCellVerticalAlignment.top,
      children: [
        // 🔹 Заголовки столбцов
        TableRow(
          children: [
            const SizedBox.shrink(),
            ...columnNames.map((name) => _buildConstrainedCell(
                  child: Text(
                    name,
                    softWrap: true,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  isHeader: true,
                )),
          ],
        ),

        // 🔹 Строки матрицы
        ...matrix.asMap().entries.map((rowEntry) => TableRow(
              children: [
                // Заголовок строки
                _buildConstrainedCell(
                  child: Text(
                    rowNames[rowEntry.key],
                    softWrap: true,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  isHeader: true,
                ),
                // Ячейки с данными
                ...rowEntry.value.asMap().entries.map((cellEntry) => Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: MatrixCell(
                        value: cellEntry.value,
                        onChanged: (value) => onCellChanged(
                          rowEntry.key,
                          cellEntry.key,
                          value,
                        ),
                      ),
                    )),
              ],
            )),
      ],
    );
  }

  Widget _buildConstrainedCell({
    required Widget child,
    required bool isHeader,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: _cellMinHeight,
        ),
        child: child,
      ),
    );
  }
}
