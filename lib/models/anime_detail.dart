
class AnimeDetail {
  final String title;
  final String? cover;
  final String? synopsis;
  final String? rating;
  final String? studio;
  final List<String>? genres;
  final List<Episode>? episodes;

  AnimeDetail({
    required this.title,
    this.cover,
    this.synopsis,
    this.rating,
    this.studio,
    this.genres,
    this.episodes,
  });

  factory AnimeDetail.fromJson(Map<String, dynamic> json) {
    // Corrected based on the provided api.json file.
    var episodesFromJson = json['streamingEpisodes'] as List?;
    List<Episode> episodeList = episodesFromJson != null
        ? episodesFromJson.map((i) => Episode.fromJson(i)).toList()
        : [];

    var genresFromJson = json['genres'] as List?;
    List<String> genreList = genresFromJson != null
        ? genresFromJson.map((s) => s.toString()).toList()
        : [];

    return AnimeDetail(
      title: json['title'] ?? 'No Title',
      cover: json['thumbnail'],
      synopsis: json['synopsis'] ?? 'No Synopsis',
      rating: json['rating'],
      studio: json['studio'] ?? 'Unknown Studio',
      genres: genreList,
      episodes: episodeList,
    );
  }
}

class Episode {
  final String videoID;
  final String episodeTitle;

  Episode({required this.videoID, required this.episodeTitle});

  factory Episode.fromJson(Map<String, dynamic> json) {
    // Corrected based on the provided api.json file.
    return Episode(
      videoID: json['videoID'] ?? '',
      episodeTitle: json['title'] ?? 'Unknown Episode',
    );
  }
}
