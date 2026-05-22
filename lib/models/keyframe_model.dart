import 'package:flutter/material.dart';

enum EasingType { linear, easeIn, easeOut, easeInOut, bounce, elastic, cubic }
enum KeyframeProperty { opacity, scale, rotation, positionX, positionY, brightness, contrast, saturation, blur, hue, skewX, skewY }

class Keyframe {
  final String id;
  double timeMs;
  KeyframeProperty property;
  double value;
  EasingType easing;
  bool selected;

  Keyframe({
    required this.id,
    required this.timeMs,
    required this.property,
    required this.value,
    this.easing = EasingType.easeInOut,
    this.selected = false,
  });

  Keyframe copyWith({
    String? id,
    double? timeMs,
    KeyframeProperty? property,
    double? value,
    EasingType? easing,
    bool? selected,
  }) {
    return Keyframe(
      id: id ?? this.id,
      timeMs: timeMs ?? this.timeMs,
      property: property ?? this.property,
      value: value ?? this.value,
      easing: easing ?? this.easing,
      selected: selected ?? this.selected,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timeMs': timeMs,
    'property': property.index,
    'value': value,
    'easing': easing.index,
  };

  factory Keyframe.fromJson(Map<String, dynamic> json) => Keyframe(
    id: json['id'],
    timeMs: json['timeMs'].toDouble(),
    property: KeyframeProperty.values[json['property']],
    value: json['value'].toDouble(),
    easing: EasingType.values[json['easing']],
  );

  String get propertyLabel {
    switch (property) {
      case KeyframeProperty.opacity: return 'Opacity';
      case KeyframeProperty.scale: return 'Scale';
      case KeyframeProperty.rotation: return 'Rotation';
      case KeyframeProperty.positionX: return 'Position X';
      case KeyframeProperty.positionY: return 'Position Y';
      case KeyframeProperty.brightness: return 'Brightness';
      case KeyframeProperty.contrast: return 'Contrast';
      case KeyframeProperty.saturation: return 'Saturation';
      case KeyframeProperty.blur: return 'Blur';
      case KeyframeProperty.hue: return 'Hue';
      case KeyframeProperty.skewX: return 'Skew X';
      case KeyframeProperty.skewY: return 'Skew Y';
    }
  }

  IconData get propertyIcon {
    switch (property) {
      case KeyframeProperty.opacity: return Icons.opacity;
      case KeyframeProperty.scale: return Icons.zoom_in;
      case KeyframeProperty.rotation: return Icons.rotate_right;
      case KeyframeProperty.positionX: return Icons.swap_horiz;
      case KeyframeProperty.positionY: return Icons.swap_vert;
      case KeyframeProperty.brightness: return Icons.brightness_6;
      case KeyframeProperty.contrast: return Icons.contrast;
      case KeyframeProperty.saturation: return Icons.palette;
      case KeyframeProperty.blur: return Icons.blur_on;
      case KeyframeProperty.hue: return Icons.color_lens;
      case KeyframeProperty.skewX: return Icons.straighten;
      case KeyframeProperty.skewY: return Icons.straighten;
    }
  }

  double get minValue {
    switch (property) {
      case KeyframeProperty.opacity: return 0;
      case KeyframeProperty.scale: return 0;
      case KeyframeProperty.rotation: return -360;
      case KeyframeProperty.positionX: return -1000;
      case KeyframeProperty.positionY: return -1000;
      case KeyframeProperty.brightness: return -100;
      case KeyframeProperty.contrast: return -100;
      case KeyframeProperty.saturation: return -100;
      case KeyframeProperty.blur: return 0;
      case KeyframeProperty.hue: return -180;
      case KeyframeProperty.skewX: return -45;
      case KeyframeProperty.skewY: return -45;
    }
  }

  double get maxValue {
    switch (property) {
      case KeyframeProperty.opacity: return 100;
      case KeyframeProperty.scale: return 500;
      case KeyframeProperty.rotation: return 360;
      case KeyframeProperty.positionX: return 1000;
      case KeyframeProperty.positionY: return 1000;
      case KeyframeProperty.brightness: return 100;
      case KeyframeProperty.contrast: return 100;
      case KeyframeProperty.saturation: return 100;
      case KeyframeProperty.blur: return 50;
      case KeyframeProperty.hue: return 180;
      case KeyframeProperty.skewX: return 45;
      case KeyframeProperty.skewY: return 45;
    }
  }

  double get defaultValue {
    switch (property) {
      case KeyframeProperty.opacity: return 100;
      case KeyframeProperty.scale: return 100;
      case KeyframeProperty.rotation: return 0;
      case KeyframeProperty.positionX: return 0;
      case KeyframeProperty.positionY: return 0;
      case KeyframeProperty.brightness: return 0;
      case KeyframeProperty.contrast: return 0;
      case KeyframeProperty.saturation: return 0;
      case KeyframeProperty.blur: return 0;
      case KeyframeProperty.hue: return 0;
      case KeyframeProperty.skewX: return 0;
      case KeyframeProperty.skewY: return 0;
    }
  }
}
