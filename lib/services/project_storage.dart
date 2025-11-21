import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/map_data.dart';
import '../models/marker_data.dart';
import '../models/project.dart';
import '../models/token_data.dart';

class ProjectStorage {
  static const _projectsDirName = 'projects';
  static const _indexFileName = 'projects_index.json';
  final _uuid = const Uuid();

  Future<Directory> _rootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final projectsDir = Directory('${docs.path}/$_projectsDirName');
    if (!projectsDir.existsSync()) {
      projectsDir.createSync(recursive: true);
    }
    return projectsDir;
  }

  Future<File> _indexFile() async {
    final dir = await _rootDir();
    final file = File('${dir.path}/$_indexFileName');
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      file.writeAsStringSync(jsonEncode([]));
    }
    return file;
  }

  Future<List<ProjectMeta>> loadProjectList() async {
    final file = await _indexFile();
    final content = await file.readAsString();
    final List<dynamic> jsonList = content.isNotEmpty ? jsonDecode(content) : [];
    return jsonList
        .map((e) => ProjectMeta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Project> loadProject(String projectId) async {
    final dir = await _rootDir();
    final file = File('${dir.path}/$projectId/project.json');
    if (!file.existsSync()) {
      throw Exception('Project not found');
    }
    return Project.fromJsonString(await file.readAsString());
  }

  Future<Project> createNewProject(String name) async {
    final id = _uuid.v4();
    final dir = await _rootDir();
    final projectDir = Directory('${dir.path}/$id');
    projectDir.createSync(recursive: true);
    Directory('${projectDir.path}/images').createSync(recursive: true);

    final project = Project(
      id: id,
      name: name,
      maps: [],
      lastOpenedMapId: null,
    );
    await saveProject(project);
    await _saveIndexEntry(ProjectMeta(id: id, name: name));
    return project;
  }

  Future<void> _saveIndexEntry(ProjectMeta meta) async {
    final file = await _indexFile();
    final list = await loadProjectList();
    final filtered = list.where((e) => e.id != meta.id).toList();
    filtered.add(meta);
    await file.writeAsString(jsonEncode(filtered.map((e) => e.toJson()).toList()));
  }

  Future<void> saveProject(Project project) async {
    final dir = await _rootDir();
    final file = File('${dir.path}/${project.id}/project.json');
    file.createSync(recursive: true);
    await file.writeAsString(project.toJsonString());
    await _saveIndexEntry(ProjectMeta.fromProject(project));
  }

  Future<void> deleteProject(String projectId) async {
    final dir = await _rootDir();
    final projectDir = Directory('${dir.path}/$projectId');
    if (projectDir.existsSync()) {
      projectDir.deleteSync(recursive: true);
    }
    final file = await _indexFile();
    final list = await loadProjectList();
    final filtered = list.where((e) => e.id != projectId).toList();
    await file.writeAsString(jsonEncode(filtered.map((e) => e.toJson()).toList()));
  }

  Future<String> copyImageToProject(String projectId, String originalPath) async {
    final dir = await _rootDir();
    final imagesDir = Directory('${dir.path}/$projectId/images');
    imagesDir.createSync(recursive: true);
    final extension = originalPath.split('.').last;
    final newPath = '${imagesDir.path}/${_uuid.v4()}.$extension';
    final newFile = await File(originalPath).copy(newPath);
    return newFile.path;
  }

  MapData createMapData(String imagePath) => MapData(
        id: _uuid.v4(),
        name: 'Новая карта',
        imagePath: imagePath,
        markers: [],
        tokens: [],
      );

  MarkerData createMarkerData(double x, double y) => MarkerData(
        id: _uuid.v4(),
        x: x,
        y: y,
        label: 'Маркер',
      );

  TokenData createTokenData(double x, double y) => TokenData(
        id: _uuid.v4(),
        x: x,
        y: y,
        label: 'Токен',
        visibleForPlayers: true,
      );
}
