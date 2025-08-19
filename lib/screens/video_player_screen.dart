import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/anime_detail.dart'; // Assuming Episode model is here
import '../models/episode_stream.dart';
import '../services/api_service.dart';
import '../widgets/custom_video_controls.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String animeSlug;
  final List<Episode> episodes;
  final int initialEpisodeIndex;

  const VideoPlayerScreen({
    super.key,
    required this.animeSlug,
    required this.episodes,
    required this.initialEpisodeIndex,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late int _currentIndex;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialEpisodeIndex;
    
    // Enable fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    // Tambahkan delay kecil untuk memastikan sistem UI mode diterapkan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });

    _initializePlayerForIndex(_currentIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Memastikan sistem UI mode tetap immersive sticky saat widget dimuat
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _initializePlayerForIndex(int index) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _videoPlayerController?.dispose();
    _chewieController?.dispose();

    final currentEpisode = widget.episodes[index];

    try {
      final data = await ApiService().getEpisodeStream(widget.animeSlug, currentEpisode.videoID);
      if (!mounted || data.streams.isEmpty) {
        throw Exception('Tidak ada stream yang tersedia.');
      }

      final initialStream = data.streams.firstWhere(
        (s) => s.quality == '720p', orElse: () => data.streams.first);

      final streamUri = Uri.parse(initialStream.streamUrl);
      final fullUrl = Uri.http(ApiService.baseUrl, streamUri.path, streamUri.queryParameters.isNotEmpty ? streamUri.queryParameters : null);

      _videoPlayerController = VideoPlayerController.networkUrl(fullUrl);
      await _videoPlayerController!.initialize();

      if (!mounted) return;

      // Memastikan sistem UI mode tetap immersive sticky
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        customControls: CustomVideoControls(
          title: currentEpisode.episodeTitle,
          prevEpisodeTitle: _currentIndex > 0 ? widget.episodes[_currentIndex - 1].episodeTitle : null,
          nextEpisodeTitle: _currentIndex < widget.episodes.length - 1 ? widget.episodes[_currentIndex + 1].episodeTitle : null,
          onNextEpisode: _goToNextEpisode,
          onPrevEpisode: _goToPrevEpisode,
          hasNextEpisode: _currentIndex < widget.episodes.length - 1,
          hasPrevEpisode: _currentIndex > 0,
        ),
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        fullScreenByDefault: true,
        allowedScreenSleep: false,
        placeholder: const Center(child: CircularProgressIndicator()),
        additionalOptions: (context) {
          // Memastikan sistem UI mode tetap immersive sticky
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          return const [];
        },
      );

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memuat stream: $e";
          _isLoading = false;
        });
      }
    }
  }

  void _goToNextEpisode() {
    print('Next episode button pressed. Current index: $_currentIndex, Episodes length: ${widget.episodes.length}');
    if (_currentIndex < widget.episodes.length - 1) {
      setState(() {
        _currentIndex++;
        print('Navigating to next episode. New index: $_currentIndex');
      });
      _initializePlayerForIndex(_currentIndex);
    } else {
      print('No next episode available');
    }
  }

  void _goToPrevEpisode() {
    print('Prev episode button pressed. Current index: $_currentIndex');
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        print('Navigating to previous episode. New index: $_currentIndex');
      });
      _initializePlayerForIndex(_currentIndex);
    } else {
      print('No previous episode available');
    }
  }

  @override
  void dispose() {
    // Kembali ke mode normal
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Memastikan sistem UI mode tetap immersive sticky
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _buildPlayer(),
      ),
    );
  }

  @override
  void setState(VoidCallback fn) {
    // Memastikan sistem UI mode tetap immersive sticky saat state berubah
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    super.setState(fn);
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      );
    }
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } 
    return const CircularProgressIndicator(color: Colors.white);
  }
}