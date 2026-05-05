import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(BuildContext context, String message, {bool isError = false}) {
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : null, duration: const Duration(seconds: 2)),
    );
  } else {
    Fluttertoast.showToast(msg: message, gravity: ToastGravity.BOTTOM, backgroundColor: isError ? Colors.red : null);
  }
}