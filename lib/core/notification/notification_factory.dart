import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'mobile_notification_service.dart';
import 'desktop_notification_service.dart';
import 'web_notification_service.dart';

Future<NotificationService> createNotificationService() async {
  if (kIsWeb) {
    return WebNotificationService();
  } else if (Platform.isAndroid || Platform.isIOS) {
    return MobileNotificationService();
  } else {
    // Десктоп
    return DesktopNotificationService(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
  }
}