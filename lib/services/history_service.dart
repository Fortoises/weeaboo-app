import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Data model for a single history entry
class HistoryEntry {
  final String animeSlug;
  final String episodeId;
  final String episodeTitle;
  final String animeTitle;
  final String coverUrl;
  final Duration lastPosition;
  final Duration totalDuration;
  final DateTime watchedAt;

  HistoryEntry({
    required this.animeSlug,
    required this.episodeId,
    required this.episodeTitle,
    required this.animeTitle,
    required this.coverUrl,
    required this.lastPosition,
    required this.totalDuration,
    required this.watchedAt,
  });

  // Methods for JSON serialization/deserialization
  Map<String, dynamic> toJson() => {
        'animeSlug': animeSlug,
        'episodeId': episodeId,
        'episodeTitle': episodeTitle,
        'animeTitle': animeTitle,
        'coverUrl': coverUrl,
        'lastPosition': lastPosition.inMilliseconds,
        'totalDuration': totalDuration.inMilliseconds,
        'watchedAt': watchedAt.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        animeSlug: json['animeSlug'],
        episodeId: json['episodeId'],
        episodeTitle: json['episodeTitle'],
        animeTitle: json['animeTitle'],
        coverUrl: json['coverUrl'],
        lastPosition: Duration(milliseconds: json['lastPosition'] ?? 0),
        totalDuration: Duration(milliseconds: json['totalDuration'] ?? 0),
        watchedAt: DateTime.parse(json['watchedAt']),
      );
}

// Service class to manage history operations
class HistoryService {
  static const _historyKey = 'continue_watching_history';
  static const _maxHistoryItems = 10;

  // Save the entire history list to shared preferences
  Future<void> _saveHistory(List<HistoryEntry> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = history.map((entry) => json.encode(entry.toJson())).toList();
    await prefs.setStringList(_historyKey, historyJson);
  }

  // Load the entire history list from shared preferences
  Future<List<HistoryEntry>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    return historyJson.map((entryJson) => HistoryEntry.fromJson(json.decode(entryJson))).toList();
  }

  // Public method to get the most recent history entry
  Future<HistoryEntry?> getLatestWatchHistory() async {
    final history = await _loadHistory();
    if (history.isEmpty) {
      return null;
    }
    // Sort by watchedAt date to get the most recent
    history.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return history.first;
  }

  // Public method to add or update an entry in the history
  Future<void> addOrUpdateHistory(HistoryEntry newEntry) async {
    final history = await _loadHistory();

    // Remove any existing entry for the same episode to avoid duplicates
    history.removeWhere((entry) => entry.episodeId == newEntry.episodeId);

    // Add the new entry to the top of the list
    history.insert(0, newEntry);

    // Trim the list if it exceeds the maximum size
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }

    await _saveHistory(history);
  }
}