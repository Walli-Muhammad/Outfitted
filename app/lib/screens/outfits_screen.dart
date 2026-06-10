import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/outfit_response.dart';
import '../models/outfit_suggestion.dart';
import '../providers/outfit_provider.dart';
import '../providers/wardrobe_provider.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kUserId = 'dev-user-1';
const _kCity = 'Karachi';

const _occasions = ['Casual', 'Work', 'Dinner', 'Party'];

// ── Weather helpers ───────────────────────────────────────────────────────────

String _weatherEmoji(String condition) {
  final hour = DateTime.now().hour;
  final isNight = hour >= 19 || hour < 6;

  switch (condition.toLowerCase()) {
    case 'sunny':
    case 'clear':
      return isNight ? '🌙' : '☀️';
    case 'cloudy':
    case 'clouds':
      return '⛅';
    case 'rainy':
    case 'rain':
    case 'drizzle':
      return '🌧️';
    case 'stormy':
    case 'thunderstorm':
      return '⛈️';
    case 'snowy':
    case 'snow':
      return '❄️';
    case 'misty':
    case 'foggy':
    case 'hazy':
      return '🌫️';
    default:
      return '🌤️';
  }
}


Color _weatherBg(String condition) {
  switch (condition.toLowerCase()) {
    case 'sunny':
    case 'clear':
      return const Color(0xFFFFF8E1);
    case 'rainy':
    case 'drizzle':
    case 'stormy':
      return const Color(0xFFE3F2FD);
    case 'snowy':
      return const Color(0xFFE8F5E9);
    default:
      return const Color(0xFFF3E5F5);
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  String _selectedOccasion = 'Casual';

  @override
  void initState() {
    super.initState();
    // Trigger initial load after first frame so providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSuggestions();
    });
  }

  void _loadSuggestions() {
    context.read<OutfitProvider>().loadSuggestions(
          userId: _kUserId,
          occasion: _selectedOccasion.toLowerCase(),
          city: _kCity,
        );
  }

  void _onOccasionChanged(String occasion) {
    setState(() => _selectedOccasion = occasion);
    _loadSuggestions();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Outfits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh suggestions',
            onPressed: _loadSuggestions,
          ),
        ],
      ),
      body: Consumer2<OutfitProvider, WardrobeProvider>(
        builder: (context, outfitProv, wardrobeProv, _) {
          // Show error as SnackBar (once)
          if (outfitProv.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showError(outfitProv.errorMessage!);
              outfitProv.clearError();
            });
          }

          return CustomScrollView(
            slivers: [
              // ── Weather Card ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _WeatherCard(
                  weather: outfitProv.currentSuggestions?.weather,
                  isLoading: outfitProv.isLoading,
                ),
              ),

              // ── Occasion Chips ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _OccasionChips(
                  selected: _selectedOccasion,
                  onSelected: _onOccasionChanged,
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              if (outfitProv.isLoading)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, idx) => const _ShimmerCard(),
                    childCount: 3,
                  ),
                )
              else if (outfitProv.currentSuggestions == null ||
                  outfitProv.currentSuggestions!.suggestions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    message: outfitProv.currentSuggestions?.message,
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final suggestion =
                          outfitProv.currentSuggestions!.suggestions[i];
                      return _OutfitCard(
                        suggestion: suggestion,
                        wardrobeProv: wardrobeProv,
                      );
                    },
                    childCount:
                        outfitProv.currentSuggestions!.suggestions.length,
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }
}

// ── Weather Card ──────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  final WeatherInfo? weather;
  final bool isLoading;

  const _WeatherCard({this.weather, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cond = weather?.condition ?? 'clear';
    final bg = _weatherBg(cond);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              )
            : Row(
                children: [
                  Text(
                    _weatherEmoji(cond),
                    style: const TextStyle(fontSize: 44),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weather?.city ?? _kCity,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${weather?.tempC ?? '--'}°C · ${_capitalise(cond)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (weather != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Humidity ${weather!.humidity}%',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Occasion Chips ────────────────────────────────────────────────────────────

class _OccasionChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _OccasionChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _occasions.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final occ = _occasions[i];
          final isSelected = occ == selected;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: ChoiceChip(
              label: Text(occ),
              selected: isSelected,
              onSelected: (isChipSelected) => onSelected(occ),
              selectedColor: primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? primary : Colors.grey.shade300,
                ),
              ),
              backgroundColor: Colors.white,
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }
}

// ── Outfit Card ───────────────────────────────────────────────────────────────

class _OutfitCard extends StatelessWidget {
  final OutfitSuggestion suggestion;
  final WardrobeProvider wardrobeProv;

  const _OutfitCard({required this.suggestion, required this.wardrobeProv});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Resolve wardrobe items from provider (may be empty if not loaded)
    final matchedItems = wardrobeProv.items
        .where((item) => suggestion.itemIds.contains(item.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      suggestion.outfitName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ScoreBadge(score: suggestion.styleScore, color: primary),
                ],
              ),
              const SizedBox(height: 12),

              // ── Garment thumbnails ──────────────────────────────────────
              if (matchedItems.isNotEmpty)
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: matchedItems.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: matchedItems[i].imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.checkroom_outlined,
                              color: Colors.grey),
                        ),
                        errorWidget: (ctx, url, err) => Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.broken_image_outlined,
                              color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Placeholder row if wardrobe not loaded yet
                Wrap(
                  spacing: 6,
                  children: suggestion.itemIds
                      .take(4)
                      .map(
                        (itemId) => Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.checkroom_outlined,
                              color: Colors.grey),
                        ),
                      )
                      .toList(),
                ),

              const SizedBox(height: 12),

              // ── Reasoning ───────────────────────────────────────────────
              Text(
                suggestion.reasoning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.black45,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score Badge ───────────────────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int score;
  final Color color;

  const _ScoreBadge({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$score% match',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Shimmer placeholder card ──────────────────────────────────────────────────

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(height: 18, width: 180),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    3,
                    (idx) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _shimmerBox(height: 72, width: 72, radius: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _shimmerBox(height: 12, width: double.infinity),
                const SizedBox(height: 6),
                _shimmerBox(height: 12, width: 200),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(
      {required double height, required double width, double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: _anim.value),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? message;
  const _EmptyState({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👗', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              message ?? 'Add at least 3 items to your wardrobe to get suggestions',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
