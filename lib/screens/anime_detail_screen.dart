import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../models/anime_detail.dart';
import '../services/api_service.dart';
import 'video_player_screen.dart';

class AnimeDetailScreen extends StatefulWidget {
  final String animeSlug;

  const AnimeDetailScreen({super.key, required this.animeSlug});

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  late Future<AnimeDetail> _animeDetailFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _animeDetailFuture = _apiService.getAnimeDetail(widget.animeSlug);
  }

  void _retryFetch() {
    setState(() {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C2A),
      body: FutureBuilder<AnimeDetail>(
        future: _animeDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DetailScreenShimmer();
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Gagal memuat detail anime.\nError: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _retryFetch,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8A55FE),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data found', style: const TextStyle(color: Colors.white)));
          }

          final anime = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF1C1C2A),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      anime.cover != null
                          ? Image.network(
                              anime.cover!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.error, color: Colors.red)),
                            )
                          : Container(color: Colors.grey[800]),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFF1C1C2A)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(anime.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: [
                          InfoChip(icon: Icons.star, text: anime.rating ?? 'N/A'),
                          InfoChip(text: anime.studio ?? 'N/A'),
                          const InfoChip(text: 'Jul 08, 2025'), // Placeholder
                          const InfoChip(text: 'TV'), // Placeholder
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        children: anime.genres?.map((genre) => Chip(label: Text(genre), backgroundColor: const Color(0xFF2C2C3A), labelStyle: const TextStyle(color: Colors.white))).toList() ?? [],
                      ),
                      const SizedBox(height: 24),
                      const SectionTitle(title: 'Synopsis'),
                      Text(anime.synopsis ?? 'No synopsis available.', style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
                      const SizedBox(height: 24),
                      const SectionTitle(title: 'Episodes'),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final episode = anime.episodes![index];
                      return EpisodeListItem(animeSlug: widget.animeSlug, episode: episode);
                    },
                    childCount: anime.episodes?.length ?? 0,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EpisodeListItem extends StatelessWidget {
  final String animeSlug;
  final Episode episode;
  const EpisodeListItem({super.key, required this.animeSlug, required this.episode});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(
                  animeSlug: animeSlug,
                  episodeSlug: episode.videoID,
                  episodeTitle: episode.episodeTitle,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(episode.episodeTitle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.play_arrow_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final String text;
  final IconData? icon;
  const InfoChip({super.key, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C3A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, color: Colors.amber, size: 16),
          if (icon != null)
            const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class DetailScreenShimmer extends StatelessWidget {
  const DetailScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(color: Colors.grey[850]),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 28, width: 250, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12))),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: List.generate(4, (index) => Container(height: 36, width: 80, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)))),
                  ),
                  const SizedBox(height: 16),
                   Wrap(
                    spacing: 8.0,
                    children: List.generate(3, (index) => Container(height: 32, width: 100, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)))),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 22, width: 150, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8))),
                  const SizedBox(height: 16),
                  Container(height: 100, width: double.infinity, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12))),
                  const SizedBox(height: 24),
                  Container(height: 22, width: 100, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8))),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Container(
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 10.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                childCount: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}