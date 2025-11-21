import 'package:flutter/material.dart';

import '../../models/map_data.dart';

class MapSelector extends StatelessWidget {
  final List<MapData> maps;
  final String? currentMapId;
  final void Function() onAddMap;
  final void Function(MapData map) onSelected;

  const MapSelector({
    super.key,
    required this.maps,
    required this.currentMapId,
    required this.onAddMap,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onAddMap,
            icon: const Icon(Icons.add),
            label: const Text('Добавить карту'),
          ),
          const SizedBox(width: 8),
          ...maps.map((map) {
            final selected = map.id == currentMapId;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(map.name),
                selected: selected,
                onSelected: (_) => onSelected(map),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
