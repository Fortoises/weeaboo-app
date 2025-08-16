import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomVideoControls extends StatefulWidget {
  final ChewieController chewieController;
  final String title;
  final VoidCallback onNextEpisode;
  final VoidCallback onPrevEpisode;
  final bool hasNextEpisode;
  final bool hasPrevEpisode;

  const CustomVideoControls({
    super.key,
    required this.chewieController,
    required this.title,
    required this.onNextEpisode,
    required this.onPrevEpisode,
    required this.hasNextEpisode,
    required this.hasPrevEpisode,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  late VideoPlayerController _controller;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.chewieController.videoPlayerController;
    _controller.addListener(_checkVideo);
  }

  @override
  void didUpdateWidget(covariant CustomVideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chewieController.videoPlayerController != _controller) {
      _controller.removeListener(_checkVideo);
      _controller = widget.chewieController.videoPlayerController;
      _controller.addListener(_checkVideo);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideo);
    super.dispose();
  }

  void _checkVideo() {
    if (_controller.value.isPlaying && _isVisible) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _controller.value.isPlaying) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isVisible = !_isVisible;
        });
      },
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: _isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildControls(context),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Column(
      children: [
        _buildTopBar(context),
        Expanded(child: _buildMiddleControls()),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
          onPressed: widget.hasPrevEpisode ? widget.onPrevEpisode : null,
          disabledColor: Colors.white30,
        ),
        IconButton(
          icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 36),
          onPressed: () {
            _controller.seekTo(_controller.value.position - const Duration(seconds: 10));
          },
        ),
        IconButton(
          icon: Icon(
            _controller.value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
            color: Colors.white, size: 60,
          ),
          onPressed: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 36),
          onPressed: () {
            _controller.seekTo(_controller.value.position + const Duration(seconds: 10));
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
          onPressed: widget.hasNextEpisode ? widget.onNextEpisode : null,
          disabledColor: Colors.white30,
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: const Color(0xFF8A55FE),
              bufferedColor: Colors.grey[600]!,
              backgroundColor: Colors.grey[800]!,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, VideoPlayerValue value, child) {
                  return Text(
                    _formatDuration(value.position),
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
              const Text(" / ", style: TextStyle(color: Colors.white70)),
              Text(
                _formatDuration(_controller.value.duration),
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  widget.chewieController.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: () {
                  widget.chewieController.toggleFullScreen();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
