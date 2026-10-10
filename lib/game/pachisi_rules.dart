/// Official classic Pachisi rules, digitised with a 2d6 cowrie-shell mapping.
///
/// Board model: a shared ring of 52 squares plus a private 6-square home
/// stretch per player. A piece's journey is measured in `steps`:
///   -1        -> in the starting yard (base)
///   0..50     -> on the shared ring (ring square = (startOffset + steps) % 52)
///   51..56    -> private home stretch (safe, cannot be captured)
///   57        -> home (finished, needs an exact roll)
library;

/// Tunable rule set so Kids Mode can soften the game without forking logic.
class RulesConfig {
  /// Whether landing on a lone opponent piece captures it.
  final bool capturesEnabled;

  /// Whether 2+ stacked same-player pieces form an impassable blockade.
  final bool blockadesEnabled;

  /// Roll needed on at least one die to leave the base.
  final int entryRoll;

  /// Consecutive doubles that forfeit the turn.
  final int doublesForfeit;

  const RulesConfig({
    this.capturesEnabled = true,
    this.blockadesEnabled = true,
    this.entryRoll = 6,
    this.doublesForfeit = 3,
  });

  static const classic = RulesConfig();

  /// Kids Mode: no captures, no harsh blockades, friendlier entry.
  static const kids = RulesConfig(
    capturesEnabled: false,
    blockadesEnabled: false,
    entryRoll: 6,
    doublesForfeit: 99,
  );
}

class PachisiRules {
  static const int playerCount = 4;
  static const int piecesPerPlayer = 4;

  /// Squares on the shared ring.
  static const int ringSize = 52;

  /// Steps value of a piece sitting in its base.
  static const int base = -1;

  /// Steps value of a finished piece.
  static const int home = 57;

  /// First step of the private home stretch.
  static const int homeStretchStart = 51;

  /// Last ring step before the home stretch.
  static const int lastRingStep = 50;

  /// Ring index where each player enters the board.
  static int startOffset(int player) => (player * 13) % ringSize;

  /// The 8 traditional safe squares ("castles"): each player's entry plus
  /// the marked square 8 steps ahead of it. Pieces here cannot be captured
  /// and any number of players may share them.
  static const Set<int> safeSquares = {0, 8, 13, 21, 26, 34, 39, 47};

  static bool isSafe(int ringSquare) => safeSquares.contains(ringSquare);

  /// Classic cowrie-shell values for the How-to-Play screen. Digital play
  /// maps these onto 2d6; the table documents the heritage.
  static const Map<String, int> cowrieTable = {
    '2 shells up': 2,
    '3 shells up': 3,
    '4 shells up': 4,
    '5 shells up': 10,
    '6 shells up': 6,
    '7 shells up': 12,
    'all shells down': 25,
  };
}
