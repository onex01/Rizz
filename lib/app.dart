import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import 'core/notification/notification_service.dart';
import 'core/theme/theme_provider.dart';
import 'core/settings/settings_provider.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'shared/services/auth_service.dart';

class RizzApp extends StatelessWidget {
  const RizzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, _) {
          return MaterialApp(
            title: 'Rizz',
            debugShowCheckedModeBanner: false,
            theme: _applyTheme(themeProvider.lightTheme, settingsProvider),
            darkTheme: _applyTheme(themeProvider.darkTheme, settingsProvider),
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );

        },
      ),
    );
  }

  ThemeData _applyTheme(ThemeData base, SettingsProvider settings) {
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: settings.accentColor,
      ),
      textTheme: base.textTheme.copyWith(
        bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: settings.fontSize),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: settings.fontSize - 2),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: settings.fontSize + 4),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: settings.fontSize + 2),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = GetIt.I<AuthService>();
    final notificationService = GetIt.I<NotificationService>();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          final user = snapshot.data!;
          // Сохраняем FCM токен после входа
          notificationService.getToken().then((token) {
            if (token != null && user.uid.isNotEmpty) {
              authService.updateUserProfile(user.uid, {'fcmToken': token});
            }
          });

          if (user.emailVerified) {
            return const HomeScreen();
          } else {
            return const EmailVerificationScreen();
          }
        }
        return const AuthScreen();
      },
    );
  }
}

// Экран подтверждения email (можно взять из исходного кода)
class EmailVerificationScreen extends StatelessWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email_outlined, size: 80, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                'Подтвердите ваш email',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Письмо отправлено на\n${user.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await user.sendEmailVerification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Письмо отправлено повторно'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text('Отправить письмо ещё раз'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => GetIt.I<AuthService>().signOut(),
                child: const Text('Выйти из аккаунта'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}