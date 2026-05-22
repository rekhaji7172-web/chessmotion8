import 'package:flutter/material.dart';
import 'keyframe_model.dart';

enum LayerType { chessBoard, chessPiece, text, image, shape, effect, audio, video }
enum BlendMode2 { normal, multiply, screen, overlay, softLight, hardLight, colorDodge, colorBurn, difference }

class LayerTransform {
  double x;
  double y;
  double scaleX;
  double scaleY;
  double rotation;
  double opacity;
  double skewX;
  double skewY;

  LayerTransform({
    this.x = 0,
    this.y = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.rotation = 0,
    this.opacity = 1,
    this.skewX = 0,
    this.skewY = 0,
  });

  LayerTransform copyWith({
    double? x, double? y, double? scaleX, double? scaleY,
    double? rotation, double? opacity, double? skewX, double? skewY,
  }) => LayerTransform(
    x: x ?? this.x, y: y ?? this.y,
    scaleX: scaleX ?? this.scaleX, scaleY: scaleY ?? this.scaleY,
    rotation: rotation ?? this.rotation, opacity: opacity ?? this.opacity,
    skewX: skewX ?? this.skewX, skewY: skewY ?? this.skewY,
  );

  Map<String, dynamic> toJson() => {
    'x': x, 'y': y, 'scaleX': scaleX, 'scaleY': scaleY,
    'rotation': rotation, 'opacity': opacity, 'skewX': skewX, 'skewY': skewY,
  };

  factory LayerTransform.fromJson(Map<String, dynamic> j) => LayerTransform(
    x: (j['x'] ?? 0).toDouble(), y: (j['y'] ?? 0).toDouble(),
    scaleX: (j['scaleX'] ?? 1).toDouble(), scaleY: (j['scaleY'] ?? 1).toDouble(),
    rotation: (j['rotation'] ?? 0).toDouble(), opacity: (j['opacity'] ?? 1).toDouble(),
    skewX: (j['skewX'] ?? 0).toDouble(), skewY: (j['skewY'] ?? 0).toDouble(),
  );
}

class LayerEffect {
  double brightness;
  double contrast;
  double saturation;
  double blur;
  double hue;
  Color? colorOverlay;
  double colorOverlayOpacity;

  LayerEffect({
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.blur = 0,
    this.hue = 0,
    this.colorOverlay,
    this.colorOverlayOpacity = 0,
  });

  LayerEffect copyWith({
    double? brightness, double? contrast, double? saturation,
    double? blur, double? hue, Color? colorOverlay, double? colorOverlayOpacity,
  }) => LayerEffect(
    brightness: brightness ?? this.brightness,
    contrast: contrast ?? this.contrast,
    saturation: saturation ?? this.saturation,
    blur: blur ?? this.blur,
    hue: hue ?? this.hue,
    colorOverlay: colorOverlay ?? this.colorOverlay,
    colorOverlayOpacity: colorOverlayOpacity ?? this.colorOverlayOpacity,
  );

  Map<String, dynamic> toJson() => {
    'brightness': brightness, 'contrast': contrast, 'saturation': saturation,
    'blur': blur, 'hue': hue,
    'colorOverlay': colorOverlay?.value,
    'colorOverlayOpacity': colorOverlayOpacity,
  };

  factory LayerEffect.fromJson(Map<String, dynamic> j) => LayerEffect(
    brightness: (j['brightness'] ?? 0).toDouble(),
    contrast: (j['contrast'] ?? 0).toDouble(),
    saturation: (j['saturation'] ?? 0).toDouble(),
    blur: (j['blur'] ?? 0).toDouble(),
    hue: (j['hue'] ?? 0).toDouble(),
    colorOverlay: j['colorOverlay'] != null ? Color(j['colorOverlay']) : null,
    colorOverlayOpacity: (j['colorOverlayOpacity'] ?? 0).toDouble(),
  );
}

class EditorLayer {
  final String id;
  String name;
  LayerType type;
  bool visible;
  bool locked;
  bool muted;
  bool solo;
  bool keyframeMode;
  double startMs;
  double endMs;
  Color color;
  int index;
  LayerTransform transform;
  LayerEffect effect;
  List<Keyframe> keyframes;
  BlendMode2 blendMode;
  Map<String, dynamic> data;

  EditorLayer({
    required this.id,
    required this.name,
    required this.type,
    this.visible = true,
    this.locked = false,
    this.muted = false,
    this.solo = false,
    this.keyframeMode = false,
    required this.startMs,
    required this.endMs,
    required this.color,
    required this.index,
    LayerTransform? transform,
    LayerEffect? effect,
    List<Keyframe>? keyframes,
    this.blendMode = BlendMode2.normal,
    Map<String, dynamic>? data,
  }) : transform = transform ?? LayerTransform(),
       effect = effect ?? LayerEffect(),
       keyframes = keyframes ?? [],
       data = data ?? {};

  double get durationMs => endMs - startMs;

  EditorLayer copyWith({
    String? id, String? name, LayerType? type,
    bool? visible, bool? locked, bool? muted, bool? solo, bool? keyframeMode,
    double? startMs, double? endMs, Color? color, int? index,
    LayerTransform? transform, LayerEffect? effect,
    List<Keyframe>? keyframes, BlendMode2? blendMode,
    Map<String, dynamic>? data,
  }) => EditorLayer(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    visible: visible ?? this.visible,
    locked: locked ?? this.locked,
    muted: muted ?? this.muted,
    solo: solo ?? this.solo,
    keyframeMode: keyframeMode ?? this.keyframeMode,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
    color: color ?? this.color,
    index: index ?? this.index,
    transform: transform ?? this.transform,
    effect: effect ?? this.effect,
    keyframes: keyframes ?? List.from(this.keyframes),
    blendMode: blendMode ?? this.blendMode,
    data: data ?? Map.from(this.data),
  );

  String get typeLabel {
    switch (type) {
      case LayerType.chessBoard: return 'Chess Board';
      case LayerType.chessPiece: return 'Chess Piece';
      case LayerType.text: return 'Text';
      case LayerType.image: return 'Image';
      case LayerType.shape: return 'Shape';
      case LayerType.effect: return 'Effect';
      case LayerType.audio: return 'Audio';
      case LayerType.video: return 'Video';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case LayerType.chessBoard: return Icons.grid_4x4;
      case LayerType.chessPiece: return Icons.extension;
      case LayerType.text: return Icons.title;
      case LayerType.image: return Icons.image;
      case LayerType.shape: return Icons.crop_square;
      case LayerType.effect: return Icons.auto_fix_high;
      case LayerType.audio: return Icons.music_note;
      case LayerType.video: return Icons.videocam;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.index,
    'visible': visible,
    'locked': locked,
    'muted': muted,
    'solo': solo,
    'keyframeMode': keyframeMode,
    'startMs': startMs,
    'endMs': endMs,
    'color': color.value,
    'index': index,
    'transform': transform.toJson(),
    'effect': effect.toJson(),
    'keyframes': keyframes.map((k) => k.toJson()).toList(),
    'blendMode': blendMode.index,
    'data': data,
  };

  factory EditorLayer.fromJson(Map<String, dynamic> json) => EditorLayer(
    id: json['id'],
    name: json['name'],
    type: LayerType.values[json['type']],
    visible: json['visible'] ?? true,
    locked: json['locked'] ?? false,
    muted: json['muted'] ?? false,
    solo: json['solo'] ?? false,
    keyframeMode: json['keyframeMode'] ?? false,
    startMs: json['startMs'].toDouble(),
    endMs: json['endMs'].toDouble(),
    color: Color(json['color']),
    index: json['index'],
    transform: LayerTransform.fromJson(json['transform'] ?? {}),
    effect: LayerEffect.fromJson(json['effect'] ?? {}),
    keyframes: (json['keyframes'] as List? ?? []).map((k) => Keyframe.fromJson(k)).toList(),
    blendMode: BlendMode2.values[json['blendMode'] ?? 0],
    data: Map<String, dynamic>.from(json['data'] ?? {}),
  );
}
