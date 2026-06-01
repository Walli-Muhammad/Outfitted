import 'wardrobe_item.dart';

class Outfit {
  final String id;
  final String? name;
  final String? description;
  final List<WardrobeItem> items;
  final DateTime createdAt;

  Outfit({
    required this.id,
    this.name,
    this.description,
    required this.items,
    required this.createdAt,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List? ?? [];
    List<WardrobeItem> itemsList = list.map((i) => WardrobeItem.fromJson(i as Map<String, dynamic>)).toList();

    return Outfit(
      id: json['id'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      items: itemsList,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'items': items.map((i) => i.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
