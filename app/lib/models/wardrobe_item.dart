class WardrobeItem {
  final String id;
  final String userId;
  final String imageUrl;
  final String type;
  final String color;
  final String style;
  final List<String> occasions;
  final String description;
  final DateTime createdAt;

  WardrobeItem({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.type,
    required this.color,
    required this.style,
    required this.occasions,
    required this.description,
    required this.createdAt,
  });

  factory WardrobeItem.fromJson(Map<String, dynamic> json) {
    // Safely cast occasions to List<String>
    var list = json['occasions'] as List? ?? [];
    List<String> occasionsList = list.map((e) => e.toString()).toList();

    return WardrobeItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? 'dev-user-1',
      imageUrl: json['image_url'] as String? ?? '',
      type: json['type'] as String? ?? 'unknown',
      color: json['color'] as String? ?? 'unknown',
      style: json['style'] as String? ?? 'unknown',
      occasions: occasionsList,
      description: json['description'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'type': type,
      'color': color,
      'style': style,
      'occasions': occasions,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
