/// A single legal piece movement.
class PachisiMove {
  final int player;
  final int piece;
  final int from; // steps value before the move (-1 = base)
  final int to; // steps value after the move
  final bool isEnter; // leaving the base
  final bool isCapture;
  final List<CapturedPiece> captured;
  final bool reachesHome;

  const PachisiMove({
    required this.player,
    required this.piece,
    required this.from,
    required this.to,
    this.isEnter = false,
    this.isCapture = false,
    this.captured = const [],
    this.reachesHome = false,
  });

  @override
  String toString() =>
      'Move(p$player piece$piece $from->$to${isEnter ? ' enter' : ''}${isCapture ? ' capture' : ''}${reachesHome ? ' home' : ''})';
}

class CapturedPiece {
  final int player;
  final int piece;
  const CapturedPiece(this.player, this.piece);
}
