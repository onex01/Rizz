import 'dart:io';
import '../services/cache_service.dart';
import '../widgets/full_screen_media_viewer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserMediaScreen extends StatefulWidget {
  final String userId;
  const UserMediaScreen({super.key, required this.userId});

  @override
  State<UserMediaScreen> createState() => _UserMediaScreenState();
}

class _UserMediaScreenState extends State<UserMediaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Медиа'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Фото'),
            Tab(text: 'Видео'),
            Tab(text: 'Файлы'),
            Tab(text: 'Голосовые'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MediaList(userId: widget.userId, type: 'image_hex'),
          _MediaList(userId: widget.userId, type: 'video_circle'),
          _MediaList(userId: widget.userId, type: 'file_hex'),
          _MediaList(userId: widget.userId, type: 'voice'),
        ],
      ),
    );
  }
}

class _MediaList extends StatelessWidget {
  final String userId;
  final String type;
  const _MediaList({required this.userId, required this.type});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('messages')
          .where('senderId', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Нет элементов'));
        }
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final messageId = docs[index].id;
            return FutureBuilder<File?>(
              future: MessageFileCache().getOrConvert(messageId, data),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final file = snap.data!;
                if (type == 'image_hex') {
                  return GestureDetector(
                    onTap: () => _showFullScreen(context, [file], 0),
                    child: Image.file(file, fit: BoxFit.cover),
                  );
                } else if (type == 'video_circle') {
                  return GestureDetector(
                    onTap: () => _showFullScreen(context, [file], 0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(file, fit: BoxFit.cover),
                        const Center(child: Icon(Icons.play_circle_outline, size: 40, color: Colors.white)),
                      ],
                    ),
                  );
                } else {
                  return const Icon(Icons.insert_drive_file, size: 48);
                }
              },
            );
          },
        );
      },
    );
  }

  void _showFullScreen(BuildContext context, List<File> files, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenMediaViewer(mediaFiles: files, initialIndex: index),
      ),
    );
  }
}