import 'dart:ui';
import 'dart:convert';
import 'package:rizz/shared/services/audio_player_service.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/logger/app_logger.dart';
import 'core/notification/notification_service.dart';
import 'shared/services/message_listener_service.dart';
import 'shared/services/firestore_service.dart';
import 'shared/services/cache_service.dart';
import 'firebase_options.dart';

// ======================================================
// ГЛОБАЛЬНЫЙ ОБРАБОТЧИК ДЛЯ ФОНОВЫХ УВЕДОМЛЕНИЙ
// ======================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Инициализируем Firebase (обязательно в изоляте)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // 2. Инициализируем DI (чтобы получить сервисы)
  await setupServiceLocator();
  
  final logger = GetIt.I<AppLogger>();
  logger.info('📩 Фоновое уведомление: ${message.messageId}');
  
  final notificationService = GetIt.I<NotificationService>();
  final title = message.notification?.title ?? 'Новое сообщение';
  final body = message.notification?.body ?? '';
  final payload = jsonEncode(message.data);
  final cache = GetIt.I<MessageFileCache>();
  await cache.init();
  
  await notificationService.showLocalNotification(
    title: title,
    body: body,
    payload: payload,
  );
}

bool isMobilePlatform() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Кэш изображений
  PaintingBinding.instance.imageCache.maximumSize = 200;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // DI
  await setupServiceLocator();

  // ✅ Регистрируем обработчик фоновых уведомлений ДО runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Google Sign‑In только на мобильных и веб
  if (isMobilePlatform()) {
    try {
      await GoogleSignIn.instance.initialize(
        clientId: '931475441186-h5gh1fo9hn6v3e2cddj2dq689m624qpd.apps.googleusercontent.com',
      );
    } catch (_) {}
  }

  final logger = GetIt.I<AppLogger>();
  await logger.init();

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
    } catch (_) {}
  }

  try {
    final audioService = GetIt.I<AudioPlayerService>();
    await audioService.init();
    logger.info('✅ AudioPlayerService initialized');
  } catch (e, stack) {
    logger.error('❌ AudioPlayerService init failed', error: e, stack: stack);
  }

  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'rizz' && uri.host == 'profile') {
      // TODO: открыть профиль
    }
  });

  FlutterError.onError = (details) {
    logger.error('Flutter error', error: details.exception, stack: details.stack);
    if (kDebugMode) FlutterError.dumpErrorToConsole(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('!!! Uncaught async error: $error');
    logger.error('Uncaught async error', error: error, stack: stack);
    return true;
  };

  runApp(const RizzApp());

  // После запуска – инициализируем уведомления и слушатель сообщений
  final notificationService = GetIt.I<NotificationService>();
  await notificationService.initialize();
  
  final messageListener = GetIt.I<MessageListenerService>();
  messageListener.startListening();
}