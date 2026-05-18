import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:window_plus/window_plus.dart'; // ✅ Импорт WindowPlus
import 'dart:io';

import 'providers/statemanager.dart';
import 'screens/router_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await WindowPlus.ensureInitialized(
      application: 'warmodel',
      enableCustomFrame: true,
      enableEventStreams: false,
    );

    await WindowPlus.instance.setMinimumSize(const Size(515, 330));

    // 5. Показываем окно
    await WindowPlus.instance.show();
  
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StateManager()),
      ],
      child: const CombatModelApp(),
    ),
  );
}

class CombatModelApp extends StatelessWidget {
  const CombatModelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'Моделирование боевых действий',
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue,
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue,
      ),
      themeMode: ThemeMode.system,
      home: const RouterScreen(),
    );
  }
}