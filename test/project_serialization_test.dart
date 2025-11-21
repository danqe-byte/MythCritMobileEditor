import 'package:flutter_test/flutter_test.dart';
import 'package:myth_crit_mobile_editor/models/map_data.dart';
import 'package:myth_crit_mobile_editor/models/marker_data.dart';
import 'package:myth_crit_mobile_editor/models/project.dart';
import 'package:myth_crit_mobile_editor/models/token_data.dart';

void main() {
  test('Project serializes to and from json', () {
    final project = Project(
      id: '1',
      name: 'Test',
      lastOpenedMapId: 'map1',
      maps: [
        MapData(
          id: 'map1',
          name: 'Map',
          imagePath: '/tmp/map.png',
          markers: [MarkerData(id: 'm1', x: 0.5, y: 0.5, label: 'Mark')],
          tokens: [
            TokenData(
              id: 't1',
              x: 0.2,
              y: 0.3,
              label: 'Goblin',
              imagePath: null,
              visibleForPlayers: true,
            )
          ],
        )
      ],
    );

    final json = project.toJson();
    final restored = Project.fromJson(json);
    expect(restored.name, project.name);
    expect(restored.maps.first.tokens.first.label, 'Goblin');
    expect(restored.maps.first.markers.first.label, 'Mark');
  });
}
