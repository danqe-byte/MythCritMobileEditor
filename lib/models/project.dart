import 'dart:convert';

import 'map_data.dart';

class ProjectMeta {
  final String id;
  final String name;

  ProjectMeta({required this.id, required this.name});

  factory ProjectMeta.fromProject(Project project) =>
      ProjectMeta(id: project.id, name: project.name);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory ProjectMeta.fromJson(Map<String, dynamic> json) =>
      ProjectMeta(id: json['id'] as String, name: json['name'] as String);
}

class Project {
  final String id;
  String name;
  String? lastOpenedMapId;
  final List<MapData> maps;

  Project({
    required this.id,
    required this.name,
    required this.maps,
    this.lastOpenedMapId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lastOpenedMapId': lastOpenedMapId,
        'maps': maps.map((m) => m.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        name: json['name'] as String,
        lastOpenedMapId: json['lastOpenedMapId'] as String?,
        maps: (json['maps'] as List<dynamic>? ?? [])
            .map((e) => MapData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String toJsonString() => jsonEncode(toJson());

  factory Project.fromJsonString(String data) =>
      Project.fromJson(jsonDecode(data) as Map<String, dynamic>);

  MapData? getMapById(String? id) {
    if (id == null) return null;
    return maps.where((m) => m.id == id).firstOrNull;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
