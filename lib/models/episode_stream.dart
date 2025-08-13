class EpisodeStream {
  final String title;
  final List<StreamSource> streams;

  EpisodeStream({required this.title, required this.streams});

  factory EpisodeStream.fromJson(Map<String, dynamic> json) {
    var streamsFromJson = json['streams'] as List?;
    List<StreamSource> streamList = streamsFromJson != null
        ? streamsFromJson
            .map((i) => StreamSource.fromJson(i))
            .where((source) => source.url.isNotEmpty) // Filter out empty URLs
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
  final String url;
  final String resolution;

  StreamSource({required this.server, required this.url, required this.resolution});

  factory StreamSource.fromJson(Map<String, dynamic> json) {
    // The API provides 'direct_url' and 'embed_url'. Prioritize 'direct_url'.
    final String url = json['direct_url'] ?? json['embed_url'] ?? '';
    return StreamSource(
      server: json['server'] ?? 'Unknown Server',
      url: url,
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