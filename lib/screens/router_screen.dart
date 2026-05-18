import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:window_plus/window_plus.dart';

// ignore: implementation_imports
import 'package:window_plus/src/common.dart' show WM_CAPTIONAREA;

import 'package:win32/win32.dart';

import 'dart:io';

import 'home_screen.dart';
import 'units_screen.dart';
import 'matrix_screen.dart';
import 'settings_screen.dart';
import 'results_screen.dart';
import '../services/file_service.dart';
import '../providers/statemanager.dart';
import '../utils/adaptive_breakpoints.dart';

import '../widgets/customtitlebar.dart';

class RouterScreen extends StatefulWidget {
  const RouterScreen({super.key});

  @override
  State<RouterScreen> createState() => _RouterScreenState();
}

class _RouterScreenState extends State<RouterScreen> {
  final _fileService = FileService();

  late final List<Widget> _screens = const [
    HomeScreen(),
    UnitsScreen(),
    MatrixScreen(),
    SettingsScreen(),
    ResultsScreen(),
  ];

  Future<void> _toggleMaximize() async {
    if (!Platform.isWindows) return;

    final isMax = await WindowPlus.instance.maximized;
    if (isMax) {
      await WindowPlus.instance.restore();
    } else {
      await WindowPlus.instance.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = AdaptiveBreakpoints.of(context);
    final isCompact = mode == AdaptiveMode.compact;

    return Consumer<StateManager>(
      // 👈 Добавляем Consumer
      builder: (context, stateManager, child) {
        return Stack(
          children: [
            NavigationView(
              key: const ValueKey("main_navigation"),
              titleBar: CustomTitleBar(
                backButton: const SizedBox.shrink(),
                isBackButtonEnabled: false,
                isBackButtonVisible: false,
                leftHeader: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Warmodel GUI',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                captionControls: WindowCaption(),
              ),
              pane: NavigationPane(
                toggleButtonPosition:
                    PaneToggleButtonPreferredPosition.titleBar,
                selected: stateManager.currentIndex, //
                onChanged: (i) => stateManager.navigateTo(i), //
                displayMode: isCompact
                    ? PaneDisplayMode.compact
                    : PaneDisplayMode.expanded,
                leading: const SizedBox.shrink(),
                items: [
                  PaneItem(
                    icon: const Icon(FluentIcons.home),
                    title: const Text('Главная'),
                    body: _screens[0],
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.people),
                    title: const Text('Войска'),
                    body: _screens[1],
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.view_all),
                    title: const Text('Матрица'),
                    body: _screens[2],
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.settings),
                    title: const Text('Параметры'),
                    body: _screens[3],
                  ),
                  PaneItem(
                    icon: const Icon(FluentIcons.line_chart),
                    title: const Text('Результаты'),
                    body: _screens[4],
                  ),
                ],
                footerItems: [
                  PaneItemAction(
                    icon: const Icon(FluentIcons.save),
                    title: const Text('Экспорт'),
                    onTap: () => _exportParams(context),
                  ),
                  PaneItemAction(
                    icon: const Icon(FluentIcons.open_file),
                    title: const Text('Импорт'),
                    onTap: () => _importParams(context),
                  ),
                ],
              ),
            ),
            //
            Positioned(
              left: 60, // Отступ после кнопки бургер-меню
              top: 0,
              right: 138, // До кнопок WindowCaption
              height: 32,
              child: GestureDetector(
                onDoubleTap: _toggleMaximize,
                onPanStart: (details) {
                  if (Platform.isWindows) {
                    PostMessage(WindowPlus.instance.hwnd, WM_CAPTIONAREA, 0, 0);
                  }
                },
                behavior: HitTestBehavior.translucent,
              ),
            )
          ],
        );
      },
    );
  }

  // -------------------------------
  // EXPORT / IMPORT
  // -------------------------------
  Future<void> _exportParams(BuildContext context) async {
    try {
      final params = context.read<StateManager>().getCombatParams();
      final saved = await _fileService.saveParams(params);
      if (!context.mounted) return;

      _showNotification(
        context,
        saved ? 'Параметры сохранены' : 'Отменено',
        severity: saved ? InfoBarSeverity.success : InfoBarSeverity.warning,
      );
    } catch (e) {
      if (!mounted) return;
      _showNotification(
        context,
        'Ошибка: $e',
        severity: InfoBarSeverity.error,
      );
    }
  }

  Future<void> _importParams(BuildContext context) async {
    try {
      final params = await _fileService.loadParams();
      if (!mounted || params == null) return;
      if (!context.mounted) return;
      context.read<StateManager>().loadFromParams(params);
      _showNotification(context, 'Параметры загружены');
    } catch (e) {
      if (!mounted) return;
      _showNotification(
        context,
        'Ошибка: $e',
        severity: InfoBarSeverity.error,
      );
    }
  }

  void _showNotification(
    BuildContext context,
    String message, {
    InfoBarSeverity severity = InfoBarSeverity.success,
  }) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        severity: severity,
        title: Text(severity == InfoBarSeverity.success ? 'Успешно' : 'Ошибка'),
        content: Text(message),
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
      ),
      duration: Duration(seconds: severity == InfoBarSeverity.error ? 4 : 2),
    );
  }
}
