import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';

class CustomVideoControls extends StatelessWidget {
  final String title;

  const CustomVideoControls({required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chewie(controller: ChewieController(
      videoPlayerController: VideoPlayerController.networkUrl(Uri.parse('')),
      customControls: const CupertinoControls(
        backgroundColor: Colors.black,
        iconColor: Colors.white,
      ),
    ),
    );
  }
}
