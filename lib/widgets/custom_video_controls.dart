import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomVideoControls extends StatefulWidget {
  final String title;
  final String? prevEpisodeTitle;
  final String? nextEpisodeTitle;
  final VoidCallback onNextEpisode;
  final VoidCallback onPrevEpisode;
  final bool hasNextEpisode;
  final bool hasPrevEpisode;

  const CustomVideoControls({
    super.key,
    required this.title,
    this.prevEpisodeTitle,
    this.nextEpisodeTitle,
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
  late ChewieController _chewieController;
  bool _isVisible = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chewieController = ChewieController.of(context);
    _controller = _chewieController.videoPlayerController;
    _controller.addListener(_playListener);
  }

  @override
  void dispose() {
    _controller.removeListener(_playListener);
    super.dispose();
  }

  // Listener to hide controls automatically when playing
  void _playListener() {
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
      behavior: HitTestBehavior.opaque, // Allows tapping on transparent areas
      onTap: () {
        setState(() {
          _isVisible = !_isVisible;
        });
      },
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          // This container is the overlay with controls
          color: Colors.black.withOpacity(0.5),
          child: _buildControls(context),
        ),
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
    return AbsorbPointer(
      absorbing: !_isVisible, // Disable buttons when controls are hidden
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPrevEpisodeButton(),
          _buildSkipButton(isForward: false),
          _buildPlayPauseButton(),
          _buildSkipButton(isForward: true),
          _buildNextEpisodeButton(),
        ],
      ),
    );
  }

  Widget _buildPrevEpisodeButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
          onPressed: widget.hasPrevEpisode ? widget.onPrevEpisode : null,
          disabledColor: Colors.white30,
        ),
        if (widget.hasPrevEpisode)
          Text("Prev: ${widget.prevEpisodeTitle}", style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildNextEpisodeButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
          onPressed: widget.hasNextEpisode ? widget.onNextEpisode : null,
          disabledColor: Colors.white30,
        ),
        if (widget.hasNextEpisode)
          Text("Next: ${widget.nextEpisodeTitle}", style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildSkipButton({required bool isForward}) {
    return IconButton(
      icon: Icon(isForward ? Icons.forward_10_rounded : Icons.replay_10_rounded, color: Colors.white, size: 36),
      onPressed: () {
        final newPosition = isForward
            ? _controller.value.position + const Duration(seconds: 10)
            : _controller.value.position - const Duration(seconds: 10);
        _controller.seekTo(newPosition);
      },
    );
  }

  Widget _buildPlayPauseButton() {
    return IconButton(
      icon: Icon(
        _controller.value.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
        color: Colors.white, size: 60,
      ),
      onPressed: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return AbsorbPointer(
      absorbing: !_isVisible, // Disable seek bar when controls are hidden
      child: Container(
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
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}