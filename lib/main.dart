import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  runApp(const ScaFuelApp());
}

class ScaFuelApp extends StatefulWidget {
  const ScaFuelApp({super.key});

  @override
  State<ScaFuelApp> createState() => _ScaFuelAppState();
}

class _ScaFuelAppState extends State<ScaFuelApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) return;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          final app = MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'SCA Fuel',
            theme: themeProvider.getLightTheme(),
            darkTheme: themeProvider.getDarkTheme(),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              final content = Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/bus.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: const Color(0xFFF6F7F8).withValues(alpha: 0.94),
                    ),
                  ),
                  child ?? const SizedBox.shrink(),
                ],
              );
              final isTouchDevice = kIsWeb &&
                  (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS);
              if (!isTouchDevice) return content;
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                panEnabled: false,
                scaleEnabled: true,
                clipBehavior: Clip.hardEdge,
                alignment: Alignment.topLeft,
                child: content,
              );
            },
            home: const LoginScreen(),
          );
          return app;
        },
      ),
    );
  }
}
