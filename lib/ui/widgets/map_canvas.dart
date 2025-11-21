import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../models/map_data.dart';
import '../../models/token_data.dart';

class MapCanvas extends StatefulWidget {
  final MapData map;
  final void Function(Offset relative)? onTap;
  final void Function(String markerId)? onMarkerTap;
  final void Function(String tokenId)? onTokenTap;
  final void Function(String tokenId, Offset relative)? onTokenDrag;

  const MapCanvas({
    super.key,
    required this.map,
    this.onTap,
    this.onMarkerTap,
    this.onTokenTap,
    this.onTokenDrag,
  });

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  final TransformationController _transformationController = TransformationController();

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        const tokenSize = 64.0;
        return InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 3,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              if (widget.onTap == null) return;
              final inverse = Matrix4.inverted(_transformationController.value);
              final scenePoint = MatrixUtils.transformPoint(inverse, details.localPosition);
              final relative = Offset(
                (scenePoint.dx / size.width).clamp(0.0, 1.0),
                (scenePoint.dy / size.height).clamp(0.0, 1.0),
              );
              widget.onTap?.call(relative);
            },
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      File(widget.map.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                  ...widget.map.markers.map((m) => Positioned(
                        left: m.x * size.width - 20,
                        top: m.y * size.height - 20,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onMarkerTap?.call(m.id),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 2)),
                                  ],
                                ),
                                child: const Icon(Icons.push_pin, color: Colors.white, size: 20),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  m.label,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              )
                            ],
                          ),
                        ),
                      )),
                  ...widget.map.tokens.map((t) => Positioned(
                        left: t.x * size.width - tokenSize / 2,
                        top: t.y * size.height - tokenSize / 2,
                        child: _DraggableToken(
                          size: tokenSize,
                          token: t,
                          onDragDelta: (delta) {
                            final newX = t.x + delta.dx / size.width;
                            final newY = t.y + delta.dy / size.height;
                            widget.onTokenDrag?.call(t.id, Offset(newX, newY));
                          },
                          onTap: () => widget.onTokenTap?.call(t.id),
                        ),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DraggableToken extends StatelessWidget {
  final TokenData token;
  final double size;
  final void Function(Offset delta) onDragDelta;
  final VoidCallback onTap;

  const _DraggableToken({
    required this.token,
    required this.size,
    required this.onDragDelta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = token.imagePath != null
        ? CircleAvatar(backgroundImage: FileImage(File(token.imagePath!)), radius: size / 2)
        : CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.blueGrey.shade700,
            child: const Icon(Icons.person, color: Colors.white),
          );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onPanUpdate: (details) => onDragDelta(details.delta),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              token.label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
