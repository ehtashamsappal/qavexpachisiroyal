import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../game/pachisi_rules.dart';
import '../models/game_theme.dart';
import 'board_layout.dart';

/// Paints the full Pachisi cross-board: yards, ring, safe castles,
/// home stretches, center home, and all pieces.
class BoardPainter extends CustomPainter {
  final PachisiState state;
  final GameTheme theme;
  final List<int> activePlayers; // player ids in seat order
  final int currentPlayer;
  final Set<int> movablePieces; // piece indices of currentPlayer with legal moves
  final bool highContrast;
  final double pulse; // 0..1 highlight animation

  BoardPainter({
    required this.state,
    required this.theme,
    required this.activePlayers,
    required this.currentPlayer,
    required this.movablePieces,
    this.highContrast = false,
    this.pulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 15;
    final boardPaint = Paint()..color = theme.surface;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, boardPaint);
    canvas.save();
    canvas.clipRRect(rrect);

    _drawYards(canvas, cell);
    _drawTrackCells(canvas, cell);
    _drawHomeStretches(canvas, cell);
    _drawCenter(canvas, cell);
    _drawPieces(canvas, cell);

    canvas.restore();
  }

  void _drawYards(Canvas canvas, double cell) {
    for (final p in activePlayers) {
      final o = BoardLayout.yardOrigin(p);
      final rect = Rect.fromLTWH(o[1] * cell, o[0] * cell, 6 * cell, 6 * cell);
      final c = theme.playerColors[p];
      canvas.drawRect(rect, Paint()..color = c.withValues(alpha: 0.85));
      final inner = rect.deflate(cell * 0.7);
      canvas.drawRect(
        inner,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        inner,
        Paint()
          ..color = c
          ..style = PaintingStyle.stroke
          ..strokeWidth = highContrast ? 3 : 1.5,
      );
    }
  }

  void _drawTrackCells(Canvas canvas, double cell) {
    for (var i = 0; i < 52; i++) {
      final rc = BoardLayout.ringCells[i];
      final rect = Rect.fromLTWH(rc[1] * cell, rc[0] * cell, cell, cell);
      var fill = Colors.white;
      Color? tint;
      // Start squares tinted by owner.
      for (final p in activePlayers) {
        if (i == PachisiRules.startOffset(p)) tint = theme.playerColors[p];
      }
      final paint = Paint()..color = tint ?? fill;
      canvas.drawRect(rect, paint);
      canvas.drawRect(
        rect,
        Paint()
          ..color = highContrast ? Colors.black : Colors.black26
          ..style = PaintingStyle.stroke
          ..strokeWidth = highContrast ? 2 : 0.8,
      );
      if (tint != null) {
        _drawGlyph(canvas, rect, '➤', tint.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70, cell);
      } else if (PachisiRules.isSafe(i)) {
        _drawGlyph(canvas, rect, '★', const Color(0xFFB45309), cell);
      }
    }
  }

  void _drawHomeStretches(Canvas canvas, double cell) {
    for (final p in activePlayers) {
      final c = theme.playerColors[p];
      for (final rc in BoardLayout.homeStretch(p)) {
        final rect = Rect.fromLTWH(rc[1] * cell, rc[0] * cell, cell, cell);
        canvas.drawRect(rect, Paint()..color = c.withValues(alpha: 0.55));
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.black26
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
      }
    }
  }

  void _drawCenter(Canvas canvas, double cell) {
    // 3x3 center: four triangles meeting at the middle.
    final cx = 7.5 * cell;
    final cy = 7.5 * cell;
    // Draw as four triangles: top(P1), right(P2), bottom(P3), left(P0).
    final square = [
      Offset(6 * cell, 6 * cell),
      Offset(9 * cell, 6 * cell),
      Offset(9 * cell, 9 * cell),
      Offset(6 * cell, 9 * cell),
    ];
    final center = Offset(cx, cy);
    final order = [1, 2, 3, 0]; // top, right, bottom, left -> players
    for (var k = 0; k < 4; k++) {
      final p = order[k];
      if (!activePlayers.contains(p)) continue;
      final a = square[k];
      final b = square[(k + 1) % 4];
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..close();
      canvas.drawPath(path, Paint()..color = theme.playerColors[p].withValues(alpha: 0.9));
    }
    // Finished pieces as mini dots inside their triangle.
    for (final p in activePlayers) {
      final n = state.homeCount(p);
      if (n == 0) continue;
      final c = theme.playerColors[p];
      final base = _triangleCenter(p, cell);
      for (var i = 0; i < n; i++) {
        final off = Offset((i % 2 - 0.5) * cell * 0.7, (i ~/ 2 - 0.25) * cell * 0.7);
        canvas.drawCircle(
          base + off,
          cell * 0.22,
          Paint()
            ..color = c
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          base + off,
          cell * 0.22,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
    // Crown marker.
    _drawGlyph(canvas, Rect.fromCenter(center: center, width: cell, height: cell),
        '♛', Colors.white.withValues(alpha: 0.85), cell * 1.4);
  }

  Offset _triangleCenter(int player, double cell) {
    // top(P1), right(P2), bottom(P3), left(P0)
    switch (player) {
      case 1:
        return Offset(7.5 * cell, 6.8 * cell);
      case 2:
        return Offset(8.2 * cell, 7.5 * cell);
      case 3:
        return Offset(7.5 * cell, 8.2 * cell);
      default:
        return Offset(6.8 * cell, 7.5 * cell);
    }
  }

  void _drawPieces(Canvas canvas, double cell) {
    // Group pieces by cell key for stacking offsets.
    final Map<String, List<_PieceDot>> byCell = {};
    void add(int player, int piece, double fx, double fy) {
      final key = '${fx.toStringAsFixed(2)},${fy.toStringAsFixed(2)}';
      byCell.putIfAbsent(key, () => []).add(_PieceDot(player, piece, fx, fy));
    }

    for (final p in activePlayers) {
      for (var i = 0; i < 4; i++) {
        final step = state.steps[p][i];
        if (step == 57) continue; // drawn in center
        if (step == -1) {
          final spot = BoardLayout.baseSpots(p)[i];
          add(p, i, spot[1] + 0.5, spot[0] + 0.5);
        } else {
          final rc = BoardLayout.cellFor(p, step)!;
          add(p, i, rc[1] + 0.5, rc[0] + 0.5);
        }
      }
    }

    for (final entry in byCell.entries) {
      final dots = entry.value;
      for (var k = 0; k < dots.length; k++) {
        final d = dots[k];
        var dx = d.fx, dy = d.fy;
        if (dots.length > 1) {
          // 2x2 mini-grid inside the cell.
          dx += (k % 2 - 0.5) * 0.42;
          dy += (k ~/ 2 - 0.5) * 0.42;
        }
        final center = Offset(dx * cell, dy * cell);
        final radius = cell * (dots.length > 1 ? 0.26 : 0.36);
        final color = theme.playerColors[d.player];
        final isMovable = d.player == currentPlayer && movablePieces.contains(d.piece);

        if (isMovable) {
          canvas.drawCircle(
            center,
            radius + 3 + pulse * 3,
            Paint()
              ..color = theme.accent.withValues(alpha: 0.85)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
        if (d.player == currentPlayer) {
          canvas.drawCircle(
            center,
            radius + 1.5,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
        canvas.drawCircle(center, radius, Paint()..color = color);
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = highContrast ? Colors.black : Colors.black38
            ..style = PaintingStyle.stroke
            ..strokeWidth = highContrast ? 2.5 : 1.2,
        );
        // Inner highlight.
        canvas.drawCircle(
          center + Offset(-radius * 0.25, -radius * 0.25),
          radius * 0.28,
          Paint()..color = Colors.white.withValues(alpha: 0.45),
        );
      }
    }
  }

  void _drawGlyph(Canvas canvas, Rect rect, String glyph, Color color, double cell) {
    final tp = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(color: color, fontSize: cell * 0.55),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) =>
      old.state != state ||
      old.movablePieces != movablePieces ||
      old.pulse != pulse ||
      old.theme != theme ||
      old.highContrast != highContrast;
}

class _PieceDot {
  final int player;
  final int piece;
  final double fx, fy;
  _PieceDot(this.player, this.piece, this.fx, this.fy);
}

/// Maps a tap to the piece (player, pieceIndex) of [playerFilter] nearest
/// to the tap, or null. Used by the game screen for piece selection.
(int, int)? pieceAtTap({
  required Offset local,
  required Size size,
  required PachisiState state,
  required List<int> activePlayers,
  int? onlyPlayer,
}) {
  final cell = size.width / 15;
  int? bestPlayer;
  int? bestPiece;
  var bestDist = double.infinity;
  for (final p in activePlayers) {
    if (onlyPlayer != null && p != onlyPlayer) continue;
    for (var i = 0; i < 4; i++) {
      final step = state.steps[p][i];
      double fx, fy;
      if (step == 57) continue;
      if (step == -1) {
        final spot = BoardLayout.baseSpots(p)[i];
        fx = spot[1] + 0.5;
        fy = spot[0] + 0.5;
      } else {
        final rc = BoardLayout.cellFor(p, step)!;
        fx = rc[1] + 0.5;
        fy = rc[0] + 0.5;
      }
      final dx = local.dx - fx * cell;
      final dy = local.dy - fy * cell;
      final dist = dx * dx + dy * dy;
      if (dist < bestDist && dist < (cell * 0.9) * (cell * 0.9)) {
        bestDist = dist;
        bestPlayer = p;
        bestPiece = i;
      }
    }
  }
  if (bestPlayer == null) return null;
  return (bestPlayer, bestPiece!);
}
