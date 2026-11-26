import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/branding_provider.dart';
import 'providers/gym_provider.dart';
import 'screens/change_password_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'theme/app_theme.dart';
import 'widgets/ui_components.dart';

import 'services/config.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppConfig.init();
  await PushNotificationService.init();

  // Set system navigation & status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const GymOSApp());
}

class GymOSApp extends StatelessWidget {
  const GymOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BrandingProvider()),
        ChangeNotifierProvider(create: (_) => GymProvider()),
      ],
      child: MaterialApp(
        onGenerateTitle: (ctx) {
          final name = Provider.of<BrandingProvider>(ctx, listen: false).gymName;
          return name.isEmpty ? 'Member' : '$name Member';
        },
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    if (!auth.isReady) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/gym_logo.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const IconBubble(
                  name: Icons.fitness_center,
                  size: 64,
                  color: AppColors.primary,
                  bg: AppColors.primarySoft,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isSignedIn) {
      if (auth.mustChangePassword) {
        return const ChangePasswordScreen(isForced: true);
      }
      return const MainNavigation();
    }

    return const LoginScreen();
  }
}
