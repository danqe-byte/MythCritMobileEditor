import 'package:flutter/material.dart';

import '../../models/project.dart';
import '../../services/image_service.dart';
import '../../services/project_storage.dart';
import 'map_editor_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ProjectStorage _storage = ProjectStorage();
  final ImageService _imageService = ImageService();
  late Future<List<ProjectMeta>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = _storage.loadProjectList();
  }

  Future<void> _refresh() async {
    setState(() {
      _projectsFuture = _storage.loadProjectList();
    });
  }

  Future<void> _createProject() async {
    final nameController = TextEditingController(text: 'Новый проект');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать проект'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Создать'),
          )
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await _storage.createNewProject(name);
      if (mounted) _refresh();
    }
  }

  Future<void> _renameProject(ProjectMeta meta) async {
    final controller = TextEditingController(text: meta.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать проект'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Название'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      final project = await _storage.loadProject(meta.id);
      project.name = result;
      await _storage.saveProject(project);
      if (mounted) _refresh();
    }
  }

  Future<void> _deleteProject(ProjectMeta meta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить проект?'),
        content: Text('Проект "${meta.name}" будет удалён.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storage.deleteProject(meta.id);
      if (mounted) _refresh();
    }
  }

  void _openProject(ProjectMeta meta) {
    Navigator.pushNamed(context, MapEditorScreen.routeName, arguments: {'projectId': meta.id}).then((_) {
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Проекты'),
        actions: [
          IconButton(onPressed: _createProject, icon: const Icon(Icons.add)),
        ],
      ),
      body: FutureBuilder<List<ProjectMeta>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final projects = snapshot.data!;
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Нет проектов'),
                  const SizedBox(height: 8),
                  ElevatedButton(onPressed: _createProject, child: const Text('Новый проект')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final meta = projects[index];
                return ListTile(
                  title: Text(meta.name),
                  onTap: () => _openProject(meta),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameProject(meta);
                      } else if (value == 'delete') {
                        _deleteProject(meta);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'rename', child: Text('Переименовать')),
                      const PopupMenuItem(value: 'delete', child: Text('Удалить')),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}
