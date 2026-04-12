import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class QrCodeScreen extends StatelessWidget {
  final String userId;
  final String nickname;

  const QrCodeScreen({super.key, required this.userId, required this.nickname});

  String get profileUrl => 'https://rizz.onex01.ru/user/$userId';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой QR-код'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => Share.share('$nickname в Rizz: $profileUrl'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(nickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: QrImageView(
                data: profileUrl,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(profileUrl, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}