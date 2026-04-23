import 'package:Rizz/shared/services/audio_player_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/logger/app_logger.dart';
import 'core/notification/notification_service.dart';
import 'shared/services/message_listener_service.dart';
import 'shared/services/firestore_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await setupServiceLocator();

  final logger = GetIt.I<AppLogger>();
  await logger.init();

  // Загружаем username текущего пользователя (если уже авторизован)
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    try {
      final fs = GetIt.I<FirestoreService>();
      final doc = await fs.getUser(currentUser.uid);
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final username = data?['username'] as String?;
        if (username != null && username.isNotEmpty) {
          logger.setUsername(username);
        }
      }
    } catch (_) {
      // не критично – логи будут без username
    }
  }

  // === ИНИЦИАЛИЗАЦИЯ АУДИО ===
  try {
    final audioService = GetIt.I<AudioPlayerService>();
    await audioService.init();
    logger.info('✅ AudioPlayerService initialized successfully');
  } catch (e, stack) {
    logger.error('❌ Failed to init AudioPlayerService', error: e, stack: stack);
  }

  // Deep links
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'rizz' && uri.host == 'profile') {
      // обработка профиля
    }
  });

  // Глобальные обработчики ошибок
  FlutterError.onError = (details) {
    logger.error('Flutter error', error: details.exception, stack: details.stack);
    if (kDebugMode) FlutterError.dumpErrorToConsole(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('!!! Uncaught async error: $error');
    logger.error('Uncaught async error', error: error, stack: stack);
    return true;
  };

  final notificationService = GetIt.I<NotificationService>();
  await notificationService.initialize();

  final messageListener = GetIt.I<MessageListenerService>();
  messageListener.startListening();

  runApp(const RizzApp());
}