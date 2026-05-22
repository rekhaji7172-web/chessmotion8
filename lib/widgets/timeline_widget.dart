import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';
import '../models/layer_model.dart';
import '../models/keyframe_model.dart';
import '../theme/app_theme.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});
  @override State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  final ScrollController _hScroll = ScrollController();
  final ScrollController _layerScroll = ScrollController();
  static const double _labelW = 140.0;
  static const double _rowH   = 52.0;
  static const double _rulerH = 28.0;

  @override
  void dispose() {
    _hScroll.dispose();
    _layerScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    final layers = editor.layers;
    final zoom   = editor.timelineZoom;
    final total  = editor.totalDurationMs;
    final pxPerMs = zoom * 0.12;
    final totalW  = total * pxPerMs;

    return Container(
      color: AppTheme.bgDark,
      child: Column(children: [
        // ── Toolbar ───────────────────────────────────────
        _TimelineToolbar(zoom: zoom, editor: editor),
        const Divider(height: 1, color: AppTheme.divider),

        // ── Main Area ─────────────────────────────────────
        Expanded(child: Row(children: [
          // Layer labels
          SizedBox(
            width: _labelW,
            child: Column(children: [
              Container(height: _rulerH, color: AppTheme.bgCard,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: const Text('LAYERS',
                    style: TextStyle(color: AppTheme.textHint,
                        fontSize: 9, letterSpacing: 1.2))),
              const Divider(height: 1, color: AppTheme.divider),
              Expanded(
                child: ListView.builder(
                  controller: _layerScroll,
                  itemCount: layers.length,
                  itemExtent: _rowH,
                  itemBuilder: (_, i) => _LayerLabel(
                    layer: layers[i],
                    isSelected: editor.selectedLayerId == layers[i].id,
                    onTap: () => editor.selectLayer(layers[i].id),
                    onVisibility: () => editor.toggleLayerVisibility(layers[i].id),
                    onLock: () => editor.toggleLayerLock(layers[i].id),
                    onKeyframe: () => editor.toggleKeyframeMode(layers[i].id),
                  ),
                ),
              ),
            ]),
          ),
          const VerticalDivider(width: 1, color: AppTheme.divider),

          // Timeline tracks
          Expanded(child: GestureDetector(
            onTapDown: (d) {
              final ms = (_hScroll.offset + d.localPosition.dx) / pxPerMs;
              editor.seekTo(ms);
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollUpdateNotification) {
                  editor.setTimelineScroll(_hScroll.offset);
                }
                return false;
              },
              child: SingleChildScrollView(
                controller: _hScroll,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: totalW + 80,
                  child: Column(children: [
                    // Ruler
                    SizedBox(height: _rulerH,
                        child: _TimeRuler(totalMs: total, pxPerMs: pxPerMs)),
                    const Divider(height: 1, color: AppTheme.divider),
                    // Tracks + Playhead
                    Expanded(child: Stack(children: [
                      ListView.builder(
                        controller: _layerScroll,
                        itemCount: layers.length,
                        itemExtent: _rowH,
                        itemBuilder: (_, i) => _LayerTrack(
                          layer: layers[i],
                          totalMs: total,
                          pxPerMs: pxPerMs,
                          isSelected: editor.selectedLayerId == layers[i].id,
                          currentTimeMs: editor.currentTimeMs,
                          onTrimStart: (ms) => editor.updateLayerTrim(
                              layers[i].id, ms, layers[i].endMs),
                          onTrimEnd: (ms) => editor.updateLayerTrim(
                              layers[i].id, layers[i].startMs, ms),
                          onKeyframeTap: (kf) {
                            editor.selectLayer(layers[i].id);
                            editor.selectKeyframe(kf.id);
                            editor.seekTo(kf.timeMs);
                          },
                        ),
                      ),
                      // Playhead
                      _Playhead(
                        currentTimeMs: editor.currentTimeMs,
                        pxPerMs: pxPerMs,
                        totalH: layers.length * _rowH,
                      ),
                    ])),
                  ]),
                ),
              ),
            ),
          )),
        ])),
      ]),
    );
  }
}

// ── Timeline Toolbar ───────────────────────────────────────────────────────
class _TimelineToolbar extends StatelessWidget {
  final double zoom;
  final EditorProvider editor;
  const _TimelineToolbar({required this.zoom, required this.editor});

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    color: AppTheme.bgCard,
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(children: [
      _TlBtn(icon: Icons.undo, tip: 'Undo', onTap: () {}),
      _TlBtn(icon: Icons.redo, tip: 'Redo', onTap: () {}),
      _div(),
      _TlBtn(icon: Icons.cut, tip: 'Split', onTap: () {}),
      _TlBtn(icon: Icons.content_copy, tip: 'Duplicate', onTap: () {}),
      _TlBtn(icon: Icons.delete_outline, tip: 'Delete', onTap: () {
        if (editor.selectedLayerId != null) {
          editor.deleteLayer(editor.selectedLayerId!);
        }
      }),
      _div(),
      _TlBtn(
        icon: Icons.near_me,
        tip: 'Snap',
        onTap: editor.toggleSnapToKeyframes,
        active: editor.snapToKeyframes,
      ),
      _TlBtn(
        icon: Icons.layers_outlined,
        tip: 'Onion Skin',
        onTap: editor.toggleOnionSkin,
        active: editor.onionSkin,
      ),
      const Spacer(),
      // Zoom controls
      const Text('Zoom', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      const SizedBox(width: 6),
      _ZoomBtn(icon: Icons.remove, onTap: () => editor.setTimelineZoom(zoom - 0.25)),
      SizedBox(
        width: 38,
        child: Text('${zoom.toStringAsFixed(1)}x',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      _ZoomBtn(icon: Icons.add, onTap: () => editor.setTimelineZoom(zoom + 0.25)),
    ]),
  );

  Widget _div() => Container(
    width: 1, height: 18, color: AppTheme.border,
    margin: const EdgeInsets.symmetric(horizontal: 4));
}

class _TlBtn extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  final bool active;
  const _TlBtn({required this.icon, required this.tip,
    required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: active ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon,
          color: active ? AppTheme.primary : AppTheme.textSecondary, size: 16),
      ),
    ),
  );
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(4)),
      child: Icon(icon, color: AppTheme.textSecondary, size: 14),
    ),
  );
}

// ── Time Ruler ─────────────────────────────────────────────────────────────
class _TimeRuler extends StatelessWidget {
  final double totalMs, pxPerMs;
  const _TimeRuler({required this.totalMs, required this.pxPerMs});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(totalMs * pxPerMs, 28),
    painter: _RulerPainter(totalMs: totalMs, pxPerMs: pxPerMs),
  );
}

class _RulerPainter extends CustomPainter {
  final double totalMs, pxPerMs;
  const _RulerPainter({required this.totalMs, required this.pxPerMs});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.bgCard,
    );

    final tickPaint = Paint()..color = AppTheme.textHint..strokeWidth = 1;
    const labelStyle = TextStyle(color: AppTheme.textHint, fontSize: 9);

    final interval = _getInterval();
    double t = 0;
    while (t <= totalMs) {
      final x = t * pxPerMs;
      final isMajor = (t % (interval * 5)) < 0.1;
      canvas.drawLine(Offset(x, isMajor ? 10 : 18), Offset(x, size.height), tickPaint);
      if (isMajor) {
        final label = _formatTime(t);
        final tp = TextPainter(
          text: TextSpan(text: label, style: labelStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x + 2, 1));
      }
      t += interval;
    }
  }

  double _getInterval() {
    if (pxPerMs > 0.5) return 100;
    if (pxPerMs > 0.1) return 500;
    return 1000;
  }

  String _formatTime(double ms) {
    final s = (ms / 1000).toStringAsFixed(1);
    return '${s}s';
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.totalMs != totalMs || old.pxPerMs != pxPerMs;
}

// ── Layer Label ────────────────────────────────────────────────────────────
class _LayerLabel extends StatelessWidget {
  final EditorLayer layer;
  final bool isSelected;
  final VoidCallback onTap, onVisibility, onLock, onKeyframe;
  const _LayerLabel({
    required this.layer, required this.isSelected,
    required this.onTap, required this.onVisibility,
    required this.onLock, required this.onKeyframe,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 52,
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.bgHover : Colors.transparent,
        border: Border(
          left: BorderSide(
            color: isSelected ? layer.color : Colors.transparent,
            width: 3,
          ),
          bottom: const BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(children: [
        // Color dot + icon
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: layer.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(layer.typeIcon, color: layer.color, size: 14),
        ),
        const SizedBox(width: 6),
        // Name
        Expanded(child: Text(layer.name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 11, fontWeight: FontWeight.w600))),
        // Buttons
        _LabelBtn(
          icon: layer.visible ? Icons.visibility : Icons.visibility_off,
          color: layer.visible ? AppTheme.textSecondary : AppTheme.textHint,
          onTap: onVisibility,
        ),
        _LabelBtn(
          icon: layer.locked ? Icons.lock : Icons.lock_open,
          color: layer.locked ? AppTheme.accent : AppTheme.textHint,
          onTap: onLock,
        ),
        _LabelBtn(
          icon: Icons.diamond_outlined,
          color: layer.keyframeMode ? AppTheme.accentGold : AppTheme.textHint,
          onTap: onKeyframe,
        ),
      ]),
    ),
  );
}

class _LabelBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _LabelBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Icon(icon, color: color, size: 14),
    ),
  );
}

// ── Layer Track ────────────────────────────────────────────────────────────
class _LayerTrack extends StatelessWidget {
  final EditorLayer layer;
  final double totalMs, pxPerMs, currentTimeMs;
  final bool isSelected;
  final Function(double) onTrimStart, onTrimEnd;
  final Function(Keyframe) onKeyframeTap;
  const _LayerTrack({
    required this.layer, required this.totalMs, required this.pxPerMs,
    required this.isSelected, required this.currentTimeMs,
    required this.onTrimStart, required this.onTrimEnd,
    required this.onKeyframeTap,
  });

  @override
  Widget build(BuildContext context) {
    final startX = layer.startMs * pxPerMs;
    final endX   = layer.endMs   * pxPerMs;
    final w      = (endX - startX).clamp(8.0, double.infinity);

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        // Track background
        Positioned(
          left: startX,
          top: 6, bottom: 6,
          width: w,
          child: GestureDetector(
            child: Container(
              decoration: BoxDecoration(
                color: layer.color.withOpacity(isSelected ? 0.3 : 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: layer.color.withOpacity(isSelected ? 0.8 : 0.4),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(children: [
                Icon(layer.typeIcon, color: layer.color, size: 12),
                const SizedBox(width: 4),
                Flexible(child: Text(layer.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: layer.color, fontSize: 9,
                      fontWeight: FontWeight.w600))),
              ]),
            ),
          ),
        ),

        // Keyframe diamonds
        ...layer.keyframes.map((kf) {
          final x = kf.timeMs * pxPerMs;
          return Positioned(
            left: x - 5,
            top: 0, bottom: 0,
            child: GestureDetector(
              onTap: () => onKeyframeTap(kf),
              child: Center(child: _KeyframeDiamond(
                color: layer.color,
                selected: false,
              )),
            ),
          );
        }),
      ]),
    );
  }
}

class _KeyframeDiamond extends StatelessWidget {
  final Color color;
  final bool selected;
  const _KeyframeDiamond({required this.color, required this.selected});

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: 0.785,
    child: Container(
      width: 10, height: 10,
      decoration: BoxDecoration(
        color: selected ? color : color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(2),
        boxShadow: selected ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)] : null,
      ),
    ),
  );
}

// ── Playhead ───────────────────────────────────────────────────────────────
class _Playhead extends StatelessWidget {
  final double currentTimeMs, pxPerMs, totalH;
  const _Playhead({required this.currentTimeMs, required this.pxPerMs, required this.totalH});

  @override
  Widget build(BuildContext context) {
    final x = currentTimeMs * pxPerMs;
    return Positioned(
      left: x,
      top: 0,
      bottom: 0,
      width: 2,
      child: IgnorePointer(
        child: Column(children: [
          // Head triangle
          Container(
            width: 12, height: 8,
            margin: const EdgeInsets.only(left: -5),
            child: CustomPaint(painter: _PlayheadHeadPainter()),
          ),
          // Line
          Expanded(child: Container(
            width: 1.5,
            color: AppTheme.accentRed,
          )),
        ]),
      ),
    );
  }
}

class _PlayheadHeadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.accentRed;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
