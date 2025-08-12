
class EpisodeStream {
  final String title;
  final List<StreamSource> streams;

  EpisodeStream({required this.title, required this.streams});

  factory EpisodeStream.fromJson(Map<String, dynamic> json) {
    var streamsFromJson = json['streams'] as List?;
    List<StreamSource> streamList = streamsFromJson != null
        ? streamsFromJson.map((i) => StreamSource.fromJson(i)).toList()
        : [];

    return EpisodeStream(
      title: json['title'] ?? 'Unknown Title',
      streams: streamList,
    );
  }
}

class StreamSource {
  final String server;
  final String url;
  final String resolution;

  StreamSource({required this.server, required this.url, required this.resolution});

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    return StreamSource(
      server: json['server'] ?? 'Unknown Server',
      url: json['url'] ?? '',
      // Helper to extract resolution like '360p' from the server name
      resolution: _extractResolution(json['server'] ?? ''),
    );
  }

  static String _extractResolution(String serverName) {
    final RegExp regExp = RegExp(r'(\d+p)');
    final match = regExp.firstMatch(serverName);
    return match?.group(1) ?? 'N/A';
  }
}
