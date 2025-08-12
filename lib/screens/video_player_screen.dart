
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
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
    _episodeStreamFuture = ApiService().getEpisodeStream(widget.animeSlug, widget.episodeSlug);
    _episodeStreamFuture.then((data) {
      if (data.streams.isNotEmpty) {
        // Prioritize a 720p stream if available, otherwise take the first one.
        final initialStream = data.streams.firstWhere(
          (s) => s.resolution == '720p',
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

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(stream.url));
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      placeholder: const Center(child: CircularProgressIndicator()),
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF8A55FE),
        handleColor: const Color(0xFF8A55FE),
        bufferedColor: Colors.grey[600]!,
        backgroundColor: Colors.grey[800]!,
      ),
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: () {
              Navigator.pop(context); // Close the options menu
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

  void _showQualitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C3A),
      builder: (context) {
        return ListView.builder(
          itemCount: _streams.length,
          itemBuilder: (context, index) {
            final stream = _streams[index];
            final bool isSelected = stream.url == _currentStream?.url;
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
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.episodeTitle),
        backgroundColor: Colors.transparent,
      ),
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
