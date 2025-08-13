import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime.dart';
import '../models/anime_detail.dart';
import '../models/episode_stream.dart';

class ApiService {
  final String _baseUrl = "apimy.ldtp.com";
  final String? _apiKey = "habib123";

  Future<List<Anime>> getLatestAnime() async {
    if (_apiKey == null) {
      throw Exception("API Key not found");
    }

    final url = Uri.https(_baseUrl, '/home/');

    final response = await http.get(
      url,
      headers: {
        'X-API-KEY': _apiKey!,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Anime.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load latest anime');
    }
  }

  Future<List<Anime>> getTop10Anime() async {
    if (_apiKey == null) {
      throw Exception("API Key not found");
    }

    final url = Uri.https(_baseUrl, '/top10/');

    final response = await http.get(
      url,
      headers: {
        'X-API-KEY': _apiKey!,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // The top10 endpoint returns 'slug' instead of 'videoID'. We'll map it to videoID.
      return data.map((json) {
        json['videoID'] = json['slug'];
        return Anime.fromJson(json);
      }).toList();
    } else {
      throw Exception('Failed to load top 10 anime');
    }
  }

  Future<AnimeDetail> getAnimeDetail(String slug) async {
    if (_apiKey == null) {
      throw Exception("API Key not found");
    }

    final url = Uri.https(_baseUrl, '/anime/$slug');

    final response = await http.get(
      url,
      headers: {
        'X-API-KEY': _apiKey!,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return AnimeDetail.fromJson(data);
    } else {
      throw Exception('Failed to load anime detail');
    }
  }

  Future<EpisodeStream> getEpisodeStream(String animeSlug, String episodeSlug) async {
    if (_apiKey == null) {
      throw Exception("API Key not found");
    }

    // The episode slug from the detail endpoint might have leading/trailing slashes.
    final cleanEpisodeSlug = episodeSlug.replaceAll(RegExp(r'^/|/\$'), '');

    final url = Uri.https(_baseUrl, "/anime/$animeSlug/episode/$cleanEpisodeSlug");

    final response = await http.get(
      url,
      headers: {
        'X-API-KEY': _apiKey!,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return EpisodeStream.fromJson(data);
    } else {
      throw Exception('Failed to load episode streams');
    }
  }
}
