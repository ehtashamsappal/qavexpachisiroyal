import 'dart:math';

/// Cowrie-shell dice, digitised as 2d6.
///
/// Classic Pachisi is played with six cowrie shells; the number landing
/// mouth-up maps to a move value (see [PachisiRules.cowrieTable]). Qavex
/// Pachisi Royal uses two six-sided dice as the digital equivalent, keeping
/// the beloved doubles-bonus and entry-on-six traditions.
class CowrieDice {
  final Random _random;
  CowrieDice({Random? random}) : _random = random ?? Random();

  /// Rolls two dice, returning (d1, d2), each 1..6.
  (int, int) roll() => (_random.nextInt(6) + 1, _random.nextInt(6) + 1);

  static int sum((int, int) r) => r.$1 + r.$2;
  static bool isDoubles((int, int) r) => r.$1 == r.$2;
  static bool hasSix((int, int) r) => r.$1 == 6 || r.$2 == 6;
}
