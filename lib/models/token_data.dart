class TokenData {
  final String id;
  double x;
  double y;
  String label;
  String? imagePath;
  bool visibleForPlayers;

  TokenData({
    required this.id,
    required this.x,
    required this.y,
    required this.label,
    this.imagePath,
    this.visibleForPlayers = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'label': label,
        'imagePath': imagePath,
        'visibleForPlayers': visibleForPlayers,
      };

  factory TokenData.fromJson(Map<String, dynamic> json) => TokenData(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        label: json['label'] as String? ?? '',
        imagePath: json['imagePath'] as String?,
        visibleForPlayers: json['visibleForPlayers'] as bool? ?? true,
      );
}
