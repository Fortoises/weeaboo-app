
class Anime {
  final String title;
  final String? cover;
  final String? rating;
  final String videoID;

  Anime({
    required this.title,
    this.cover,
    this.rating,
    required this.videoID,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    return Anime(
      title: json['title'],
      cover: json['cover'],
      rating: json['rating'],
      videoID: json['videoID'],
    );
  }
}
