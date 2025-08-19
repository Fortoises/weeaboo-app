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
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    print('CustomVideoControls initState. hasPrevEpisode: ${widget.hasPrevEpisode}, hasNextEpisode: ${widget.hasNextEpisode}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chewieController = ChewieController.of(context);
    _controller = _chewieController.videoPlayerController;
    _controller.addListener(_playListener);
    
    // Memastikan sistem UI mode tetap immersive sticky
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.removeListener(_playListener);
    super.dispose();
  }

  // Listener to hide controls automatically when playing
  void _playListener() {
    if (_controller.value.isPlaying && _isVisible) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
    
    // Memastikan sistem UI mode tetap immersive sticky
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _toggleControls() {
    setState(() {
      _isVisible = !_isVisible;
      
      // Cancel any pending hide timer when manually toggling
      _hideTimer?.cancel();
      
      // Memastikan sistem UI mode tetap immersive sticky
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      
      // If showing controls and video is playing, start a new timer to hide them
      if (_isVisible && _controller.value.isPlaying) {
        _hideTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isVisible = false;
            });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Allows tapping on transparent areas
      onTap: _toggleControls,
      child: AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200), // Faster animation
        child: Container(
          // This container is the overlay with controls
          // Mengurangi opacity untuk membuat tampilan lebih bersih
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
      // Menghapus latar belakang hitam yang tidak perlu
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
        // Tukar posisi next dan prev untuk memperbaiki arah
        _buildPrevEpisodeButton(), // Prev episode di kiri
        _buildSkipButton(isForward: false),
        _buildPlayPauseButton(),
        _buildSkipButton(isForward: true),
        _buildNextEpisodeButton(), // Next episode di kanan
      ],
    );
  }

  // Extract episode number from title
  String _extractEpisodeNumber(String? title) {
    if (title == null) return '';
    
    // Cari pola seperti "Eps 1", "Episode 1", "Eps. 1", dll.
    final RegExp regExp = RegExp(r'(?:Eps|Episode|Eps\.)\s*(\d+)', caseSensitive: false);
    final Match? match = regExp.firstMatch(title);
    
    if (match != null) {
      return 'Episode ${match.group(1)}';
    }
    
    // Jika tidak ditemukan pola, kembalikan bagian setelah karakter terakhir ": " atau " - "
    final List<String> separators = [': ', ' - '];
    for (final separator in separators) {
      if (title.contains(separator)) {
        final parts = title.split(separator);
        if (parts.length > 1) {
          return parts.last.trim();
        }
      }
    }
    
    // Jika masih tidak ditemukan, kembalikan title asli
    return title;
  }

  Widget _buildPrevEpisodeButton() {
    final String episodeLabel = _extractEpisodeNumber(widget.prevEpisodeTitle);
    print('Building Prev Episode Button. hasPrevEpisode: ${widget.hasPrevEpisode}, label: $episodeLabel');
    
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
    print('Building Next Episode Button. hasNextEpisode: ${widget.hasNextEpisode}, label: $episodeLabel');
    
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

  Widget _buildSkipButton({required bool isForward}) {
    return IconButton(
      icon: Icon(isForward ? Icons.forward_10_rounded : Icons.replay_10_rounded, color: Colors.white, size: 36),
      onPressed: () async {
        final newPosition = isForward
            ? _controller.value.position + const Duration(seconds: 10)
            : _controller.value.position - const Duration(seconds: 10);
            
        // Tampilkan indikator buffering saat seek
        setState(() {
          _isVisible = true;
        });
        
        await _controller.seekTo(newPosition);
        
        // Memastikan sistem UI mode tetap immersive sticky
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        
        // Reset timer when skipping
        _hideTimer?.cancel();
        if (_isVisible && _controller.value.isPlaying) {
          _hideTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _isVisible = false;
              });
            }
          });
        }
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
          if (_controller.value.isPlaying) {
            _controller.pause();
            _hideTimer?.cancel(); // Cancel hide timer when pausing
          } else {
            _controller.play();
            // Restart hide timer when playing
            _hideTimer?.cancel();
            if (_isVisible) {
              _hideTimer = Timer(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _isVisible = false;
                  });
                }
              });
            }
          }
          
          // Memastikan sistem UI mode tetap immersive sticky
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
                  // Exit fullscreen and return to previous screen
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}