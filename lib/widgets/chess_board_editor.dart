import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';
import '../models/layer_model.dart';
import '../theme/app_theme.dart';
import '../utils/chess_painter.dart';

class ChessBoardEditor extends StatefulWidget {
  final EditorLayer layer;
  const ChessBoardEditor({super.key, required this.layer});
  @override
  State<ChessBoardEditor> createState() => _ChessBoardEditorState();
}

class _ChessBoardEditorState extends State<ChessBoardEditor> {
  late Map<String, String> _position;
  String? _selectedPiece;
  String _dragPiece = '';
  bool _showSetupPanel = false;

  static const List<String> _pieceOptions = [
    'K','Q','R','B','N','P','k','q','r','b','n','p'
  ];

  @override
  void initState() {
    super.initState();
    _position = Map<String, String>.from(startingPosition);
  }

  String _squareName(int col, int row) {
    return '${String.fromCharCode('a'.codeUnitAt(0) + col)}${8 - row}';
  }

  @override
  Widget build(BuildContext context) {
    final editor = context.read<EditorProvider>();
    return Column(children: [
      // Board
      AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(builder: (_, c) {
          final sq = c.maxWidth / 8;
          final lightC = _parseColor(widget.layer.data['lightColor'] ?? '#F0D9B5');
          final darkC  = _parseColor(widget.layer.data['darkColor']  ?? '#B58863');
          return Stack(children: [
            CustomPaint(
              size: Size(c.maxWidth, c.maxWidth),
              painter: ChessBoardPainter(
                lightColor: lightC,
                darkColor: darkC,
                showCoordinates: widget.layer.data['showCoordinates'] ?? true,
              ),
            ),
            // Pieces
            for (final e in _position.entries) ...[
              _buildPiece(e.key, e.value, sq),
            ],
            // Drop targets
            if (_dragPiece.isNotEmpty)
              for (int r = 0; r < 8; r++)
                for (int c2 = 0; c2 < 8; c2++)
                  Positioned(
                    left: c2 * sq, top: r * sq,
                    width: sq, height: sq,
                    child: DragTarget<String>(
                      onAcceptWithDetails: (d) {
                        final from = d.data;
                        final to   = _squareName(c2, r);
                        setState(() {
                          final piece = _position.remove(from);
                          if (piece != null) _position[to] = piece;
                          _dragPiece = '';
                        });
                        editor.updateLayerData(widget.layer.id, {'position': _position});
                      },
                      builder: (_, c, r2) => Container(
                        decoration: BoxDecoration(
                          color: c.isNotEmpty
                              ? AppTheme.accent.withOpacity(0.3)
                              : Colors.transparent,
                          border: c.isNotEmpty
                              ? Border.all(color: AppTheme.accent, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
          ]);
        }),
      ),

      // Controls
      Container(
        padding: const EdgeInsets.all(10),
        color: AppTheme.bgCard,
        child: Column(children: [
          Row(children: [
            _ControlBtn(label: 'Starting Position', icon: Icons.refresh,
                onTap: () {
                  setState(() => _position = Map.from(startingPosition));
                  editor.updateLayerData(widget.layer.id, {'position': _position});
                }),
            const SizedBox(width: 8),
            _ControlBtn(label: 'Clear Board', icon: Icons.clear_all,
                onTap: () {
                  setState(() => _position.clear());
                  editor.updateLayerData(widget.layer.id, {'position': _position});
                }),
            const SizedBox(width: 8),
            _ControlBtn(
              label: 'Setup',
              icon: Icons.settings,
              onTap: () => setState(() => _showSetupPanel = !_showSetupPanel),
            ),
          ]),
          if (_showSetupPanel) ...[
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Add Piece:', style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
            ),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: _pieceOptions.map((p) {
              final isWhite = p == p.toUpperCase();
              return GestureDetector(
                onTap: () => setState(() => _selectedPiece = p),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: _selectedPiece == p
                        ? AppTheme.accent.withOpacity(0.2)
                        : AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _selectedPiece == p ? AppTheme.accent : AppTheme.border),
                  ),
                  child: CustomPaint(
                    painter: ChessPiecePainter(piece: p, isWhite: isWhite),
                  ),
                ),
              );
            }).toList()),
            if (_selectedPiece != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Tap a square to place the piece',
                    style: const TextStyle(color: AppTheme.accent, fontSize: 11)),
              ),
          ],
        ]),
      ),
    ]);
  }

  Widget _buildPiece(String square, String piece, double sq) {
    final file = square[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = 8 - int.parse(square[1]);
    final isWhite = piece == piece.toUpperCase();
    return Positioned(
      left: file * sq, top: rank * sq,
      width: sq, height: sq,
      child: Draggable<String>(
        data: square,
        onDragStarted: () => setState(() => _dragPiece = piece),
        onDraggableCanceled: (_, __) => setState(() => _dragPiece = ''),
        feedback: SizedBox(
          width: sq * 1.3, height: sq * 1.3,
          child: CustomPaint(
              painter: ChessPiecePainter(piece: piece, isWhite: isWhite, opacity: 0.8)),
        ),
        childWhenDragging: const SizedBox(),
        child: GestureDetector(
          onTap: () {
            if (_selectedPiece != null) {
              setState(() {
                _position[square] = _selectedPiece!;
                _selectedPiece = null;
              });
            }
          },
          child: CustomPaint(
            painter: ChessPiecePainter(piece: piece, isWhite: isWhite),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      try { return Color(int.parse('FF$clean', radix: 16)); } catch (_) {}
    }
    return Colors.white;
  }
}

class _ControlBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ControlBtn({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppTheme.textSecondary, size: 13),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}
