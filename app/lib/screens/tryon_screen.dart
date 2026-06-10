import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/tryon_result.dart';
import '../providers/tryon_provider.dart';
import '../providers/wardrobe_provider.dart';

const _kUserId = 'dev-user-1';

class TryOnScreen extends StatefulWidget {
  const TryOnScreen({super.key});

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TryOnProvider>().loadHistory(_kUserId);
      context.read<WardrobeProvider>().loadItems(_kUserId);
    });
  }

  // ── Image Picker ───────────────────────────────────────────────────────────

  Future<void> _pickAndUploadModelPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    await context
        .read<TryOnProvider>()
        .uploadModelPhoto(File(picked.path), _kUserId);

    if (!mounted) return;
    final err = context.read<TryOnProvider>().errorMessage;
    if (err != null) {
      _showError(err);
      context.read<TryOnProvider>().clearError();
    }
  }

  Future<void> _triggerTryOn(String itemId) async {
    await context.read<TryOnProvider>().generateTryOn(_kUserId, itemId);
    if (!mounted) return;
    final err = context.read<TryOnProvider>().errorMessage;
    if (err != null) {
      _showError(err);
      context.read<TryOnProvider>().clearError();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<TryOnProvider, WardrobeProvider>(
      builder: (context, tryOnProv, wardrobeProv, child) {
        // Show error once via SnackBar
        if (tryOnProv.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showError(tryOnProv.errorMessage!);
              tryOnProv.clearError();
            }
          });
        }

        return Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: const Text('Virtual Try-On'),
                actions: [
                  if (tryOnProv.modelPhotoUrl != null)
                    TextButton(
                      onPressed: _pickAndUploadModelPhoto,
                      child: const Text('Change photo'),
                    ),
                ],
              ),
              // History is always visible — model photo only gates new try-ons
              body: _FittingRoomSection(
                tryOnProv: tryOnProv,
                wardrobeProv: wardrobeProv,
                onItemTap: _triggerTryOn,
                onUploadModel: _pickAndUploadModelPhoto,
              ),
            ),

            // ── Full-screen generating overlay ─────────────────────────────
            if (tryOnProv.isGenerating || tryOnProv.isUploadingPhoto)
              _LoadingOverlay(
                message: tryOnProv.isGenerating
                    ? 'AI is fitting the clothes…\n(~20 seconds)'
                    : 'Uploading your photo…',
              ),
          ],
        );
      },
    );
  }
}

// ── Section: Fitting Room ─────────────────────────────────────────────────────

class _FittingRoomSection extends StatelessWidget {
  final TryOnProvider tryOnProv;
  final WardrobeProvider wardrobeProv;
  final ValueChanged<String> onItemTap;
  final VoidCallback onUploadModel;

  const _FittingRoomSection({
    required this.tryOnProv,
    required this.wardrobeProv,
    required this.onItemTap,
    required this.onUploadModel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // ── Wardrobe section — inline setup banner when no model photo ─
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Your Wardrobe',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        if (tryOnProv.modelPhotoUrl == null)
          // Inline banner — no model photo yet
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Upload a model photo to start trying clothes on',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: tryOnProv.isUploadingPhoto ? null : onUploadModel,
                      child: const Text('Upload'),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // Model photo set — show avatar status bar + garment strip
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: CachedNetworkImageProvider(
                          tryOnProv.modelPhotoUrl!,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your fitting room is ready',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tap a garment below to try it on',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _GarmentStrip(
                  isPremium: tryOnProv.isPremium,
                  wardrobeProv: wardrobeProv,
                  onItemTap: onItemTap,
                ),
              ],
            ),
          ),

        // ── Divider ────────────────────────────────────────────────────
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Divider(),
          ),
        ),

        // ── History section title ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Past Try-Ons',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // ── History list ───────────────────────────────────────────────
        if (tryOnProv.isLoadingHistory)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else if (tryOnProv.history.isEmpty)
          SliverToBoxAdapter(
            child: _EmptyHistory(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _HistoryCard(
                result: tryOnProv.history[i],
                wardrobeProv: wardrobeProv,
                onDelete: (id) async {
                  final confirmed = await showDialog<bool>(
                    context: ctx,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete this try-on?'),
                      content: const Text(
                          'This will permanently remove this result.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && ctx.mounted) {
                    ctx.read<TryOnProvider>().deleteTryOn(id);
                  }
                },
              ),
              childCount: tryOnProv.history.length,
            ),
          ),

        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
      ],
    );
  }
}

// ── Garment Strip ─────────────────────────────────────────────────────────────

class _GarmentStrip extends StatelessWidget {
  final bool isPremium;
  final WardrobeProvider wardrobeProv;
  final ValueChanged<String> onItemTap;

  const _GarmentStrip({
    required this.isPremium,
    required this.wardrobeProv,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 112,
      child: Stack(
        children: [
          // Scroll row (always rendered but may be blurred)
          wardrobeProv.isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : wardrobeProv.items.isEmpty
                  ? const Center(
                      child: Text(
                        'No wardrobe items yet',
                        style: TextStyle(color: Colors.black45),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: wardrobeProv.items.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) {
                        final item = wardrobeProv.items[i];
                        return GestureDetector(
                          onTap: isPremium ? () => onItemTap(item.id) : null,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: item.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  placeholder: (ctx, url) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.checkroom_outlined,
                                        color: Colors.grey),
                                  ),
                                  errorWidget: (ctx, url, err) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.broken_image_outlined,
                                        color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.type,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

          // Premium lock overlay
          if (!isPremium)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: primary, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final TryOnResult result;
  final WardrobeProvider wardrobeProv;
  final ValueChanged<String> onDelete;

  const _HistoryCard({
    required this.result,
    required this.wardrobeProv,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = wardrobeProv.items
        .where((i) => i.id == result.itemId)
        .firstOrNull;

    final dateStr = DateFormat('MMM d, yyyy').format(result.createdAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onLongPress: () => onDelete(result.id),
        child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result image
            if (result.isCompleted && result.resultImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: result.resultImageUrl!,
                  height: 320,
                  fit: BoxFit.cover,
                  placeholder: (ctx, url) => const SizedBox(
                    height: 320,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (ctx, url, err) => const SizedBox(
                    height: 200,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined,
                          size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(
                    result.isFailed
                        ? Icons.error_outline
                        : Icons.hourglass_empty_rounded,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),

            // Item info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item != null
                              ? '${item.color} ${item.type}'
                              : 'Wardrobe item',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: result.status),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    switch (status) {
      case 'completed':
        color = Colors.green;
        label = '✓ Done';
      case 'failed':
        color = Colors.red;
        label = '✗ Failed';
      default:
        color = Colors.orange;
        label = '⏳ Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── Empty History ─────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('👗', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Your try-on results will appear here',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

// ── Full-Screen Loading Overlay ───────────────────────────────────────────────

class _LoadingOverlay extends StatelessWidget {
  final String message;
  const _LoadingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
