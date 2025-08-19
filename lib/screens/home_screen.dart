import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../models/anime_detail.dart';
import '../services/api_service.dart';
import '../models/anime.dart';
import '../services/history_service.dart';
import 'anime_detail_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Anime>> _latestAnimeFuture;
  late Future<List<Anime>> _top10AnimeFuture;
  final ApiService _apiService = ApiService();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _latestAnimeFuture = _apiService.getLatestAnime();
    _top10AnimeFuture = _apiService.getTop10Anime();
  }

  void _retryFetch() {
    setState(() {
      _fetchData();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Weeaboo', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _retryFetch();
        },
        child: ListView(
          children: [
            const SearchBarWidget(),
            Top10AnimeSection(top10AnimeFuture: _top10AnimeFuture, onRetry: _retryFetch),
            ContinueWatchingSection(key: UniqueKey()), // Use UniqueKey to force rebuild on refresh
            const SectionTitle(title: 'New Update Anime'),
            LatestAnimeGrid(latestAnimeFuture: _latestAnimeFuture, onRetry: _retryFetch),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.watch_later_outlined), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF222230),
        selectedItemColor: const Color(0xFF8A55FE),
        unselectedItemColor: Colors.white54,
        showUnselectedLabels: true,
      ),
    );
  }
}

class ContinueWatchingSection extends StatefulWidget {
  const ContinueWatchingSection({super.key});

  @override
  State<ContinueWatchingSection> createState() => _ContinueWatchingSectionState();
}

class _ContinueWatchingSectionState extends State<ContinueWatchingSection> {
  late Future<HistoryEntry?> _historyFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _historyFuture = HistoryService().getLatestWatchHistory();
  }

  void _resumeWatching(BuildContext context, HistoryEntry entry) async {
    try {
      // We need to fetch the full episode list to pass to the player
      final animeDetail = await _apiService.getAnimeDetail(entry.animeSlug);
      final episodes = animeDetail.episodes?.reversed.toList() ?? [];
      final episodeIndex = episodes.indexWhere((ep) => ep.videoID == entry.episodeId);

      if (episodeIndex == -1) {
        throw Exception('Episode not found in the list.');
      }

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            animeSlug: entry.animeSlug,
            animeTitle: entry.animeTitle,
            coverUrl: entry.coverUrl,
            episodes: episodes,
            initialEpisodeIndex: episodeIndex,
            // Pass the resume position
            startAtPosition: entry.lastPosition,
          ),
        ),
      ).then((_) {
        // Refresh history when returning from player
        setState(() {
          _historyFuture = HistoryService().getLatestWatchHistory();
        });
      });

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melanjutkan tontonan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HistoryEntry?>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ShimmerLoadingCard();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // Show nothing if there is an error or no history
          return const SizedBox.shrink();
        }

        final entry = snapshot.data!;
        final progress = entry.totalDuration.inSeconds > 0
            ? entry.lastPosition.inSeconds / entry.totalDuration.inSeconds
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: 'Terakhir Ditonton'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () => _resumeWatching(context, entry),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C3A),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              entry.coverUrl,
                              width: 100,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 100, height: 60, color: Colors.grey[800]),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.animeTitle,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(entry.episodeTitle, style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_circle_fill, color: Color(0xFF8A55FE), size: 40),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[700],
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8A55FE)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShimmerLoadingCard extends StatelessWidget {
  const _ShimmerLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[850]!,
        highlightColor: Colors.grey[800]!,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }
}

// A reusable widget to show in case of error.
class RetryErrorWidget extends StatelessWidget {
  final String errorInfo;
  final VoidCallback onRetry;

  const RetryErrorWidget({super.key, required this.errorInfo, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorInfo, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A55FE),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari Anime Di Sini',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: const Color(0xFF2C2C3A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class Top10AnimeSection extends StatelessWidget {
  final Future<List<Anime>> top10AnimeFuture;
  final VoidCallback onRetry;
  const Top10AnimeSection({super.key, required this.top10AnimeFuture, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Top 10 This Week'),
        SizedBox(
          height: 180,
          child: FutureBuilder<List<Anime>>(
            future: top10AnimeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[850]!,
                  highlightColor: Colors.grey[800]!,
                  child: CarouselSlider.builder(
                    itemCount: 3,
                    itemBuilder: (context, index, realIndex) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    options: CarouselOptions(height: 180, viewportFraction: 0.8),
                  ),
                );
              }
              if (snapshot.hasError) {
                return RetryErrorWidget(errorInfo: 'Gagal memuat Top 10 Anime.\nError: ${snapshot.error}', onRetry: onRetry);
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No Top 10 anime found.', style: TextStyle(color: Colors.white70)));
              }
              final animeList = snapshot.data!;
              return CarouselSlider.builder(
                itemCount: animeList.length,
                itemBuilder: (context, index, realIndex) {
                  final anime = animeList[index];
                  return TopAnimeCard(anime: anime, rank: index + 1);
                },
                options: CarouselOptions(
                  height: 180,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 5),
                  autoPlayAnimationDuration: const Duration(milliseconds: 800),
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TopAnimeCard extends StatelessWidget {
  final Anime anime;
  final int rank;
  const TopAnimeCard({super.key, required this.anime, required this.rank});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailScreen(animeSlug: anime.videoID), // videoID holds the slug
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (anime.cover != null)
                Image.network(anime.cover!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, color: Colors.red)))
              else
                Container(color: Colors.grey[800]),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 5, offset: Offset(2, 2))],
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Text(
                  anime.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 10)])
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LatestAnimeGrid extends StatelessWidget {
  final Future<List<Anime>> latestAnimeFuture;
  final VoidCallback onRetry;
  const LatestAnimeGrid({super.key, required this.latestAnimeFuture, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Anime>>(
      future: latestAnimeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoadingGrid();
        }
        if (snapshot.hasError) {
          return RetryErrorWidget(errorInfo: 'Gagal memuat anime terbaru.\nError: ${snapshot.error}', onRetry: onRetry);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No latest anime found.', style: TextStyle(color: Colors.white70))));
        }
        final animeList = snapshot.data!;
        return AnimationLimiter(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: animeList.length,
            itemBuilder: (context, index) {
              final anime = animeList[index];
              return AnimationConfiguration.staggeredGrid(
                position: index,
                duration: const Duration(milliseconds: 375),
                columnCount: 2,
                child: ScaleAnimation(
                  child: FadeInAnimation(
                    child: AnimeCard(anime: anime, index: index),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AnimeCard extends StatelessWidget {
  final Anime anime;
  final int index;

  const AnimeCard({super.key, required this.anime, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailScreen(animeSlug: anime.videoID), // videoID holds the slug
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (anime.cover != null)
                    Image.network(
                      anime.cover!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800], child: const Icon(Icons.error, color: Colors.white)),
                    )
                  else
                    Container(color: Colors.grey[800]),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A55FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  if (anime.rating != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(anime.rating!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            anime.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class ShimmerLoadingGrid extends StatelessWidget {
  const ShimmerLoadingGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 15,
                width: 100,
                color: Colors.black,
              ),
            ],
          );
        },
      ),
    );
  }
}