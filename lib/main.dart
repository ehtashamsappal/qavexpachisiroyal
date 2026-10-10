import 'package:flutter/material.dart';

import 'engine/game_controller.dart';
import 'models/game_theme.dart';
import 'models/meta.dart';
import 'screens/about_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/how_to_play_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/mode_select_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/themes_screen.dart';
import 'services/audio_service.dart';
import 'services/storage.dart';
import 'widgets/royal_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await AppState.load();
  await AudioService().init(soundOn: app.soundOn, musicOn: app.musicOn);
  runApp(PachisiRoyalApp(app: app));
}

class PachisiRoyalApp extends StatelessWidget {
  final AppState app;
  const PachisiRoyalApp({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final theme = themeOf(app, gameThemes);
        return MaterialApp(
          title: 'Qavex Pachisi Royal',
          debugShowCheckedModeBanner: false,
          theme: theme.material,
          builder: (context, child) {
            // Accessibility: optional larger text scaling.
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(app.largeText ? 1.25 : 1.0),
              ),
              child: child!,
            );
          },
          initialRoute: '/splash',
          onGenerateRoute: (settings) {
            Widget page;
            switch (settings.name) {
              case '/splash':
                page = SplashScreen(app: app);
                break;
              case '/home':
                page = HomeScreen(app: app);
                break;
              case '/modes':
                page = ModeSelectScreen(app: app);
                break;
              case '/levels':
                final args = settings.arguments as Map<String, dynamic>?;
                var mode = args?['mode'] as GameMode?;
                if (args?['preselect'] == 'tournament') {
                  mode = GameMode.tournament;
                }
                page = LevelSelectScreen(app: app, mode: mode ?? GameMode.classicRoyal);
                break;
              case '/game':
                final config = settings.arguments as MatchConfig;
                page = GameScreen(app: app, config: config);
                break;
              case '/shop':
                page = ShopScreen(app: app);
                break;
              case '/settings':
                page = SettingsScreen(app: app);
                break;
              case '/themes':
                page = ThemesScreen(app: app);
                break;
              case '/profile':
                page = ProfileScreen(app: app);
                break;
              case '/stats':
                page = StatsScreen(app: app);
                break;
              case '/howto':
                page = HowToPlayScreen(app: app);
                break;
              case '/about':
                page = AboutScreen(app: app);
                break;
              default:
                page = HomeScreen(app: app);
            }
            return MaterialPageRoute(
              builder: (_) => page,
              settings: settings,
            );
          },
        );
      },
    );
  }
}
