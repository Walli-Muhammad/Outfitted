class OutfitSuggestion {
  final String outfitName;
  final List<String> itemIds;
  final String reasoning;
  final int styleScore;

  const OutfitSuggestion({
    required this.outfitName,
    required this.itemIds,
    required this.reasoning,
    required this.styleScore,
  });

  factory OutfitSuggestion.fromJson(Map<String, dynamic> json) {
    return OutfitSuggestion(
      outfitName: json['outfit_name'] as String? ?? 'Outfit',
      itemIds: List<String>.from(json['item_ids'] as List? ?? []),
      reasoning: json['reasoning'] as String? ?? '',
      styleScore: (json['style_score'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'outfit_name': outfitName,
        'item_ids': itemIds,
        'reasoning': reasoning,
        'style_score': styleScore,
      };
}
