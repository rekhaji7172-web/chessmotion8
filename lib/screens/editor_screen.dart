import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';
import '../providers/project_provider.dart';
import '../models/layer_model.dart';
import '../models/keyframe_model.dart';
import '../theme/app_theme.dart';
import '../utils/chess_painter.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/properties_panel.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});
  @override State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  Timer? _playTimer;
  bool _sidebarOpen = true;

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  void _handlePlayback(EditorProvider editor) {
    if (editor.isPlaying) {
      _playTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
        if (!mounted) { _playTimer?.cancel(); return; }
        final e = context.read<EditorProvider>();
        if (e.isPlaying) {
          e.advanceTime(33);
        } else {
          _playTimer?.cancel();
        }
      });
    } else {
      _playTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, editor, _) {
        // Start/stop playback timer
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (editor.isPlaying && (_playTimer == null || !_playTimer!.isActive)) {
            _handlePlayback(editor);
          } else if (!editor.isPlaying) {
            _playTimer?.cancel();
          }
        });

        return Scaffold(
          backgroundColor: AppTheme.bgDark,
          body: Column(children: [
            // ── Top Bar ──────────────────────────────────────
            _EditorTopBar(
              sidebarOpen: _sidebarOpen,
              onToggleSidebar: () => setState(() => _sidebarOpen = !_sidebarOpen),
              onSave: () {
                if (editor.project != null) {
                  context.read<ProjectProvider>().saveProject(editor.project!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project saved!'),
                        backgroundColor: AppTheme.primary,
                        duration: Duration(seconds: 1)),
                  );
                }
              },
              onExport: () => _showExportDialog(context),
              onBack: () => Navigator.pop(context),
            ),

            // ── Main Editor Area ─────────────────────────────
            Expanded(child: Row(children: [

              // Left panel: Layers + Add
              if (_sidebarOpen) _LayersPanel(editor: editor),

              // Center: Preview canvas
              Expanded(child: Column(children: [
                // Canvas Preview
                Expanded(child: _PreviewCanvas(editor: editor)),
                // Playback controls
                _PlaybackControls(editor: editor),
              ])),

              // Right panel: Properties
              if (_sidebarOpen)
                SizedBox(
                  width: 240,
                  child: const PropertiesPanel(),
                ),
            ])),

            // ── Timeline ─────────────────────────────────────
            SizedBox(
              height: 220,
              child: const TimelineWidget(),
            ),
          ]),
        );
      },
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => _ExportDialog());
  }
}

// ── Editor Top Bar ─────────────────────────────────────────────────────────
class _EditorTopBar extends StatelessWidget {
  final bool sidebarOpen;
  final VoidCallback onToggleSidebar, onSave, onExport, onBack;
  const _EditorTopBar({
    required this.sidebarOpen,
    required this.onToggleSidebar,
    required this.onSave,
    required this.onExport,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final editor = context.watch<EditorProvider>();
    return Container(
      height: 52 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 12, right: 12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(children: [
        // Back
        _TopBtn(icon: Icons.arrow_back_ios_new, onTap: onBack),
        const SizedBox(width: 8),
        // Project title
        Expanded(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(editor.project?.title ?? 'Untitled',
                style: const TextStyle(color: Colors.white,
                    fontSize: 14, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
            Text(editor.project?.settings.aspectRatioLabel ?? '',
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
        )),
        // Toolbar buttons
        _TopBtn(icon: sidebarOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined,
            onTap: onToggleSidebar, active: sidebarOpen),
        _TopBtn(icon: Icons.undo, onTap: () {}),
        _TopBtn(icon: Icons.redo, onTap: () {}),
        const SizedBox(width: 4),
        // Save
        _TopTextBtn(label: 'Save', icon: Icons.save_outlined,
            color: AppTheme.primary, onTap: onSave),
        const SizedBox(width: 6),
        // Export
        _TopTextBtn(label: 'Export', icon: Icons.ios_share,
            color: AppTheme.accent, onTap: onExport),
      ]),
    );
  }
}

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _TopBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon,
        color: active ? AppTheme.accent : AppTheme.textSecondary, size: 20),
    padding: const EdgeInsets.all(6),
    constraints: const BoxConstraints(),
  );
}

class _TopTextBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TopTextBtn({required this.label, required this.icon,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color,
            fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

// ── Layers Panel ───────────────────────────────────────────────────────────
class _LayersPanel extends StatelessWidget {
  final EditorProvider editor;
  const _LayersPanel({required this.editor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: Column(children: [
        const SizedBox(height: 8),
        // Add layer button
        _LayerAddBtn(onAdd: (type) => editor.addLayer(type)),
        const Divider(color: AppTheme.divider, height: 16),
        // Quick actions
        _PanelBtn(icon: Icons.grid_4x4, tip: 'Chess Board',
            onTap: () => editor.addLayer(LayerType.chessBoard)),
        _PanelBtn(icon: Icons.extension, tip: 'Chess Piece',
            onTap: () => editor.addLayer(LayerType.chessPiece)),
        _PanelBtn(icon: Icons.title, tip: 'Text',
            onTap: () => editor.addLayer(LayerType.text)),
        _PanelBtn(icon: Icons.image_outlined, tip: 'Image',
            onTap: () => editor.addLayer(LayerType.image)),
        _PanelBtn(icon: Icons.crop_square, tip: 'Shape',
            onTap: () => editor.addLayer(LayerType.shape)),
        _PanelBtn(icon: Icons.auto_fix_high, tip: 'Effect',
            onTap: () => editor.addLayer(LayerType.effect)),
        const Spacer(),
        // Tools
        const Divider(color: AppTheme.divider, height: 16),
        _PanelBtn(icon: Icons.zoom_in, tip: 'Zoom In', onTap: () {}),
        _PanelBtn(icon: Icons.zoom_out, tip: 'Zoom Out', onTap: () {}),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _LayerAddBtn extends StatelessWidget {
  final Function(LayerType) onAdd;
  const _LayerAddBtn({required this.onAdd});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Add Layer',
    child: InkWell(
      onTap: () => _showMenu(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    ),
  );

  void _showMenu(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final pos = box.localToGlobal(Offset.zero);
    showMenu(
      context: context,
      color: AppTheme.bgSurface,
      position: RelativeRect.fromLTRB(pos.dx + 50, pos.dy, 0, 0),
      items: LayerType.values.map((t) {
        final dummy = EditorLayer(
          id: '', name: '', type: t, startMs: 0, endMs: 0, color: Colors.white, index: 0);
        return PopupMenuItem<LayerType>(
          value: t,
          child: Row(children: [
            Icon(dummy.typeIcon, color: AppTheme.textSecondary, size: 18),
            const SizedBox(width: 10),
            Text(dummy.typeLabel,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ]),
        );
      }).toList(),
    ).then((t) { if (t != null) onAdd(t); });
  }
}

class _PanelBtn extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback onTap;
  const _PanelBtn({required this.icon, required this.tip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
    ),
  );
}

// ── Preview Canvas ─────────────────────────────────────────────────────────
class _PreviewCanvas extends StatelessWidget {
  final EditorProvider editor;
  const _PreviewCanvas({required this.editor});

  @override
  Widget build(BuildContext context) {
    final project  = editor.project;
    final ratio    = project?.settings.aspectRatioValue ?? 16 / 9;
    final layers   = editor.layers.where((l) => l.visible).toList();

    return Container(
      color: const Color(0xFF040810),
      child: Center(
        child: AspectRatio(
          aspectRatio: ratio,
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: const Color(0xFF080D18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Stack(children: [
              // Layers rendered bottom to top
              ...layers.map((layer) => _LayerRenderer(
                layer: layer,
                editor: editor,
              )),
              // Frame overlay
              Positioned.fill(child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.border.withOpacity(0.5), width: 1),
                  ),
                ),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

class _LayerRenderer extends StatelessWidget {
  final EditorLayer layer;
  final EditorProvider editor;
  const _LayerRenderer({required this.layer, required this.editor});

  @override
  Widget build(BuildContext context) {
    final t = layer.transform;
    final opacity = editor.getInterpolatedValue(layer, KeyframeProperty.opacity,
        editor.currentTimeMs) / 100;
    final scale = editor.getInterpolatedValue(layer, KeyframeProperty.scale,
        editor.currentTimeMs) / 100;
    final rotation = editor.getInterpolatedValue(layer, KeyframeProperty.rotation,
        editor.currentTimeMs);
    final posX = editor.getInterpolatedValue(layer, KeyframeProperty.positionX,
        editor.currentTimeMs);
    final posY = editor.getInterpolatedValue(layer, KeyframeProperty.positionY,
        editor.currentTimeMs);

    Widget child = _buildLayerContent(layer);

    return Positioned.fill(
      child: Transform.translate(
        offset: Offset(posX + t.x, posY + t.y),
        child: Transform.rotate(
          angle: (rotation + t.rotation) * 3.14159 / 180,
          child: Transform.scale(
            scale: scale * t.scaleX,
            child: Opacity(
              opacity: (opacity * t.opacity).clamp(0, 1),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerContent(EditorLayer layer) {
    switch (layer.type) {
      case LayerType.chessBoard:
        return ChessCanvasWidget(
          lightColor: layer.data['lightColor'] ?? '#F0D9B5',
          darkColor: layer.data['darkColor'] ?? '#B58863',
          showCoordinates: layer.data['showCoordinates'] ?? true,
          position: startingPosition,
        );
      case LayerType.chessPiece:
        final piece = layer.data['piece'] ?? 'K';
        final isWhite = (layer.data['pieceColor'] ?? 'white') == 'white';
        return Center(child: CustomPaint(
          size: const Size(80, 80),
          painter: ChessPiecePainter(piece: piece, isWhite: isWhite),
        ));
      case LayerType.text:
        return Center(child: Text(
          layer.data['text'] ?? 'Text',
          style: TextStyle(
            color: Colors.white,
            fontSize: ((layer.data['fontSize'] ?? 48) as num).toDouble(),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ));
      case LayerType.shape:
        return Container(
          color: _parseColor(layer.data['fillColor'] ?? '#1565C0'),
        );
      case LayerType.effect:
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [layer.color.withOpacity(0.3), Colors.transparent],
            ),
          ),
        );
      default:
        return Container(
          color: layer.color.withOpacity(0.1),
          child: Center(child: Icon(layer.typeIcon,
              color: layer.color.withOpacity(0.5), size: 48)),
        );
    }
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      try { return Color(int.parse('FF$clean', radix: 16)); } catch (_) {}
    }
    return Colors.white;
  }
}

// ── Playback Controls ──────────────────────────────────────────────────────
class _PlaybackControls extends StatelessWidget {
  final EditorProvider editor;
  const _PlaybackControls({required this.editor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: [
        // Time display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(editor.currentTimeLabel,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              )),
        ),
        const SizedBox(width: 12),

        // Scrubber
        Expanded(child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            activeTrackColor: AppTheme.accent,
            thumbColor: AppTheme.accent,
            inactiveTrackColor: AppTheme.bgSurface,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
          ),
          child: Slider(
            value: editor.currentTimeMs.clamp(0, editor.totalDurationMs),
            min: 0,
            max: editor.totalDurationMs,
            onChanged: (v) => editor.seekTo(v),
          ),
        )),

        const SizedBox(width: 12),
        Text(editor.totalTimeLabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(width: 16),

        // Playback buttons
        _PlayBtn(icon: Icons.skip_previous, onTap: editor.stop, size: 18),
        _PlayBtn(icon: Icons.chevron_left, onTap: editor.stepBackward, size: 20),
        // Play/Pause
        GestureDetector(
          onTap: editor.togglePlay,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: editor.isPlaying ? AppTheme.accentRed : AppTheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (editor.isPlaying ? AppTheme.accentRed : AppTheme.primary)
                      .withOpacity(0.4),
                  blurRadius: 12,
                )
              ],
            ),
            child: Icon(
              editor.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white, size: 26,
            ),
          ),
        ),
        _PlayBtn(icon: Icons.chevron_right, onTap: editor.stepForward, size: 20),
        _PlayBtn(icon: Icons.skip_next, onTap: () => editor.seekTo(editor.totalDurationMs), size: 18),

        const SizedBox(width: 8),
        // FPS
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('${editor.project?.settings.fps.toInt() ?? 30} FPS',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _PlayBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _PlayBtn({required this.icon, required this.onTap, required this.size});

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, color: AppTheme.textSecondary, size: size),
    padding: const EdgeInsets.all(6),
    constraints: const BoxConstraints(),
  );
}

// ── Export Dialog ──────────────────────────────────────────────────────────
class _ExportDialog extends StatefulWidget {
  @override State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  String _quality = '1080p';
  String _format  = 'MP4';
  double _fps = 30;
  bool _exporting = false;
  double _progress = 0;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppTheme.bgCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Icon(Icons.ios_share, color: AppTheme.accent, size: 22),
          const SizedBox(width: 10),
          const Text('Export Video', style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary),
              onPressed: () => Navigator.pop(context)),
        ]),
        const SizedBox(height: 20),
        _ExportOption(
          label: 'Quality',
          value: _quality,
          options: ['480p', '720p', '1080p', '4K'],
          onChanged: (v) => setState(() => _quality = v),
        ),
        const SizedBox(height: 10),
        _ExportOption(
          label: 'Format',
          value: _format,
          options: ['MP4', 'MOV', 'GIF', 'WebM'],
          onChanged: (v) => setState(() => _format = v),
        ),
        const SizedBox(height: 10),
        Row(children: [
          const Text('FPS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const Spacer(),
          ...['24', '30', '60'].map((f) => _FpsChip(
            label: f,
            selected: _fps == double.parse(f),
            onTap: () => setState(() => _fps = double.parse(f)),
          )),
        ]),
        const SizedBox(height: 20),
        if (_exporting) ...[
          LinearProgressIndicator(value: _progress,
              color: AppTheme.accent, backgroundColor: AppTheme.bgSurface),
          const SizedBox(height: 8),
          Text('Exporting... ${(_progress * 100).toInt()}%',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startExport,
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Start Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ]),
    ),
  );

  Future<void> _startExport() async {
    setState(() { _exporting = true; _progress = 0; });
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() => _progress = i / 100);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported as $_quality $_format @ ${_fps.toInt()}fps'),
            backgroundColor: AppTheme.primary),
      );
    }
  }
}

class _ExportOption extends StatelessWidget {
  final String label, value;
  final List<String> options;
  final Function(String) onChanged;
  const _ExportOption({required this.label, required this.value,
    required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    const Spacer(),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: AppTheme.bgSurface,
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    ),
  ]);
}

class _FpsChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FpsChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
      ),
      child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecondary,
          fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}
