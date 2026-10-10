/// 15x15 Pachisi cross-board geometry.
///
/// The shared ring of 52 squares winds around the four arms; each player
/// also owns a 6-cell home stretch and a 4-spot base yard.
class BoardLayout {
  /// Ring square index -> (row, col) on the 15x15 grid.
  static const List<List<int>> ringCells = [
    [6, 1], [6, 2], [6, 3], [6, 4], [6, 5], // 0-4
    [5, 6], [4, 6], [3, 6], [2, 6], [1, 6], [0, 6], // 5-10
    [0, 7], [0, 8], // 11-12
    [1, 8], [2, 8], [3, 8], [4, 8], [5, 8], // 13-17
    [6, 9], [6, 10], [6, 11], [6, 12], [6, 13], [6, 14], // 18-23
    [7, 14], [8, 14], // 24-25
    [8, 13], [8, 12], [8, 11], [8, 10], [8, 9], // 26-30
    [9, 8], [10, 8], [11, 8], [12, 8], [13, 8], [14, 8], // 31-36
    [14, 7], [14, 6], // 37-38
    [13, 6], [12, 6], [11, 6], [10, 6], [9, 6], // 39-43
    [8, 5], [8, 4], [8, 3], [8, 2], [8, 1], [8, 0], // 44-49
    [7, 0], [6, 0], // 50-51
  ];

  /// Player -> 6 home-stretch cells (steps 51..56), innermost last.
  static List<List<int>> homeStretch(int player) {
    switch (player) {
      case 0:
        return const [[7, 1], [7, 2], [7, 3], [7, 4], [7, 5], [7, 6]];
      case 1:
        return const [[1, 7], [2, 7], [3, 7], [4, 7], [5, 7], [6, 7]];
      case 2:
        return const [[7, 13], [7, 12], [7, 11], [7, 10], [7, 9], [7, 8]];
      default:
        return const [[13, 7], [12, 7], [11, 7], [10, 7], [9, 7], [8, 7]];
    }
  }

  /// Player -> 4 base-yard spots for pieces waiting to enter.
  static List<List<int>> baseSpots(int player) {
    switch (player) {
      case 0:
        return const [[2, 2], [2, 3], [3, 2], [3, 3]];
      case 1:
        return const [[2, 11], [2, 12], [3, 11], [3, 12]];
      case 2:
        return const [[11, 11], [11, 12], [12, 11], [12, 12]];
      default:
        return const [[11, 2], [11, 3], [12, 2], [12, 3]];
    }
  }

  /// Yard rectangle (top-left row/col, size 6) per player.
  static List<int> yardOrigin(int player) {
    switch (player) {
      case 0:
        return const [0, 0];
      case 1:
        return const [0, 9];
      case 2:
        return const [9, 9];
      default:
        return const [9, 0];
    }
  }

  /// Cell (row, col) for a piece at journey [step] of [player].
  /// Returns null for finished (home) pieces — those go to the center.
  static List<int>? cellFor(int player, int step) {
    if (step == -1) return null; // base: use baseSpots
    if (step == 57) return null; // home: center
    if (step >= 51) return homeStretch(player)[step - 51];
    final ring = (player * 13 + step) % 52;
    return ringCells[ring];
  }
}
