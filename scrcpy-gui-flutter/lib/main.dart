import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1250, 900),
    center: true,
    backgroundColor: Color(0xFF0C0C0E),
    titleBarStyle: TitleBarStyle.hidden,
    title: 'Scrcpy GUI',
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const ScrcpyGuiApp(),
    ),
  );
}

class ScrcpyGuiApp extends StatelessWidget {
  const ScrcpyGuiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.theme;

    return MaterialApp(
      title: 'Scrcpy GUI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: theme.bgColor,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.dark(
          primary: theme.accentPrimary,
          secondary: theme.accentSecondary,
          surface: theme.surfaceColor,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
