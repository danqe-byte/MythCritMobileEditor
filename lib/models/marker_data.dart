class MarkerData {
  final String id;
  double x;
  double y;
  String label;
  String? targetMapId;

  MarkerData({
    required this.id,
    required this.x,
    required this.y,
    required this.label,
    this.targetMapId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': x,
        'y': y,
        'label': label,
        'targetMapId': targetMapId,
      };

  factory MarkerData.fromJson(Map<String, dynamic> json) => MarkerData(
        id: json['id'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        label: json['label'] as String? ?? '',
        targetMapId: json['targetMapId'] as String?,
      );
}
