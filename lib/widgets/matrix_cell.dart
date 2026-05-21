import 'package:fluent_ui/fluent_ui.dart';

class MatrixCell extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool isHighlighted;
  final String? tooltip;

  const MatrixCell({
    super.key,
    required this.value,
    required this.onChanged,
    this.isHighlighted = false,
    this.tooltip,
  });

  @override
  State<MatrixCell> createState() => _MatrixCellState();
}

class _MatrixCellState extends State<MatrixCell> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _isEditing = false;
        _controller.text = _formatValue(widget.value);
      });
    }
  }

  @override
  void didUpdateWidget(covariant MatrixCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  Color _getValueColor(double value) {
    if (value >= 10.0) return const Color(0xFFEF5350);
    if (value >= 5.0) return const Color(0xFFFFA726);
    if (value >= 1.0) return const Color(0xFF66BB6A);
    return const Color(0xFF9E9E9E);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return Tooltip(
      message: widget.tooltip ?? 'Эффективность: ${widget.value}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.isHighlighted
              ? theme.accentColor.withValues(alpha: 0.1)
              : theme.cardColor,
          border: Border.all(
            color: theme.resources.cardStrokeColorDefaultSolid,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 60,
            minHeight: 40,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: _isEditing
                ? TextBox(
                    controller: _controller,
                    focusNode: _focusNode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (text) {
                      final value = double.tryParse(text);
                      if (value != null) widget.onChanged(value);
                    },
                    onSubmitted: (_) {
                      final value = double.tryParse(_controller.text);
                      if (value != null) widget.onChanged(value);
                      setState(() {
                        _isEditing = false;
                        _controller.text = _formatValue(value ?? widget.value);
                      });
                      _focusNode.unfocus();
                    },
                  )
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => _isEditing = true);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _focusNode.requestFocus();
                      });
                    },
                    child: Center(
                      child: Text(
                        _formatValue(widget.value),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getValueColor(widget.value),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
