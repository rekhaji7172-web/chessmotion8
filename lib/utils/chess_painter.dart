import 'package:flutter/material.dart';

class ChessBoardPainter extends CustomPainter {
  final Color lightColor;
  final Color darkColor;
  final bool showCoordinates;
  final int boardStyle;
  final int highlightedSquare;

  const ChessBoardPainter({
    this.lightColor = const Color(0xFFF0D9B5),
    this.darkColor  = const Color(0xFFB58863),
    this.showCoordinates = true,
    this.boardStyle = 0,
    this.highlightedSquare = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sq = size.width / 8;
    final lightP = Paint()..color = lightColor;
    final darkP  = Paint()..color = darkColor;
    final hlP    = Paint()..color = const Color(0xAAFFE082);

    // Draw squares
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final isLight = (r + c) % 2 == 0;
        final rect = Rect.fromLTWH(c * sq, r * sq, sq, sq);
        canvas.drawRect(rect, isLight ? lightP : darkP);
        if (highlightedSquare == r * 8 + c) {
          canvas.drawRect(rect, hlP);
        }
      }
    }

    // Border glow
    final borderP = Paint()
      ..color = const Color(0xFF1565C0).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderP);

    // Coordinates
    if (showCoordinates) {
      final files = ['a','b','c','d','e','f','g','h'];
      final ranks = ['8','7','6','5','4','3','2','1'];
      const ts = TextStyle(fontSize: 9, fontWeight: FontWeight.w700);

      for (int i = 0; i < 8; i++) {
        final isLightFile = i % 2 == 0;
        _drawText(canvas, files[i],
            Offset(i * sq + sq - 9, size.height - 11),
            ts.copyWith(color: isLightFile ? darkColor : lightColor));
        _drawText(canvas, ranks[i],
            Offset(2, i * sq + 2),
            ts.copyWith(color: i % 2 == 0 ? darkColor : lightColor));
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(ChessBoardPainter old) =>
      old.lightColor != lightColor ||
      old.darkColor != darkColor ||
      old.showCoordinates != showCoordinates ||
      old.highlightedSquare != highlightedSquare;
}

// ── Chess Piece Painter ────────────────────────────────────────────────────
class ChessPiecePainter extends CustomPainter {
  final String piece;
  final bool isWhite;
  final double opacity;

  const ChessPiecePainter({
    required this.piece,
    required this.isWhite,
    this.opacity = 1.0,
  });

  static const Map<String, String> _symbols = {
    'K': '♔', 'Q': '♕', 'R': '♖', 'B': '♗', 'N': '♘', 'P': '♙',
    'k': '♚', 'q': '♛', 'r': '♜', 'b': '♝', 'n': '♞', 'p': '♟',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final symbol = _symbols[piece] ?? '♙';
    final color = isWhite ? Colors.white : Colors.black;

    // Shadow
    final shadowP = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: size.width * 0.75,
          color: Colors.black.withOpacity(0.4 * opacity),
          shadows: const [],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadowP.paint(canvas, Offset(size.width * 0.125 + 3, size.height * 0.05 + 3));

    // Piece
    final tp = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          fontSize: size.width * 0.75,
          color: color.withOpacity(opacity),
          shadows: [
            Shadow(
              color: (isWhite ? Colors.black : Colors.white).withOpacity(0.3 * opacity),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width * 0.125, size.height * 0.05));
  }

  @override
  bool shouldRepaint(ChessPiecePainter old) =>
      old.piece != piece || old.isWhite != isWhite || old.opacity != opacity;
}

// ── Animated Chess Canvas Widget ───────────────────────────────────────────
class ChessCanvasWidget extends StatefulWidget {
  final String lightColor;
  final String darkColor;
  final bool showCoordinates;
  final Map<String, String> position;

  const ChessCanvasWidget({
    super.key,
    this.lightColor = '#F0D9B5',
    this.darkColor  = '#B58863',
    this.showCoordinates = true,
    this.position = const {},
  });

  @override
  State<ChessCanvasWidget> createState() => _ChessCanvasWidgetState();
}

class _ChessCanvasWidgetState extends State<ChessCanvasWidget> {
  int _hoveredSquare = -1;

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTapDown: (d) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(d.globalPosition);
          final sq = box.size.width / 8;
          final c = (local.dx / sq).floor().clamp(0, 7);
          final r = (local.dy / sq).floor().clamp(0, 7);
          setState(() => _hoveredSquare = r * 8 + c);
        },
        child: CustomPaint(
          painter: ChessBoardPainter(
            lightColor: _parseColor(widget.lightColor),
            darkColor: _parseColor(widget.darkColor),
            showCoordinates: widget.showCoordinates,
            highlightedSquare: _hoveredSquare,
          ),
          child: LayoutBuilder(builder: (_, c) {
            final sq = c.maxWidth / 8;
            return Stack(children: [
              ...widget.position.entries.map((e) {
                final file = e.key[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
                final rank = 8 - int.parse(e.key[1]);
                final piece = e.value;
                final isWhite = piece == piece.toUpperCase();
                return Positioned(
                  left: file * sq,
                  top: rank * sq,
                  width: sq,
                  height: sq,
                  child: CustomPaint(
                    painter: ChessPiecePainter(piece: piece, isWhite: isWhite),
                  ),
                );
              }),
            ]);
          }),
        ),
      ),
    );
  }
}

// ── Starting position ──────────────────────────────────────────────────────
const Map<String, String> startingPosition = {
  'a1': 'R', 'b1': 'N', 'c1': 'B', 'd1': 'Q', 'e1': 'K', 'f1': 'B', 'g1': 'N', 'h1': 'R',
  'a2': 'P', 'b2': 'P', 'c2': 'P', 'd2': 'P', 'e2': 'P', 'f2': 'P', 'g2': 'P', 'h2': 'P',
  'a7': 'p', 'b7': 'p', 'c7': 'p', 'd7': 'p', 'e7': 'p', 'f7': 'p', 'g7': 'p', 'h7': 'p',
  'a8': 'r', 'b8': 'n', 'c8': 'b', 'd8': 'q', 'e8': 'k', 'f8': 'b', 'g8': 'n', 'h8': 'r',
};
