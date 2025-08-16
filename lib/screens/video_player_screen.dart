import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../models/episode_stream.dart';
import '../services/api_service.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String animeSlug;
  final String episodeSlug;
  final String episodeTitle;

  const VideoPlayerScreen({
    super.key,
    required this.animeSlug,
    required this.episodeSlug,
    required this.episodeTitle,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late Future<EpisodeStream> _episodeStreamFuture;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  StreamSource? _currentStream;
  List<StreamSource> _streams = [];

  @override
  void initState() {
    super.initState();
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    _episodeStreamFuture = ApiService().getEpisodeStream(widget.animeSlug, widget.episodeSlug);
    _episodeStreamFuture.then((data) {
      if (data.streams.isNotEmpty) {
        final initialStream = data.streams.firstWhere(
          (s) => s.quality == '720p',
          orElse: () => data.streams.first,
        );
        _initializePlayer(initialStream);
        setState(() {
          _streams = data.streams;
        });
      }
    });
  }

  void _initializePlayer(StreamSource stream) {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    // Parse the relative stream URL to separate the path from the query parameters.
    final streamUri = Uri.parse(stream.streamUrl);
    final fullUrl = Uri.http(
      ApiService.baseUrl,
      streamUri.path,
      streamUri.queryParameters.isNotEmpty ? streamUri.queryParameters : null,
    );

    _videoPlayerController = VideoPlayerController.networkUrl(
      fullUrl,
    );
    
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      fullScreenByDefault: true,
      allowedScreenSleep: false,
      placeholder: const Center(child: CircularProgressIndicator()),
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF8A55FE),
        handleColor: const Color(0xFF8A55FE),
        bufferedColor: Colors.grey[600]!,
        backgroundColor: Colors.grey[800]!,
      ),
      overlay: _buildCustomAppBar(context),
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: () {
              Navigator.pop(context);
              _showQualitySelector(context);
            },
            iconData: Icons.hd,
            title: 'Kualitas Video',
          ),
        ];
      },
    );
    setState(() {
      _currentStream = stream;
    });
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.episodeTitle,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQualitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C3A),
      builder: (context) {
        return ListView.builder(
          itemCount: _streams.length,
          itemBuilder: (context, index) {
            final stream = _streams[index];
            final bool isSelected = stream.streamUrl == _currentStream?.streamUrl;
            return ListTile(
              title: Text(stream.server, style: TextStyle(color: isSelected ? const Color(0xFF8A55FE) : Colors.white)),
              trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF8A55FE)) : null,
              onTap: () {
                Navigator.pop(context);
                _initializePlayer(stream);
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FutureBuilder<EpisodeStream>(
          future: _episodeStreamFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white));
            }
            if (_chewieController == null) {
              return const Text('Tidak ada stream yang tersedia.', style: TextStyle(color: Colors.white));
            }
            return Chewie(controller: _chewieController!);
          },
        ),
      ),
    );
  }
}
