import 'layer_model.dart';

enum AspectRatioType { ratio16x9, ratio9x16, ratio1x1, ratio4x5, ratio4x3 }

class ProjectSettings {
  double durationMs;
  double fps;
  AspectRatioType aspectRatio;
  int width;
  int height;
  String backgroundColor;

  ProjectSettings({
    this.durationMs = 10000,
    this.fps = 30,
    this.aspectRatio = AspectRatioType.ratio16x9,
    this.width = 1920,
    this.height = 1080,
    this.backgroundColor = '#080D18',
  });

  String get aspectRatioLabel {
    switch (aspectRatio) {
      case AspectRatioType.ratio16x9: return '16:9 Landscape';
      case AspectRatioType.ratio9x16: return '9:16 Portrait';
      case AspectRatioType.ratio1x1: return '1:1 Square';
      case AspectRatioType.ratio4x5: return '4:5 Portrait';
      case AspectRatioType.ratio4x3: return '4:3 Standard';
    }
  }

  double get aspectRatioValue {
    switch (aspectRatio) {
      case AspectRatioType.ratio16x9: return 16 / 9;
      case AspectRatioType.ratio9x16: return 9 / 16;
      case AspectRatioType.ratio1x1: return 1.0;
      case AspectRatioType.ratio4x5: return 4 / 5;
      case AspectRatioType.ratio4x3: return 4 / 3;
    }
  }

  ProjectSettings copyWith({
    double? durationMs, double? fps, AspectRatioType? aspectRatio,
    int? width, int? height, String? backgroundColor,
  }) => ProjectSettings(
    durationMs: durationMs ?? this.durationMs,
    fps: fps ?? this.fps,
    aspectRatio: aspectRatio ?? this.aspectRatio,
    width: width ?? this.width,
    height: height ?? this.height,
    backgroundColor: backgroundColor ?? this.backgroundColor,
  );

  Map<String, dynamic> toJson() => {
    'durationMs': durationMs,
    'fps': fps,
    'aspectRatio': aspectRatio.index,
    'width': width,
    'height': height,
    'backgroundColor': backgroundColor,
  };

  factory ProjectSettings.fromJson(Map<String, dynamic> j) => ProjectSettings(
    durationMs: (j['durationMs'] ?? 10000).toDouble(),
    fps: (j['fps'] ?? 30).toDouble(),
    aspectRatio: AspectRatioType.values[j['aspectRatio'] ?? 0],
    width: j['width'] ?? 1920,
    height: j['height'] ?? 1080,
    backgroundColor: j['backgroundColor'] ?? '#080D18',
  );
}

class ChessProject {
  final String id;
  String title;
  String description;
  DateTime createdAt;
  DateTime updatedAt;
  String thumbnailPath;
  List<EditorLayer> layers;
  ProjectSettings settings;

  ChessProject({
    required this.id,
    required this.title,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath = '',
    List<EditorLayer>? layers,
    ProjectSettings? settings,
  }) : layers = layers ?? [],
       settings = settings ?? ProjectSettings();

  ChessProject copyWith({
    String? id, String? title, String? description,
    DateTime? createdAt, DateTime? updatedAt, String? thumbnailPath,
    List<EditorLayer>? layers, ProjectSettings? settings,
  }) => ChessProject(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    layers: layers ?? List.from(this.layers),
    settings: settings ?? this.settings,
  );

  String get formattedDuration {
    final dur = Duration(milliseconds: settings.durationMs.toInt());
    final s = dur.inSeconds;
    final ms = (dur.inMilliseconds % 1000) ~/ 10;
    final m = dur.inMinutes;
    if (m > 0) {
      return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
    }
    return '${s.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'thumbnailPath': thumbnailPath,
    'layers': layers.map((l) => l.toJson()).toList(),
    'settings': settings.toJson(),
  };

  factory ChessProject.fromJson(Map<String, dynamic> json) => ChessProject(
    id: json['id'],
    title: json['title'],
    description: json['description'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    thumbnailPath: json['thumbnailPath'] ?? '',
    layers: (json['layers'] as List? ?? []).map((l) => EditorLayer.fromJson(l)).toList(),
    settings: ProjectSettings.fromJson(json['settings'] ?? {}),
  );
}
