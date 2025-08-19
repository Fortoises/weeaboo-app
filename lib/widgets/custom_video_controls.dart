import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class CustomVideoControls extends StatefulWidget {
  final String title;
  final String? prevEpisodeTitle;
  final String? nextEpisodeTitle;
  final VoidCallback onNextEpisode;
  final VoidCallback onPrevEpisode;
  final bool hasNextEpisode;
  final bool hasPrevEpisode;

  // New parameters for quality selection
  final List<String> availableQualities;
  final String currentQuality;
  final Function(String) onQualitySelected;

  const CustomVideoControls({
    super.key,
    required this.title,
    this.prevEpisodeTitle,
    this.nextEpisodeTitle,
    required this.onNextEpisode,
    required this.onPrevEpisode,
    required this.hasNextEpisode,
    required this.hasPrevEpisode,
    required this.availableQualities,
    required this.currentQuality,
    required this.onQualitySelected,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;
  bool _isVisible = true;
  Timer? _hideTimer;
  bool _isSeeking = false;
  bool _userIsPlaying = true;

  @override
  void initState() {
    super.initState();
    _userIsPlaying = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chewieController = ChewieController.of(context);
    _controller = _chewieController.videoPlayerController;
    _controller.addListener(_playListener);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_playListener);
    super.dispose();
  }

  void _playListener() {
    if (_controller.value.isPlaying && _isVisible && !_isSeeking) {
      _startHideTimer();
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _isVisible = !_isVisible;
      _hideTimer?.cancel();
      if (_isVisible && _userIsPlaying) {
        _startHideTimer();
      }
    });
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          color: Colors.black.withOpacity(0.3),
          child: _buildControls(context),
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return Padding(
      padding: padding,
      child: Column(
        children: [
          _buildTopBar(context),
          Expanded(child: _buildMiddleControls()),
          _buildBottomBar(context),
        ],
      ),
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
        _buildPrevEpisodeButton(),
        _buildSkipButton(isForward: false),
        _buildPlayPauseButton(),
        _buildSkipButton(isForward: true),
        _buildNextEpisodeButton(),
      ],
    );
  }

  Widget _buildSkipButton({required bool isForward}) {
    return IconButton(
      icon: Icon(isForward ? Icons.forward_10_rounded : Icons.replay_10_rounded, color: Colors.white, size: 36),
      onPressed: _isSeeking ? null : () async {
        setState(() => _isSeeking = true);
        final currentPosition = _controller.value.position;
        final newPosition = isForward
            ? currentPosition + const Duration(seconds: 10)
            : currentPosition - const Duration(seconds: 10);
        await _controller.seekTo(newPosition);
        if (_userIsPlaying) {
          _controller.play();
        }
        if (mounted) {
          setState(() => _isSeeking = false);
        }
      },
    );
  }

  Widget _buildPlayPauseButton() {
    return IconButton(
      icon: Icon(
        _userIsPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
        color: Colors.white, size: 60,
      ),
      onPressed: () {
        setState(() {
          _userIsPlaying = !_userIsPlaying;
          if (_userIsPlaying) {
            _controller.play();
            _startHideTimer();
          } else {
            _controller.pause();
            _hideTimer?.cancel();
          }
        });
      },
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
            allowScrubbing: !_isSeeking,
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
                  return Text(_formatDuration(value.position), style: const TextStyle(color: Colors.white));
                },
              ),
              const Text(" / ", style: TextStyle(color: Colors.white70)),
              Text(_formatDuration(_controller.value.duration), style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              _buildQualitySelector(), // New quality selector button
              IconButton(
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                onPressed: () {
                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New Widget for the quality selection button and menu
  Widget _buildQualitySelector() {
    // Don't build if there are no qualities or only one
    if (widget.availableQualities.length <= 1) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      onSelected: widget.onQualitySelected,
      initialValue: widget.currentQuality,
      color: Colors.black87,
      itemBuilder: (BuildContext context) {
        return widget.availableQualities.map((String quality) {
          return PopupMenuItem<String>(
            value: quality,
            child: Text(
              quality,
              style: TextStyle(
                color: widget.currentQuality == quality ? const Color(0xFF8A55FE) : Colors.white,
                fontWeight: widget.currentQuality == quality ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.settings, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(widget.currentQuality, style: const TextStyle(color: Colors.white)),
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

  String _extractEpisodeNumber(String? title) {
    if (title == null) return '';
    final RegExp regExp = RegExp(r'(?:Eps|Episode|Eps\.)\s*(\d+)', caseSensitive: false);
    final Match? match = regExp.firstMatch(title);
    if (match != null) {
      return 'Episode ${match.group(1)}';
    }
    final List<String> separators = [': ', ' - '];
    for (final separator in separators) {
      if (title.contains(separator)) {
        final parts = title.split(separator);
        if (parts.length > 1) {
          return parts.last.trim();
        }
      }
    }
    return title;
  }

  Widget _buildPrevEpisodeButton() {
    final String episodeLabel = _extractEpisodeNumber(widget.prevEpisodeTitle);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
          onPressed: widget.hasPrevEpisode ? widget.onPrevEpisode : null,
          disabledColor: Colors.white30,
        ),
        if (widget.hasPrevEpisode && episodeLabel.isNotEmpty)
          Text(episodeLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildNextEpisodeButton() {
    final String episodeLabel = _extractEpisodeNumber(widget.nextEpisodeTitle);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
          onPressed: widget.hasNextEpisode ? widget.onNextEpisode : null,
          disabledColor: Colors.white30,
        ),
        if (widget.hasNextEpisode && episodeLabel.isNotEmpty)
          Text(episodeLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}