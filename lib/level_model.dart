import 'package:flutter/material.dart';

class LevelModel {
  final int level;
  final int columns;
  final int rows;
  final Offset startPoint;
  final Offset targetPoint;
  final List<Offset> obstacles;

  LevelModel({
    required this.level,
    required this.columns,
    required this.rows,
    required this.startPoint,
    required this.targetPoint,
    required this.obstacles,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      level: json['level'],
      columns: json['gridSize']['columns'],
      rows: json['gridSize']['rows'],
      startPoint: Offset(
        (json['startPoint']['x'] as num).toDouble(),
        (json['startPoint']['y'] as num).toDouble(),
      ),
      targetPoint: Offset(
        (json['targetPoint']['x'] as num).toDouble(),
        (json['targetPoint']['y'] as num).toDouble(),
      ),
      obstacles: (json['obstacles'] as List)
          .map((o) => Offset((o['x'] as num).toDouble(), (o['y'] as num).toDouble()))
          .toList(),
    );
  }
}
