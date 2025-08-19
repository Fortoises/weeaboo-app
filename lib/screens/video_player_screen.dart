import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/anime_detail.dart';
import '../models/episode_stream.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import '../widgets/custom_video_controls.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String animeSlug;
  final String animeTitle;
  final String coverUrl;
  final List<Episode> episodes;
  final int initialEpisodeIndex;
  final Duration? startAtPosition; // Add optional startAtPosition

  const VideoPlayerScreen({
    super.key,
    required this.animeSlug,
    required this.animeTitle,
    required this.coverUrl,
    required this.episodes,
    required this.initialEpisodeIndex,
    this.startAtPosition, // Add to constructor
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // Player state
  late int _currentIndex;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _error;

  // Stream and quality management state
  List<StreamSource> _allStreams = [];
  List<String> _availableQualities = [];
  StreamSource? _currentStream;
  
  final HistoryService _historyService = HistoryService();
  final List<String> _serverPriority = ['Filedon', 'Pixeldrain', 'Blogger', 'Wibufile'];
  final List<String> _qualityPriority = ['1080p', '720p', '480p', '360p', 'default'];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialEpisodeIndex;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      // Pass the startAtPosition to the initial episode load
      _initializeEpisode(_currentIndex, startAt: widget.startAtPosition ?? Duration.zero);
    });
  }

  Future<void> _saveHistory() async {
    if (_videoPlayerController == null || _currentStream == null) return;

    final position = await _videoPlayerController!.position;
    final duration = _videoPlayerController!.value.duration;

    if (position != null && position > const Duration(seconds: 5) && position.inSeconds < duration.inSeconds - 5) {
      final entry = HistoryEntry(
        animeSlug: widget.animeSlug,
        episodeId: widget.episodes[_currentIndex].videoID,
        episodeTitle: widget.episodes[_currentIndex].episodeTitle,
        animeTitle: widget.animeTitle,
        coverUrl: widget.coverUrl,
        lastPosition: position,
        totalDuration: duration,
        watchedAt: DateTime.now(),
      );
      await _historyService.addOrUpdateHistory(entry);
      print("History saved for ${widget.animeTitle} at ${position.inMinutes} minutes.");
    }
  }

  Future<void> _initializeEpisode(int index, {Duration startAt = Duration.zero}) async {
    await _saveHistory();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _currentIndex = index;
      _allStreams.clear();
      _availableQualities.clear();
      _currentStream = null;
    });

    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    try {
      final episodeData = await ApiService().getEpisodeStream(widget.animeSlug, widget.episodes[index].videoID);
      if (!mounted || episodeData.streams.isEmpty) {
        throw Exception('Tidak ada stream yang tersedia untuk episode ini.');
      }
      _allStreams = episodeData.streams;
      print("Available streams: ${_allStreams.map((s) => '${s.quality} on ${s.provider}').toList()}");
      _updateAvailableQualities();

      final initialStream = _findBestInitialStream();
      if (initialStream == null) {
        throw Exception('Tidak dapat menemukan stream yang valid sesuai prioritas.');
      }
      
      await _initializePlayer(initialStream, startAt: startAt);

    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memuat episode: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializePlayer(StreamSource stream, {Duration startAt = Duration.zero}) async {
    if (!mounted) return;
    setState(() {
       _isLoading = true;
       _currentStream = stream;
    });

    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    try {
      final fullUrl = Uri.parse("http://${ApiService.baseUrl}${stream.streamUrl}");
      print("Attempting to play URL: $fullUrl");
      
      _videoPlayerController = VideoPlayerController.networkUrl(fullUrl);
      await _videoPlayerController!.initialize();
      if (startAt > Duration.zero) {
        await _videoPlayerController!.seekTo(startAt);
      }
      _videoPlayerController!.setLooping(false);

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        customControls: CustomVideoControls(
          title: widget.episodes[_currentIndex].episodeTitle,
          prevEpisodeTitle: _currentIndex > 0 ? widget.episodes[_currentIndex - 1].episodeTitle : null,
          nextEpisodeTitle: _currentIndex < widget.episodes.length - 1 ? widget.episodes[_currentIndex + 1].episodeTitle : null,
          onNextEpisode: _goToNextEpisode,
          onPrevEpisode: _goToPrevEpisode,
          hasNextEpisode: _currentIndex < widget.episodes.length - 1,
          hasPrevEpisode: _currentIndex > 0,
          availableQualities: _availableQualities,
          currentQuality: _currentStream?.quality ?? 'N/A',
          onQualitySelected: (newQuality) {
            _changeStreamQuality(newQuality);
          },
        ),
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        fullScreenByDefault: true,
        allowedScreenSleep: false,
        placeholder: const Center(child: CircularProgressIndicator()),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Gagal memutar video: $e";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeStreamQuality(String newQuality) async {
    if (_currentStream?.quality == newQuality) return;

    final currentPosition = await _videoPlayerController?.position ?? Duration.zero;
    await _saveHistory();
    final newStream = _findStreamForQuality(newQuality);

    if (newStream != null) {
      await _initializePlayer(newStream, startAt: currentPosition);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menemukan stream untuk kualitas $newQuality')),
      );
    }
  }

  StreamSource? _findBestInitialStream() {
    for (var quality in _qualityPriority) {
      final stream = _findStreamForQuality(quality);
      if (stream != null) {
        return stream;
      }
    }
    return null;
  }

  StreamSource? _findStreamForQuality(String quality) {
    for (var serverName in _serverPriority) {
      try {
        return _allStreams.firstWhere((s) => s.quality == quality && s.provider.toLowerCase() == serverName.toLowerCase());
      } catch (e) {
        // Not found, continue
      }
    }
    return null;
  }

  void _updateAvailableQualities() {
    final qualities = _allStreams.map((s) => s.quality).toSet().toList();
    qualities.sort((a, b) {
      if (a == 'default') return 1;
      if (b == 'default') return -1;
      final aVal = int.tryParse(a.replaceAll('p', '')) ?? 0;
      final bVal = int.tryParse(b.replaceAll('p', '')) ?? 0;
      return bVal.compareTo(aVal);
    });
    _availableQualities = qualities;
  }

  void _goToNextEpisode() {
    if (_currentIndex < widget.episodes.length - 1) {
      _initializeEpisode(_currentIndex + 1);
    }
  }

  void _goToPrevEpisode() {
    if (_currentIndex > 0) {
      _initializeEpisode(_currentIndex - 1);
    }
  }

  @override
  void dispose() {
    _saveHistory();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _buildPlayer(),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return const CircularProgressIndicator(color: Colors.white);
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
      );
    }
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }
    return const Center(child: Text('Mempersiapkan player...', style: TextStyle(color: Colors.white)));
  }
}