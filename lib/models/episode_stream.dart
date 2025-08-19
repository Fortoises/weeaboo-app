class EpisodeStream {
  final String title;
  final List<StreamSource> streams;

  EpisodeStream({required this.title, required this.streams});

  factory EpisodeStream.fromJson(Map<String, dynamic> json) {
    var streamsFromJson = json['streams'] as List?;
    List<StreamSource> streamList = streamsFromJson != null
        ? streamsFromJson
            .map((i) => StreamSource.fromJson(i))
            .where((source) => source.streamUrl.isNotEmpty) // Filter out empty URLs
            .toList()
        : [];

    return EpisodeStream(
      title: json['title'] ?? 'Unknown Title',
      streams: streamList,
    );
  }
}

class StreamSource {
  final String server;
  final String provider;
  final String streamUrl;
  final String quality;

  StreamSource({required this.server, required this.provider, required this.streamUrl, required this.quality});

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    return StreamSource(
      server: json['server'] ?? 'Unknown Server',
      provider: json['provider'] ?? '',
      streamUrl: json['stream_url'] ?? '',
      quality: json['quality'] ?? 'N/A',
    );
  }
}