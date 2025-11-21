import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/map_data.dart';
import '../../models/token_data.dart';

class MapCanvas extends StatelessWidget {
  final MapData map;
  final bool markerMode;
  final void Function(Offset relative) onTapForNewMarker;
  final void Function(String markerId)? onMarkerTap;
  final void Function(String tokenId)? onTokenTap;
  final void Function(String tokenId, Offset relative)? onTokenDrag;

  const MapCanvas({
    super.key,
    required this.map,
    required this.markerMode,
    required this.onTapForNewMarker,
    this.onMarkerTap,
    this.onTokenTap,
    this.onTokenDrag,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 3,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final local = details.localPosition;
              final relative = Offset(local.dx / size.width, local.dy / size.height);
              onTapForNewMarker(relative);
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    File(map.imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
                ...map.markers.map((m) => Positioned(
                      left: m.x * size.width - 12,
                      top: m.y * size.height - 12,
                      child: GestureDetector(
                        onTap: () => onMarkerTap?.call(m.id),
                        child: Column(
                          children: [
                            const Icon(Icons.push_pin, color: Colors.red),
                            Container(
                              padding: const EdgeInsets.all(4),
                              color: Colors.black54,
                              child: Text(
                                m.label,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            )
                          ],
                        ),
                      ),
                    )),
                ...map.tokens.map((t) => Positioned(
                      left: t.x * size.width - 20,
                      top: t.y * size.height - 20,
                      child: _DraggableToken(
                        token: t,
                        onDragDelta: (delta) {
                          final newX = t.x + delta.dx / size.width;
                          final newY = t.y + delta.dy / size.height;
                          onTokenDrag?.call(t.id, Offset(newX, newY));
                        },
                        onTap: () => onTokenTap?.call(t.id),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DraggableToken extends StatelessWidget {
  final TokenData token;
  final void Function(Offset delta) onDragDelta;
  final VoidCallback onTap;

  const _DraggableToken({
    required this.token,
    required this.onDragDelta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = token.imagePath != null
        ? CircleAvatar(backgroundImage: FileImage(File(token.imagePath!)))
        : const CircleAvatar(child: Icon(Icons.person));
    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (details) => onDragDelta(details.delta),
      child: Column(
        children: [avatar, Text(token.label)],
      ),
    );
  }
}
