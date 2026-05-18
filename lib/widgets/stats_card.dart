import 'package:fluent_ui/fluent_ui.dart';

/// Адаптивная карточка статистики
class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? color;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final typography = theme.typography;
    final textScaler = MediaQuery.of(context).textScaler;
    final scale = textScaler.scale(1.0).clamp(1.0, 1.5);
    
    return Card(
      child: Padding(
        // ✅ Адаптивные отступы
        padding: EdgeInsets.all(12 * scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок + иконка
            Row(
              children: [
                Icon(
                  icon,
                  color: color ?? theme.accentColor,
                  size: 20 * scale,
                ),
                SizedBox(width: 10 * scale),
                Expanded(
                  child: Text(
                    title,
                    // ✅ Используем системную типографику Fluent UI
                    style: typography.caption?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10 * scale),
            
            // Значение — главное, масштабируется
            Text(
              value,
              style: typography.title?.copyWith(
                fontWeight: FontWeight.w600,
                color: color ?? theme.resources.textFillColorPrimary,
                // ✅ Не даём тексту стать слишком большим
                fontSize: (20 * scale).clamp(16.0, 28.0),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Подзаголовок
            if (subtitle != null) ...[
              SizedBox(height: 4 * scale),
              Text(
                subtitle!,
                style: typography.caption?.copyWith(
                  color: theme.inactiveColor,
                  fontSize: (11 * scale).clamp(9.0, 14.0),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}