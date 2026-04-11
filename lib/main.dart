import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'app.dart';
import 'core/di/service_locator.dart';
import 'core/logger/app_logger.dart';
import 'core/notification/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await setupServiceLocator();

  final logger = GetIt.I<AppLogger>();
  await logger.init();

  // Глобальный перехват ошибок
  FlutterError.onError = (details) {
    logger.error('Flutter error: ${details.exception}', details.exception, details.stack);
    if (kDebugMode) FlutterError.dumpErrorToConsole(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught async error', error, stack);
    return true;
  };

  final notificationService = GetIt.I<NotificationService>();
  await notificationService.initialize();

  runApp(const RizzApp());
}