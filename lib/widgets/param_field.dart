import 'package:fluent_ui/fluent_ui.dart';

/// Виджет поля ввода числового параметра
class ParamField extends StatefulWidget {
  final String label;
  final String? description;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isInteger;
  final double? minValue;
  final double? maxValue;
  final double step;
  final int decimalPlaces;

  const ParamField({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.onChanged,
    this.isInteger = false,
    this.minValue,
    this.maxValue,
    this.step = 0.01,
    this.decimalPlaces = 4,
  });

  @override
  State<ParamField> createState() => _ParamFieldState();
}

class _ParamFieldState extends State<ParamField> 
{
  late TextEditingController _controller;
  late FocusNode _focusNode; // ✅ Добавляем
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.isInteger
          ? widget.value.toInt().toString()
          : widget.value.toStringAsFixed(widget.decimalPlaces),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged); // ✅ Слушаем фокус
  }
  
  void _onFocusChanged() {
    // Когда поле теряет фокус — разрешаем внешние обновления
    if (!_focusNode.hasFocus) {
      _syncControllerToValue();
    }
  }
  
  // ✅ Синхронизируем контроллер с внешним значением
  void _syncControllerToValue() {
    final newText = widget.isInteger
        ? widget.value.toInt().toString()
        : widget.value.toStringAsFixed(widget.decimalPlaces);
    
    if (_controller.text != newText) {
      _controller.text = newText;
    }
  }

  @override
  void didUpdateWidget(covariant ParamField oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Обновляем контроллер только если поле НЕ в фокусе
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _syncControllerToValue();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

    void _validateAndNotify(String text) {
    final value = double.tryParse(text);
    if (value == null) {
      setState(() => _errorMessage = 'Некорректное значение');
      return;
    }

    if (widget.minValue != null && value < widget.minValue!) {
      setState(() => _errorMessage = 'Значение меньше минимального');
      return;
    }

    if (widget.maxValue != null && value > widget.maxValue!) {
      setState(() => _errorMessage = 'Значение больше максимального');
      return;
    }

    setState(() => _errorMessage = null);
    
    widget.onChanged(value);
  }



  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (widget.description != null) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: widget.description!,  // ← String, не Text
                  child: Icon(
                    FluentIcons.info,
                    size: 16,
                    color: FluentTheme.of(context).inactiveColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextBox(
            controller: _controller,
            focusNode: _focusNode, // ✅ Подключаем

            placeholder: 'Введите значение',  // ← String, не Text
            onChanged: _validateAndNotify,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: FluentTheme.of(context).accentColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}