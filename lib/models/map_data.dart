import 'marker_data.dart';
import 'token_data.dart';

class MapData {
  final String id;
  String name;
  String imagePath;
  final List<MarkerData> markers;
  final List<TokenData> tokens;

  MapData({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.markers,
    required this.tokens,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'imagePath': imagePath,
        'markers': markers.map((e) => e.toJson()).toList(),
        'tokens': tokens.map((e) => e.toJson()).toList(),
      };

  factory MapData.fromJson(Map<String, dynamic> json) => MapData(
        id: json['id'] as String,
        name: json['name'] as String,
        imagePath: json['imagePath'] as String,
        markers: (json['markers'] as List<dynamic>? ?? [])
            .map((e) => MarkerData.fromJson(e as Map<String, dynamic>))
            .toList(),
        tokens: (json['tokens'] as List<dynamic>? ?? [])
            .map((e) => TokenData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
