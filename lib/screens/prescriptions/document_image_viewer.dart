import 'dart:io';

import 'package:flutter/material.dart';

class DocumentImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const DocumentImageViewer({required this.images, required this.initialIndex});

  @override
  State<DocumentImageViewer> createState() => _DocumentImageViewerState();
}

class _DocumentImageViewerState extends State<DocumentImageViewer> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final path = widget.images[index];
          if (!File(path).existsSync()) {
            return const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: Colors.white70,
                size: 64,
              ),
            );
          }

          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(child: Image.file(File(path), fit: BoxFit.contain)),
          );
        },
      ),
    );
  }
}
