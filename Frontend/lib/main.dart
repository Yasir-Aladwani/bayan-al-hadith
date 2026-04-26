import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'utils/app_font.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/user_provider.dart';
import 'providers/admin_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const HudAIApp());
}

class HudAIApp extends StatelessWidget {
  const HudAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'HudAI',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(false, settings.fontFamily),
            darkTheme: _buildTheme(true, settings.fontFamily, settings.isAmoled),
            themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(settings.fontScale),
              ),
              child: child!,
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(bool dark, String fontFamily, [bool amoled = false]) {
    const primary = Color(0xFFC4A882);
    final bg   = amoled ? Colors.black           : (dark ? const Color(0xFF1A1108) : const Color(0xFFFAF8F5));
    final card = amoled ? const Color(0xFF0D0D0D) : (dark ? const Color(0xFF2D1F10) : const Color(0xFFEDE8E0));
    final text    = dark ? const Color(0xFFF2E8D9) : const Color(0xFF3D2B1F);
    final muted   = dark ? const Color(0xFF9E8468) : const Color(0xFF8B7355);

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: primary,
        onSecondary: Colors.white,
        surface: bg,
        onSurface: text,
        error: Colors.red,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: card,
      dividerColor: dark ? const Color(0xFF4A3520) : const Color(0xFFD4C9BC),
      textTheme: appTextTheme(fontFamily,
        TextTheme(
          displayLarge: TextStyle(color: text, fontWeight: FontWeight.w700),
          bodyLarge: TextStyle(color: text),
          bodyMedium: TextStyle(color: muted),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: text,
        elevation: 0,
      ),
    );
  }
}
