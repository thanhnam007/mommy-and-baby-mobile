import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/activity_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/baby_provider.dart';
import 'providers/camera_provider.dart';
import 'providers/growth_provider.dart';
import 'providers/media_provider.dart';
import 'providers/pumping_provider.dart';
import 'providers/reminder_provider.dart';
import 'providers/theme_provider.dart';
import 'views/auth/login_view.dart';
import 'views/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(const MommyBabyApp());
}

class MommyBabyApp extends StatelessWidget {
  const MommyBabyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BabyProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => GrowthProvider()),
        ChangeNotifierProvider(create: (_) => CameraProvider()),
        ChangeNotifierProvider(create: (_) => PumpingProvider()),
        ChangeNotifierProvider(create: (_) => ReminderProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProv, authProv, _) {
          return MaterialApp(
            title: 'Mommy & Baby',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProv.themeMode,
            home: authProv.isAuthenticated ? const MainLayout() : const LoginView(),
          );
        },
      ),
    );
  }
}
