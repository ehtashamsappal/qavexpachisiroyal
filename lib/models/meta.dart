import '../game/ai.dart';

/// The six play modes of Qavex Pachisi Royal.
enum GameMode {
  classicRoyal,
  quickMatch,
  vsAi,
  passAndPlay,
  timedBlitz,
  tournament,
}

extension GameModeX on GameMode {
  String get title => switch (this) {
        GameMode.classicRoyal => 'Classic Royal',
        GameMode.quickMatch => 'Quick Match',
        GameMode.vsAi => 'Vs AI',
        GameMode.passAndPlay => 'Pass & Play',
        GameMode.timedBlitz => 'Timed Blitz',
        GameMode.tournament => 'Tournament Ladder',
      };

  String get description => switch (this) {
        GameMode.classicRoyal =>
          'The full royal court: 4 players, official classic rules, first to bring all four pieces home wins.',
        GameMode.quickMatch =>
          'A swift duel — you versus one Medium AI, perfect for a tea break.',
        GameMode.vsAi =>
          'Face 1–3 AI courtiers at the difficulty of your choosing.',
        GameMode.passAndPlay =>
          '2–4 humans on one device. Pass the phone, keep the crown.',
        GameMode.timedBlitz =>
          'Five minutes on the clock. Most progress when the gong sounds wins.',
        GameMode.tournament =>
          'Climb a 5-rung ladder: Easy → Expert. Win a rung to ascend.',
      };

  String get icon => switch (this) {
        GameMode.classicRoyal => '👑',
        GameMode.quickMatch => '⚡',
        GameMode.vsAi => '🤖',
        GameMode.passAndPlay => '👥',
        GameMode.timedBlitz => '⏱️',
        GameMode.tournament => '🏆',
      };

  /// Default player setup for the mode.
  int get defaultHumans => switch (this) {
        GameMode.passAndPlay => 2,
        _ => 1,
      };
}

/// A tournament rung.
class LadderRung {
  final int rung;
  final AiDifficulty difficulty;
  final int aiCount;
  const LadderRung(this.rung, this.difficulty, this.aiCount);
}

const List<LadderRung> tournamentLadder = [
  LadderRung(1, AiDifficulty.easy, 1),
  LadderRung(2, AiDifficulty.medium, 2),
  LadderRung(3, AiDifficulty.medium, 3),
  LadderRung(4, AiDifficulty.hard, 3),
  LadderRung(5, AiDifficulty.expert, 3),
];

/// Achievement definition. Progress is tracked generically in AppState.
class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int coinReward;
  final int target; // progress needed (1 for one-shot)

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.coinReward,
    this.target = 1,
  });
}

/// 52 achievements across play, mastery, collection and loyalty.
const List<Achievement> achievements = [
  // First steps
  Achievement(id: 'first_roll', title: 'First Cast', description: 'Roll the cowrie dice for the first time.', icon: '🎲', coinReward: 10),
  Achievement(id: 'first_entry', title: 'Enter the Court', description: 'Bring your first piece onto the board.', icon: '🚪', coinReward: 10),
  Achievement(id: 'first_capture', title: 'First Blood', description: 'Capture an opponent piece.', icon: '⚔️', coinReward: 15),
  Achievement(id: 'first_home', title: 'Safe Haven', description: 'Bring a piece home.', icon: '🏠', coinReward: 15),
  Achievement(id: 'first_win', title: 'Crowned', description: 'Win your first match.', icon: '👑', coinReward: 50),
  Achievement(id: 'first_blockade', title: 'Wall of the Court', description: 'Form your first blockade.', icon: '🧱', coinReward: 20),
  // Wins
  Achievement(id: 'wins_5', title: 'Rising Noble', description: 'Win 5 matches.', icon: '🥉', coinReward: 40, target: 5),
  Achievement(id: 'wins_25', title: 'Seasoned Raja', description: 'Win 25 matches.', icon: '🥈', coinReward: 100, target: 25),
  Achievement(id: 'wins_100', title: 'Eternal Maharaja', description: 'Win 100 matches.', icon: '🥇', coinReward: 300, target: 100),
  Achievement(id: 'win_no_capture', title: 'Gentle Ruler', description: 'Win without capturing anyone.', icon: '🕊️', coinReward: 60),
  Achievement(id: 'win_comeback', title: 'Great Comeback', description: 'Win after losing 2+ pieces to captures in one match.', icon: '🔥', coinReward: 60),
  Achievement(id: 'win_vs_expert', title: 'Giant Slayer', description: 'Beat an Expert AI.', icon: '🗡️', coinReward: 80),
  Achievement(id: 'win_all_ai_counts', title: 'Court Conqueror', description: 'Win against 1, 2 and 3 AI opponents.', icon: '🏰', coinReward: 80),
  // Captures & tactics
  Achievement(id: 'captures_10', title: 'Raider', description: 'Capture 10 pieces total.', icon: '🎯', coinReward: 30, target: 10),
  Achievement(id: 'captures_100', title: 'Terror of the Court', description: 'Capture 100 pieces total.', icon: '💀', coinReward: 150, target: 100),
  Achievement(id: 'capture_3_match', title: 'Triple Strike', description: 'Capture 3 pieces in one match.', icon: '⚡', coinReward: 40),
  Achievement(id: 'blockades_25', title: 'Master Builder', description: 'Form 25 blockades total.', icon: '🏗️', coinReward: 60, target: 25),
  Achievement(id: 'safe_haven', title: 'Untouchable', description: 'Keep a piece on a safe square for 10 consecutive turns.', icon: '🛡️', coinReward: 40),
  Achievement(id: 'perfect_home', title: 'Perfect Procession', description: 'Bring all 4 pieces home with exact rolls only (no overshoot attempts).', icon: '✨', coinReward: 70),
  // Dice luck
  Achievement(id: 'double_six', title: 'Double Sixes', description: 'Roll double sixes.', icon: '🎰', coinReward: 15),
  Achievement(id: 'six_streak', title: 'Blessed by Fortune', description: 'Roll a six three times in a row.', icon: '🍀', coinReward: 30),
  Achievement(id: 'rolls_1000', title: 'Veteran Caster', description: 'Roll the dice 1,000 times.', icon: '🎲', coinReward: 80, target: 1000),
  // Modes
  Achievement(id: 'try_all_modes', title: 'Grand Tour', description: 'Play all 6 game modes.', icon: '🗺️', coinReward: 80),
  Achievement(id: 'blitz_win', title: 'Against the Clock', description: 'Win a Timed Blitz match.', icon: '⏱️', coinReward: 50),
  Achievement(id: 'blitz_dominance', title: 'Blitz Royalty', description: 'Win Timed Blitz with 3+ pieces home.', icon: '👑', coinReward: 70),
  Achievement(id: 'ladder_complete', title: 'Ladder Legend', description: 'Complete all 5 tournament rungs.', icon: '🏆', coinReward: 200),
  Achievement(id: 'pass_play_4', title: 'Full House', description: 'Finish a 4-player Pass & Play match.', icon: '👥', coinReward: 40),
  Achievement(id: 'quick_win', title: 'Swift Victory', description: 'Win a Quick Match in under 40 turns.', icon: '💨', coinReward: 40),
  // Loyalty & streaks
  Achievement(id: 'streak_3', title: 'Devoted', description: 'Play 3 days in a row.', icon: '📿', coinReward: 30, target: 3),
  Achievement(id: 'streak_7', title: 'Week of the Raja', description: 'Play 7 days in a row.', icon: '🗓️', coinReward: 80, target: 7),
  Achievement(id: 'streak_30', title: 'Moon Cycle', description: 'Play 30 days in a row.', icon: '🌙', coinReward: 250, target: 30),
  Achievement(id: 'games_10', title: 'Court Regular', description: 'Finish 10 matches.', icon: '🎪', coinReward: 30, target: 10),
  Achievement(id: 'games_50', title: 'Court Pillar', description: 'Finish 50 matches.', icon: '🏛️', coinReward: 100, target: 50),
  Achievement(id: 'games_200', title: 'Living Legend', description: 'Finish 200 matches.', icon: '🌟', coinReward: 300, target: 200),
  // Coins & collection
  Achievement(id: 'coins_500', title: 'Treasury Clerk', description: 'Hold 500 Royal Coins at once.', icon: '💰', coinReward: 0, target: 500),
  Achievement(id: 'coins_5000', title: 'Royal Treasurer', description: 'Hold 5,000 Royal Coins at once.', icon: '💎', coinReward: 0, target: 5000),
  Achievement(id: 'shop_first', title: 'Patron of Arts', description: 'Buy your first shop item.', icon: '🛍️', coinReward: 20),
  Achievement(id: 'shop_all_dice', title: 'Dice Collector', description: 'Own all dice skins.', icon: '🎲', coinReward: 60),
  Achievement(id: 'themes_4', title: 'Art Connoisseur', description: 'Unlock 4 themes.', icon: '🎨', coinReward: 40),
  Achievement(id: 'themes_all', title: 'Master of Aesthetics', description: 'Unlock all 8 themes.', icon: '🌈', coinReward: 100),
  Achievement(id: 'coffee', title: 'Generous Soul', description: 'Buy the developer a coffee.', icon: '☕', coinReward: 100),
  // Skill & style
  Achievement(id: 'extra_turn_chain', title: 'Relentless', description: 'Take 4 extra turns in a row.', icon: '🔗', coinReward: 40),
  Achievement(id: 'home_rush', title: 'Homeward Bound', description: 'Bring 2 pieces home in one turn chain.', icon: '🏃', coinReward: 40),
  Achievement(id: 'no_captured', title: 'Unscathed', description: 'Win a match without losing any piece to capture.', icon: '🛡️', coinReward: 60),
  Achievement(id: 'beat_hard', title: 'Court Strategist', description: 'Beat a Hard AI.', icon: '🧠', coinReward: 50),
  Achievement(id: 'kids_play', title: 'Family Time', description: 'Finish a match in Kids Mode.', icon: '🧒', coinReward: 30),
  Achievement(id: 'night_owl', title: 'Night Owl', description: 'Play a match after midnight.', icon: '🦉', coinReward: 20),
  Achievement(id: 'early_bird', title: 'Early Bird', description: 'Play a match before 7 AM.', icon: '🐦', coinReward: 20),
  Achievement(id: 'themed_win', title: 'Fashionable Victory', description: 'Win while using a non-default theme.', icon: '💅', coinReward: 30),
  Achievement(id: 'profile_set', title: 'Introducing Yourself', description: 'Set your royal name and avatar.', icon: '📝', coinReward: 15),
  Achievement(id: 'doubles_forfeit', title: 'Too Greedy', description: 'Forfeit a turn on three consecutive doubles.', icon: '🤦', coinReward: 10),
  Achievement(id: 'marathon', title: 'Marathon Durbar', description: 'Play a single match lasting 150+ turns.', icon: '🏃‍♂️', coinReward: 50),
  Achievement(id: 'comeback_king', title: 'Phoenix of Pachisi', description: 'Win after all 4 of your pieces were captured at least once.', icon: '🐦‍🔥', coinReward: 100),
];

/// Cosmetic shop items bought with Royal Coins (soft currency only).
class ShopItem {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int price;
  final String kind; // 'dice' or 'frame'
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.price,
    required this.kind,
  });
}

const List<ShopItem> shopItems = [
  ShopItem(id: 'dice_ivory', name: 'Ivory Dice', description: 'Classic carved-ivory look.', icon: '⚪', price: 0, kind: 'dice'),
  ShopItem(id: 'dice_gold', name: 'Golden Dice', description: 'For rolls worthy of a raja.', icon: '🟡', price: 200, kind: 'dice'),
  ShopItem(id: 'dice_jade', name: 'Jade Dice', description: 'Cool Mughal jade.', icon: '🟢', price: 350, kind: 'dice'),
  ShopItem(id: 'dice_ruby', name: 'Ruby Dice', description: 'Deep royal red.', icon: '🔴', price: 500, kind: 'dice'),
  ShopItem(id: 'dice_onyx', name: 'Onyx Dice', description: 'Midnight black with gold pips.', icon: '⚫', price: 800, kind: 'dice'),
  ShopItem(id: 'frame_bronze', name: 'Bronze Frame', description: 'A modest court frame.', icon: '🖼️', price: 150, kind: 'frame'),
  ShopItem(id: 'frame_silver', name: 'Silver Frame', description: 'Moonlit elegance.', icon: '🌙', price: 400, kind: 'frame'),
  ShopItem(id: 'frame_gold', name: 'Gold Frame', description: 'Fit for the Maharaja.', icon: '👑', price: 1000, kind: 'frame'),
];

/// Themes unlockable with Royal Coins (Maharaja Court is free).
const Map<String, int> themePrices = {
  'maharaja': 0,
  'midnight': 150,
  'ocean': 150,
  'neon': 300,
  'desert': 300,
  'forest': 300,
  'mono': 450,
  'sunset': 450,
};
