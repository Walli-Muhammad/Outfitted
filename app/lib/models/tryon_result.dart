class TryOnResult {
  final String id;
  final String? resultImageUrl;
  final String itemId;
  final String status;
  final DateTime createdAt;

  const TryOnResult({
    required this.id,
    this.resultImageUrl,
    required this.itemId,
    required this.status,
    required this.createdAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  factory TryOnResult.fromJson(Map<String, dynamic> json) {
    return TryOnResult(
      id: json['id'] as String? ?? '',
      resultImageUrl: json['result_image_url'] as String?,
      itemId: json['item_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'result_image_url': resultImageUrl,
        'item_id': itemId,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };
}
