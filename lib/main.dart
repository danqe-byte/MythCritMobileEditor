import 'package:flutter/material.dart';

import 'ui/screens/map_editor_screen.dart';
import 'ui/screens/project_list_screen.dart';

void main() {
  runApp(const MythCritApp());
}

class MythCritApp extends StatelessWidget {
  const MythCritApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Myth Crit Map Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const ProjectListScreen(),
      routes: {
        MapEditorScreen.routeName: (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MapEditorScreen(projectId: args['projectId'] as String);
        },
      },
    );
  }
}
