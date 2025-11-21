import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/map_data.dart';
import '../../models/marker_data.dart';
import '../../models/project.dart';
import '../../models/token_data.dart';
import '../../services/export_service.dart';
import '../../services/image_service.dart';
import '../../services/project_storage.dart';
import '../widgets/map_canvas.dart';
import '../widgets/map_selector.dart';

class MapEditorScreen extends StatefulWidget {
  static const routeName = '/map-editor';

  final String projectId;
  const MapEditorScreen({super.key, required this.projectId});

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  final ProjectStorage _storage = ProjectStorage();
  final ImageService _imageService = ImageService();
  final ExportService _exportService = ExportService();

  Project? _project;
  MapData? _currentMap;
  bool _markerMode = false;
  Timer? _saveTimer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final project = await _storage.loadProject(widget.projectId);
    setState(() {
      _project = project;
      _currentMap = project.getMapById(project.lastOpenedMapId) ?? project.maps.firstOrNull;
      _loading = false;
    });
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () async {
      final project = _project;
      if (project != null) {
        await _storage.saveProject(project);
      }
    });
  }

  Future<void> _addMap() async {
    final path = await _imageService.pickImageFromGallery();
    if (path == null) return;
    final project = _project;
    if (project == null) return;
    final copied = await _storage.copyImageToProject(project.id, path);
    final map = _storage.createMapData(copied);

    final nameController = TextEditingController(text: map.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Название карты'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Сохранить'),
          )
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      map.name = name;
    }

    project.maps.add(map);
    project.lastOpenedMapId = map.id;
    setState(() {
      _currentMap = map;
    });
    _scheduleSave();
  }

  void _setCurrentMap(MapData map) {
    final project = _project;
    if (project == null) return;
    project.lastOpenedMapId = map.id;
    setState(() {
      _currentMap = map;
    });
    _scheduleSave();
  }

  void _addMarkerAt(Offset relative) {
    final map = _currentMap;
    final project = _project;
    if (map == null || project == null) return;
    final marker = _storage.createMarkerData(relative.dx, relative.dy);
    map.markers.add(marker);
    _scheduleSave();
    _editMarker(marker);
  }

  void _addTokenAt(Offset relative) {
    final map = _currentMap;
    final project = _project;
    if (map == null || project == null) return;
    final token = _storage.createTokenData(relative.dx, relative.dy);
    map.tokens.add(token);
    _scheduleSave();
    _editToken(token);
  }

  void _updateTokenPosition(String tokenId, Offset relative) {
    final map = _currentMap;
    if (map == null) return;
    final token = map.tokens.firstWhere((t) => t.id == tokenId);
    token
      ..x = relative.dx.clamp(0.0, 1.0)
      ..y = relative.dy.clamp(0.0, 1.0);
    setState(() {});
    _scheduleSave();
  }

  Future<void> _editMarker(MarkerData marker) async {
    final map = _currentMap;
    final project = _project;
    if (map == null || project == null) return;
    final labelController = TextEditingController(text: marker.label);
    String? targetMapId = marker.targetMapId;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            DropdownButtonFormField<String?>(
              value: targetMapId,
              decoration: const InputDecoration(labelText: 'Целевая карта'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Нет')),
                ...project.maps.map(
                  (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                ),
              ],
              onChanged: (value) => targetMapId = value,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Удалить'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      marker.label = labelController.text;
      marker.targetMapId = targetMapId;
      _scheduleSave();
    } else if (result == false) {
      map.markers.removeWhere((m) => m.id == marker.id);
      setState(() {});
      _scheduleSave();
    }
  }

  Future<void> _editToken(TokenData token) async {
    final project = _project;
    if (project == null) return;
    final labelController = TextEditingController(text: token.label);
    bool visible = token.visibleForPlayers;
    String? imagePath = token.imagePath;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            CheckboxListTile(
              value: visible,
              onChanged: (val) {
                setState(() {
                  visible = val ?? true;
                });
              },
              title: const Text('Показывать игрокам (на ТВ)'),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await _imageService.pickImageFromGallery();
                    if (picked != null) {
                      final copied = await _storage.copyImageToProject(project.id, picked);
                      setState(() {
                        imagePath = copied;
                      });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Иконка токена'),
                ),
                const SizedBox(width: 8),
                if (imagePath != null) const Text('Выбрано'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Удалить'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      token.label = labelController.text;
      token.visibleForPlayers = visible;
      token.imagePath = imagePath;
      _scheduleSave();
    } else if (result == false) {
      _currentMap?.tokens.removeWhere((t) => t.id == token.id);
      setState(() {});
      _scheduleSave();
    }
  }

  Future<void> _exportScene() async {
    final map = _currentMap;
    if (map == null) return;
    final tokens = map.tokens.where((t) => t.visibleForPlayers).toList();
    final png = await _exportService.captureWidgetToPng(() => _SceneExportView(
          map: map,
          tokens: tokens,
        ));
    await _exportService.savePngToGallery(png, name: map.name);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сцена экспортирована в галерею')),
      );
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final map = _currentMap;
    final project = _project;
    return Scaffold(
      appBar: AppBar(
        title: Text(project?.name ?? 'Проект'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _markerMode = !_markerMode),
            icon: Icon(_markerMode ? Icons.push_pin : Icons.push_pin_outlined),
            tooltip: 'Добавить маркер',
          ),
          IconButton(
            onPressed: () {
              setState(() => _markerMode = false);
              _addTokenAt(const Offset(0.5, 0.5));
            },
            icon: const Icon(Icons.person_add),
            tooltip: 'Добавить токен',
          ),
          IconButton(
            onPressed: _exportScene,
            icon: const Icon(Icons.tv),
            tooltip: 'Экспорт сцены',
          ),
        ],
      ),
      body: project == null
          ? const Center(child: Text('Проект не найден'))
          : Column(
              children: [
                MapSelector(
                  maps: project.maps,
                  currentMapId: map?.id,
                  onAddMap: _addMap,
                  onSelected: _setCurrentMap,
                ),
                Expanded(
                  child: map == null
                      ? const Center(child: Text('Добавьте карту'))
                      : MapCanvas(
                          map: map,
                          markerMode: _markerMode,
                          onTapForNewMarker: (pos) {
                            if (_markerMode) {
                              _addMarkerAt(pos);
                              setState(() => _markerMode = false);
                            } else {
                              _addTokenAt(pos);
                            }
                          },
                          onMarkerTap: (id) {
                            final marker = map.markers.firstWhere((m) => m.id == id);
                            _editMarker(marker);
                          },
                          onTokenTap: (id) {
                            final token = map.tokens.firstWhere((t) => t.id == id);
                            _editToken(token);
                          },
                          onTokenDrag: _updateTokenPosition,
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMap,
        icon: const Icon(Icons.map),
        label: const Text('Добавить карту'),
      ),
    );
  }
}

class _SceneExportView extends StatelessWidget {
  final MapData map;
  final List<TokenData> tokens;
  const _SceneExportView({required this.map, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    File(map.imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
                ...tokens.map(
                  (t) => Positioned(
                    left: t.x * size.width,
                    top: t.y * size.height,
                    child: _TokenView(token: t),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TokenView extends StatelessWidget {
  final TokenData token;
  const _TokenView({required this.token});

  @override
  Widget build(BuildContext context) {
    final widget = token.imagePath != null
        ? CircleAvatar(backgroundImage: FileImage(File(token.imagePath!)))
        : const CircleAvatar(child: Icon(Icons.person));
    return Column(
      children: [
        widget,
        Text(
          token.label,
          style: const TextStyle(color: Colors.white),
        )
      ],
    );
  }
}
