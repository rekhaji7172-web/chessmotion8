import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/editor_provider.dart';
import '../models/layer_model.dart';
import '../theme/app_theme.dart';
import 'chess_board_editor.dart';

class LayerOptionsSheet extends StatelessWidget {
  final EditorLayer layer;
  const LayerOptionsSheet({super.key, required this.layer});

  static Future<void> show(BuildContext context, EditorLayer layer) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LayerOptionsSheet(layer: layer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, scroll) => Column(children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 10, bottom: 6),
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: AppTheme.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: layer.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(layer.typeIcon, color: layer.color, size: 16),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(layer.name, style: const TextStyle(
                  color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              Text(layer.typeLabel, style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11)),
            ]),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.textSecondary),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
        ),
        const Divider(color: AppTheme.divider, height: 1),
        Expanded(child: SingleChildScrollView(
          controller: scroll,
          child: _buildContent(context),
        )),
      ]),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (layer.type) {
      case LayerType.chessBoard:
        return ChessBoardEditor(layer: layer);
      case LayerType.chessPiece:
        return _PieceEditor(layer: layer);
      case LayerType.text:
        return _TextEditor(layer: layer);
      case LayerType.shape:
        return _ShapeEditor(layer: layer);
      default:
        return _GenericEditor(layer: layer);
    }
  }
}

// ── Piece Editor ───────────────────────────────────────────────────────────
class _PieceEditor extends StatelessWidget {
  final EditorLayer layer;
  const _PieceEditor({required this.layer});

  static const _pieces = [
    ('K', 'King'), ('Q', 'Queen'), ('R', 'Rook'),
    ('B', 'Bishop'), ('N', 'Knight'), ('P', 'Pawn'),
  ];

  @override
  Widget build(BuildContext context) {
    final editor = context.read<EditorProvider>();
    final currentPiece = layer.data['piece'] ?? 'K';
    final isWhite = (layer.data['pieceColor'] ?? 'white') == 'white';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(title: 'Piece Type'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: _pieces.map((p) {
            final selected = currentPiece.toUpperCase() == p.$1;
            return GestureDetector(
              onTap: () => editor.updateLayerData(layer.id, {
                'piece': isWhite ? p.$1 : p.$1.toLowerCase(),
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? layer.color.withOpacity(0.2) : AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected ? layer.color : AppTheme.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 32, height: 32,
                      child: CustomPaint(
                        painter: _SymbolPainter(
                          symbol: _getSymbol(p.$1, isWhite),
                          color: isWhite ? Colors.white : Colors.grey.shade300,
                        ),
                      ),
                    ),
                    Text(p.$2, style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 8)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Color'),
        const SizedBox(height: 8),
        Row(children: [
          _ColorToggle(
            label: 'White',
            selected: isWhite,
            color: Colors.white,
            onTap: () {
              final p = (layer.data['piece'] ?? 'K').toString().toUpperCase();
              editor.updateLayerData(layer.id, {'pieceColor': 'white', 'piece': p});
            },
          ),
          const SizedBox(width: 10),
          _ColorToggle(
            label: 'Black',
            selected: !isWhite,
            color: Colors.grey.shade700,
            onTap: () {
              final p = (layer.data['piece'] ?? 'K').toString().toLowerCase();
              editor.updateLayerData(layer.id, {'pieceColor': 'black', 'piece': p});
            },
          ),
        ]),
      ]),
    );
  }

  String _getSymbol(String piece, bool white) {
    const map = {
      'K': ['♔','♚'], 'Q': ['♕','♛'], 'R': ['♖','♜'],
      'B': ['♗','♝'], 'N': ['♘','♞'], 'P': ['♙','♟'],
    };
    return map[piece]?[white ? 0 : 1] ?? '♙';
  }
}

class _SymbolPainter extends CustomPainter {
  final String symbol;
  final Color color;
  const _SymbolPainter({required this.symbol, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: symbol, style: TextStyle(fontSize: 24, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class _ColorToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _ColorToggle({required this.label, required this.selected,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary.withOpacity(0.2) : AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
      ),
      child: Row(children: [
        Container(width: 14, height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border))),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecondary,
          fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    ),
  );
}

// ── Text Editor ────────────────────────────────────────────────────────────
class _TextEditor extends StatefulWidget {
  final EditorLayer layer;
  const _TextEditor({required this.layer});
  @override
  State<_TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<_TextEditor> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.layer.data['text'] ?? 'Your Text');
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final editor = context.read<EditorProvider>();
    final layer  = widget.layer;
    final fontSize = ((layer.data['fontSize'] ?? 48) as num).toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(title: 'Text Content'),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter text...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onChanged: (v) => editor.updateLayerData(layer.id, {'text': v}),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Font Size'),
        Slider(
          value: fontSize.clamp(8, 200),
          min: 8, max: 200,
          onChanged: (v) => editor.updateLayerData(layer.id, {'fontSize': v.round()}),
        ),
        Center(child: Text('${fontSize.round()}px',
            style: const TextStyle(color: AppTheme.accent, fontSize: 13))),
        const SizedBox(height: 12),
        _SectionHeader(title: 'Font Weight'),
        const SizedBox(height: 8),
        Row(children: [
          _WeightChip(label: 'Normal', value: 'normal',
              selected: layer.data['fontWeight'] == 'normal',
              onTap: () => editor.updateLayerData(layer.id, {'fontWeight': 'normal'})),
          const SizedBox(width: 8),
          _WeightChip(label: 'Bold', value: 'bold',
              selected: (layer.data['fontWeight'] ?? 'bold') == 'bold',
              onTap: () => editor.updateLayerData(layer.id, {'fontWeight': 'bold'})),
          const SizedBox(width: 8),
          _WeightChip(label: 'Italic', value: 'italic',
              selected: layer.data['fontWeight'] == 'italic',
              onTap: () => editor.updateLayerData(layer.id, {'fontWeight': 'italic'})),
        ]),
      ]),
    );
  }
}

class _WeightChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;
  const _WeightChip({required this.label, required this.value,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary.withOpacity(0.2) : AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
      ),
      child: Text(label, style: TextStyle(
        color: selected ? Colors.white : AppTheme.textSecondary,
        fontSize: 12, fontWeight: FontWeight.w600)),
    ),
  );
}

// ── Shape Editor ───────────────────────────────────────────────────────────
class _ShapeEditor extends StatelessWidget {
  final EditorLayer layer;
  const _ShapeEditor({required this.layer});

  static const _shapes = [
    ('rectangle', 'Rectangle', Icons.crop_square),
    ('circle', 'Circle', Icons.radio_button_unchecked),
    ('triangle', 'Triangle', Icons.change_history),
    ('line', 'Line', Icons.remove),
    ('arrow', 'Arrow', Icons.arrow_forward),
    ('star', 'Star', Icons.star_border),
  ];

  @override
  Widget build(BuildContext context) {
    final editor = context.read<EditorProvider>();
    final current = layer.data['shapeType'] ?? 'rectangle';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _SectionHeader(title: 'Shape Type'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.8,
          children: _shapes.map((s) {
            final selected = current == s.$1;
            return GestureDetector(
              onTap: () => editor.updateLayerData(layer.id, {'shapeType': s.$1}),
              child: Container(
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary.withOpacity(0.2) : AppTheme.bgSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.border),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(s.$3,
                      color: selected ? AppTheme.primary : AppTheme.textSecondary,
                      size: 16),
                  const SizedBox(width: 6),
                  Text(s.$2, style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Stroke Width'),
        Slider(
          value: ((layer.data['strokeWidth'] ?? 2) as num).toDouble().clamp(0, 20),
          min: 0, max: 20,
          onChanged: (v) => editor.updateLayerData(layer.id, {'strokeWidth': v.round()}),
        ),
      ]),
    );
  }
}

// ── Generic Editor ─────────────────────────────────────────────────────────
class _GenericEditor extends StatelessWidget {
  final EditorLayer layer;
  const _GenericEditor({required this.layer});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(layer.typeIcon, color: layer.color, size: 48),
      const SizedBox(height: 16),
      Text('${layer.typeLabel} Editor',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      const Text('Use Transform & Effects tabs to animate this layer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
    ])),
  );
}

// ── Shared ─────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title.toUpperCase(),
    style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
  );
}
