import 'package:fluent_ui/fluent_ui.dart';
import '../providers/statemanager.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:io';
import 'package:video_player/video_player.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // ← обязательно
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    _controller =
        VideoPlayerController.file(File("assets/videos/bg-anim3.mp4"));

    await _controller!.initialize();
    _controller!.setVolume(0.0);

    _controller!.setLooping(true);
  
    _controller!.play();

    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final useVideo = context.read<StateManager>().useVideoBackground;

    if (_controller == null) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // вкладка/окно неактивно → ставим на паузу
      if (_controller!.value.isPlaying) _controller!.pause();
    }

    if (state == AppLifecycleState.resumed) {
      // вернулись → продолжаем, если включено
      if (useVideo && !_controller!.value.isPlaying) _controller!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final useVideo = context.watch<StateManager>().useVideoBackground;

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: Stack(
        children: [
          // 🔥 Фон: видео или картинка
          Positioned.fill(
            child: useVideo &&
                    _controller != null &&
                    _controller!.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/bg.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
          ),

          // Затемнение
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
            ),
          ),

          // Контент
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                constraints: const BoxConstraints(maxWidth: 520),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Добро пожаловать',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Warmodel GUI — инструмент для моделирования боевых действий. '
                          'Настройте параметры, задайте состав войск и получите результат расчёта.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.95),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: () {
                            context.read<StateManager>().navigateTo(1);
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Начать работу'),
                              SizedBox(width: 8),
                              Icon(FluentIcons.chevron_right, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Row(
              children: [
                Text(
                  'Анимация',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                ToggleSwitch(
                  checked: useVideo,
                  onChanged: (value) {
                    context.read<StateManager>().toggleBackground(value);

                    if (!value && _controller != null) {
                      _controller!.pause();
                    }
                    if (value &&
                        _controller != null &&
                        !_controller!.value.isPlaying) {
                      _controller!.play();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
