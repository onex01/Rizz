import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final List<File> mediaFiles;
  final int initialIndex;
  const FullScreenMediaViewer({super.key, required this.mediaFiles, required this.initialIndex});

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaFiles.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final file = widget.mediaFiles[index];
              final isVideo = file.path.endsWith('.mp4');
              if (isVideo) {
                return _VideoViewer(file: file);
              } else {
                return InteractiveViewer(child: Image.file(file));
              }
            },
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text('${_currentIndex + 1} / ${widget.mediaFiles.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoViewer extends StatefulWidget {
  final File file;
  const _VideoViewer({required this.file});

  @override
  State<_VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<_VideoViewer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return GestureDetector(
      onTap: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
      child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
    );
  }
}