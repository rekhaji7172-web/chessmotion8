import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/layer_model.dart';
import '../models/keyframe_model.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

class EditorProvider extends ChangeNotifier {
  ChessProject? _project;
  String? _selectedLayerId;
  String? _selectedKeyframeId;
  double _currentTimeMs = 0;
  bool _isPlaying = false;
  bool _showKeyframePanel = false;
  bool _showEffectsPanel = false;
  bool _showPropertiesPanel = true;
  double _timelineZoom = 1.0;
  double _timelineScroll = 0;
  KeyframeProperty _activeKeyframeProperty = KeyframeProperty.opacity;
  bool _snapToKeyframes = true;
  bool _onionSkin = false;

  ChessProject? get project => _project;
  String? get selectedLayerId => _selectedLayerId;
  String? get selectedKeyframeId => _selectedKeyframeId;
  double get currentTimeMs => _currentTimeMs;
  bool get isPlaying => _isPlaying;
  bool get showKeyframePanel => _showKeyframePanel;
  bool get showEffectsPanel => _showEffectsPanel;
  bool get showPropertiesPanel => _showPropertiesPanel;
  double get timelineZoom => _timelineZoom;
  double get timelineScroll => _timelineScroll;
  KeyframeProperty get activeKeyframeProperty => _activeKeyframeProperty;
  bool get snapToKeyframes => _snapToKeyframes;
  bool get onionSkin => _onionSkin;
  List<EditorLayer> get layers => _project?.layers ?? [];
  double get totalDurationMs => _project?.settings.durationMs ?? 10000;

  EditorLayer? get selectedLayer {
    if (_selectedLayerId == null) return null;
    try {
      return layers.firstWhere((l) => l.id == _selectedLayerId);
    } catch (_) {
      return null;
    }
  }

  String get currentTimeLabel => _msToLabel(_currentTimeMs);
  String get totalTimeLabel   => _msToLabel(totalDurationMs);

  String _msToLabel(double ms) {
    final total   = ms.toInt();
    final minutes = total ~/ 60000;
    final seconds = (total % 60000) ~/ 1000;
    final millis  = (total % 1000) ~/ 10;
    if (minutes > 0) {
      return '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${millis.toString().padLeft(2, '0')}';
    }
    return '${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(2, '0')}';
  }

  // ── Project ────────────────────────────────────────────────────────
  void loadProject(ChessProject project) {
    _project = project;
    _selectedLayerId = null;
    _currentTimeMs = 0;
    _isPlaying = false;
    notifyListeners();
  }

  void createNewProject({required String title, String description = ''}) {
    final project = ChessProject(
      id: _uuid.v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final boardLayer = EditorLayer(
      id: _uuid.v4(),
      name: 'Chess Board',
      type: LayerType.chessBoard,
      startMs: 0,
      endMs: project.settings.durationMs,
      color: AppTheme.layerColorAt(0),
      index: 0,
      data: {
        'lightColor': '#F0D9B5',
        'darkColor': '#B58863',
        'showCoordinates': true,
        'boardStyle': 0,
      },
    );
    project.layers.add(boardLayer);
    _project = project;
    notifyListeners();
  }

  // ── Layers ─────────────────────────────────────────────────────────
  void selectLayer(String? id) {
    _selectedLayerId = id;
    _selectedKeyframeId = null;
    notifyListeners();
  }

  void addLayer(LayerType type, {String? name}) {
    if (_project == null) return;
    final idx = layers.length;
    final id  = _uuid.v4();
    final layer = EditorLayer(
      id: id,
      name: name ?? _defaultLayerName(type, idx),
      type: type,
      startMs: _currentTimeMs,
      endMs: (_currentTimeMs + 5000).clamp(0, totalDurationMs),
      color: AppTheme.layerColorAt(idx),
      index: idx,
      data: _defaultLayerData(type),
    );
    _project!.layers.add(layer);
    _selectedLayerId = id;
    _markDirty();
  }

  void deleteLayer(String id) {
    if (_project == null) return;
    _project!.layers.removeWhere((l) => l.id == id);
    if (_selectedLayerId == id) _selectedLayerId = null;
    for (int i = 0; i < _project!.layers.length; i++) {
      _project!.layers[i] = _project!.layers[i].copyWith(index: i);
    }
    _markDirty();
  }

  void toggleLayerVisibility(String id) =>
      _updateLayer(id, (l) => l.copyWith(visible: !l.visible));

  void toggleLayerLock(String id) =>
      _updateLayer(id, (l) => l.copyWith(locked: !l.locked));

  void toggleLayerMute(String id) =>
      _updateLayer(id, (l) => l.copyWith(muted: !l.muted));

  void toggleLayerSolo(String id) =>
      _updateLayer(id, (l) => l.copyWith(solo: !l.solo));

  void toggleKeyframeMode(String id) =>
      _updateLayer(id, (l) => l.copyWith(keyframeMode: !l.keyframeMode));

  void reorderLayers(int oldIndex, int newIndex) {
    if (_project == null) return;
    if (newIndex > oldIndex) newIndex--;
    final layer = _project!.layers.removeAt(oldIndex);
    _project!.layers.insert(newIndex, layer);
    for (int i = 0; i < _project!.layers.length; i++) {
      _project!.layers[i] = _project!.layers[i].copyWith(index: i);
    }
    _markDirty();
  }

  void updateLayerTrim(String id, double startMs, double endMs) =>
      _updateLayer(id, (l) => l.copyWith(
        startMs: startMs.clamp(0, totalDurationMs),
        endMs: endMs.clamp(0, totalDurationMs),
      ));

  void updateLayerTransform(String id, LayerTransform transform) =>
      _updateLayer(id, (l) => l.copyWith(transform: transform));

  void updateLayerEffect(String id, LayerEffect effect) =>
      _updateLayer(id, (l) => l.copyWith(effect: effect));

  void updateLayerData(String id, Map<String, dynamic> data) =>
      _updateLayer(id, (l) => l.copyWith(data: {...l.data, ...data}));

  void updateLayerName(String id, String name) =>
      _updateLayer(id, (l) => l.copyWith(name: name));

  // ── Keyframes ──────────────────────────────────────────────────────
  void addKeyframe({
    required String layerId,
    required KeyframeProperty property,
    required double value,
    EasingType easing = EasingType.easeInOut,
  }) {
    if (_project == null) return;
    final idx = layers.indexWhere((l) => l.id == layerId);
    if (idx < 0) return;
    final layer = layers[idx];
    final kf = Keyframe(
      id: _uuid.v4(),
      timeMs: _currentTimeMs,
      property: property,
      value: value,
      easing: easing,
    );
    final kfs = List<Keyframe>.from(layer.keyframes)..add(kf);
    kfs.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    _project!.layers[idx] = layer.copyWith(keyframes: kfs);
    _selectedKeyframeId = kf.id;
    _markDirty();
  }

  void deleteKeyframe(String layerId, String keyframeId) {
    if (_project == null) return;
    final idx = layers.indexWhere((l) => l.id == layerId);
    if (idx < 0) return;
    final layer = layers[idx];
    final kfs = layer.keyframes.where((k) => k.id != keyframeId).toList();
    _project!.layers[idx] = layer.copyWith(keyframes: kfs);
    if (_selectedKeyframeId == keyframeId) _selectedKeyframeId = null;
    _markDirty();
  }

  void updateKeyframe(String layerId, Keyframe keyframe) {
    if (_project == null) return;
    final idx = layers.indexWhere((l) => l.id == layerId);
    if (idx < 0) return;
    final layer = layers[idx];
    final kfs = layer.keyframes
        .map((k) => k.id == keyframe.id ? keyframe : k)
        .toList()
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
    _project!.layers[idx] = layer.copyWith(keyframes: kfs);
    _markDirty();
  }

  void selectKeyframe(String? id) {
    _selectedKeyframeId = id;
    notifyListeners();
  }

  // ── Playback ───────────────────────────────────────────────────────
  void setCurrentTime(double ms) {
    _currentTimeMs = ms.clamp(0, totalDurationMs);
    notifyListeners();
  }

  void seekTo(double ms) => setCurrentTime(ms);

  void togglePlay() { _isPlaying = !_isPlaying; notifyListeners(); }
  void play()       { _isPlaying = true;         notifyListeners(); }
  void pause()      { _isPlaying = false;        notifyListeners(); }

  void stop() {
    _isPlaying = false;
    _currentTimeMs = 0;
    notifyListeners();
  }

  void stepForward() {
    final fd = 1000.0 / (_project?.settings.fps ?? 30);
    setCurrentTime(_currentTimeMs + fd);
  }

  void stepBackward() {
    final fd = 1000.0 / (_project?.settings.fps ?? 30);
    setCurrentTime(_currentTimeMs - fd);
  }

  void advanceTime(double deltaMs) {
    _currentTimeMs += deltaMs;
    if (_currentTimeMs >= totalDurationMs) _currentTimeMs = 0;
    notifyListeners();
  }

  // ── UI ─────────────────────────────────────────────────────────────
  void toggleKeyframePanel()   { _showKeyframePanel   = !_showKeyframePanel;   notifyListeners(); }
  void toggleEffectsPanel()    { _showEffectsPanel    = !_showEffectsPanel;    notifyListeners(); }
  void togglePropertiesPanel() { _showPropertiesPanel = !_showPropertiesPanel; notifyListeners(); }

  void setActiveKeyframeProperty(KeyframeProperty prop) {
    _activeKeyframeProperty = prop;
    notifyListeners();
  }

  void setTimelineZoom(double zoom) {
    _timelineZoom = zoom.clamp(0.25, 8.0);
    notifyListeners();
  }

  void setTimelineScroll(double scroll) {
    _timelineScroll = scroll.clamp(0, double.infinity);
    notifyListeners();
  }

  void toggleSnapToKeyframes() { _snapToKeyframes = !_snapToKeyframes; notifyListeners(); }
  void toggleOnionSkin()       { _onionSkin       = !_onionSkin;       notifyListeners(); }

  void updateProjectSettings(ProjectSettings settings) {
    if (_project == null) return;
    _project = _project!.copyWith(settings: settings);
    _markDirty();
  }

  void updateProjectTitle(String title) {
    if (_project == null) return;
    _project = _project!.copyWith(title: title);
    _markDirty();
  }

  // ── Interpolation ──────────────────────────────────────────────────
  double getInterpolatedValue(
      EditorLayer layer, KeyframeProperty property, double timeMs) {
    final kfs = layer.keyframes
        .where((k) => k.property == property)
        .toList()
      ..sort((a, b) => a.timeMs.compareTo(b.timeMs));

    if (kfs.isEmpty) return _defaultForProperty(property);
    if (kfs.length == 1) return kfs[0].value;
    if (timeMs <= kfs.first.timeMs) return kfs.first.value;
    if (timeMs >= kfs.last.timeMs)  return kfs.last.value;

    for (int i = 0; i < kfs.length - 1; i++) {
      if (timeMs >= kfs[i].timeMs && timeMs <= kfs[i + 1].timeMs) {
        final ratio = (timeMs - kfs[i].timeMs) /
            (kfs[i + 1].timeMs - kfs[i].timeMs);
        final et = _applyEasing(ratio, kfs[i + 1].easing);
        return kfs[i].value + (kfs[i + 1].value - kfs[i].value) * et;
      }
    }
    return kfs.last.value;
  }

  double _defaultForProperty(KeyframeProperty p) {
    switch (p) {
      case KeyframeProperty.opacity:    return 100;
      case KeyframeProperty.scale:      return 100;
      case KeyframeProperty.rotation:   return 0;
      case KeyframeProperty.positionX:  return 0;
      case KeyframeProperty.positionY:  return 0;
      case KeyframeProperty.brightness: return 0;
      case KeyframeProperty.contrast:   return 0;
      case KeyframeProperty.saturation: return 0;
      case KeyframeProperty.blur:       return 0;
      case KeyframeProperty.hue:        return 0;
      case KeyframeProperty.skewX:      return 0;
      case KeyframeProperty.skewY:      return 0;
    }
  }

  double _applyEasing(double t, EasingType easing) {
    switch (easing) {
      case EasingType.linear:    return t;
      case EasingType.easeIn:    return t * t;
      case EasingType.easeOut:   return t * (2 - t);
      case EasingType.easeInOut: return t < 0.5 ? 2*t*t : -1+(4-2*t)*t;
      case EasingType.bounce:    return _bounceEase(t);
      case EasingType.elastic:   return _elasticEase(t);
      case EasingType.cubic:     return t * t * t;
    }
  }

  double _bounceEase(double t) {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      final n = t - 1.5 / 2.75;
      return 7.5625 * n * n + 0.75;
    } else if (t < 2.5 / 2.75) {
      final n = t - 2.25 / 2.75;
      return 7.5625 * n * n + 0.9375;
    } else {
      final n = t - 2.625 / 2.75;
      return 7.5625 * n * n + 0.984375;
    }
  }

  double _elasticEase(double t) {
    if (t == 0 || t == 1) return t;
    return math.pow(2.0, -10.0 * t).toDouble() *
        math.sin((t - 0.1) * 5.0 * math.pi) + 1.0;
  }

  // ── Helpers ────────────────────────────────────────────────────────
  void _updateLayer(String id, EditorLayer Function(EditorLayer) updater) {
    if (_project == null) return;
    final idx = layers.indexWhere((l) => l.id == id);
    if (idx < 0) return;
    _project!.layers[idx] = updater(_project!.layers[idx]);
    _markDirty();
  }

  void _markDirty() {
    if (_project != null) {
      _project = _project!.copyWith(updatedAt: DateTime.now());
    }
    notifyListeners();
  }

  String _defaultLayerName(LayerType type, int idx) {
    switch (type) {
      case LayerType.chessBoard: return 'Chess Board ${idx + 1}';
      case LayerType.chessPiece: return 'Chess Piece ${idx + 1}';
      case LayerType.text:       return 'Text ${idx + 1}';
      case LayerType.image:      return 'Image ${idx + 1}';
      case LayerType.shape:      return 'Shape ${idx + 1}';
      case LayerType.effect:     return 'Effect ${idx + 1}';
      case LayerType.audio:      return 'Audio ${idx + 1}';
      case LayerType.video:      return 'Video ${idx + 1}';
    }
  }

  Map<String, dynamic> _defaultLayerData(LayerType type) {
    switch (type) {
      case LayerType.chessBoard:
        return {
          'lightColor': '#F0D9B5',
          'darkColor': '#B58863',
          'showCoordinates': true,
          'boardStyle': 0,
        };
      case LayerType.chessPiece:
        return {'piece': 'K', 'pieceColor': 'white', 'square': 'e4'};
      case LayerType.text:
        return {
          'text': 'Your Text Here',
          'fontSize': 48,
          'fontWeight': 'bold',
          'textColor': '#FFFFFF',
          'textAlign': 'center',
        };
      case LayerType.shape:
        return {
          'shapeType': 'rectangle',
          'fillColor': '#1565C0',
          'strokeColor': '#FFFFFF',
          'strokeWidth': 2,
        };
      case LayerType.effect:
        return {'effectType': 'glow', 'intensity': 0.5};
      default:
        return {};
    }
  }
}
