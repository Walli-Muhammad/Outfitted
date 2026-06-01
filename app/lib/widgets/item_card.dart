import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/wardrobe_item.dart';

class WardrobeItemCard extends StatelessWidget {
  final WardrobeItem item;
  final VoidCallback? onTap;

  const WardrobeItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  // Helper to map color name string to Flutter Color for beautiful dot indicators
  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase().trim()) {
      case 'blue':
        return Colors.blue.shade600;
      case 'red':
        return Colors.red.shade600;
      case 'black':
        return Colors.black87;
      case 'white':
        return Colors.white;
      case 'green':
        return Colors.green.shade600;
      case 'grey':
      case 'gray':
        return Colors.grey.shade500;
      case 'yellow':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'purple':
      case 'violet':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = _getColorFromName(item.color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Garment Image (cover fit)
            Expanded(
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade500.withOpacity(0.08),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade500.withOpacity(0.08),
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            
            // Metadata Tags (Flat label styling)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Capitalized Item Type
                  Text(
                    item.type.isEmpty ? 'Unknown' : '${item.type[0].toUpperCase()}${item.type.substring(1)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Color dot indicator + color name text
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: dotColor == Colors.white
                              ? Border.all(color: Colors.grey.shade300, width: 1)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.color.isEmpty ? 'Unknown' : '${item.color[0].toUpperCase()}${item.color.substring(1)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
