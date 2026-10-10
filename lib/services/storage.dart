import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/ai.dart';
import '../models/meta.dart';

/// Central app state: profile, Royal Coins, stats, achievements, streak,
/// settings, themes, shop ownership. Persisted with SharedPreferences.
/// Everything is offline; no account, no ads, no tracking.
class AppState extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool ready = false;

  // Profile
  String playerName = 'Royal Player';
  String avatar = '👑';

  // Soft currency (play-earned only)
  int coins = 100;

  // Stats
  int gamesPlayed = 0;
  int gamesWon = 0;
  int totalCaptures = 0;
  int totalRolls = 0;
  int totalBlockades = 0;
  int bestStreak = 0;
  int aiWins1 = 0, aiWins2 = 0, aiWins3 = 0;

  // Daily streak
  int streak = 0;
  String lastPlayDate = '';
  bool dailyRewardClaimed = false;

  // Achievements: id -> progress
  final Map<String, int> achievementProgress = {};
  final Set<String> achievementsUnlocked = {};

  // Settings
  bool soundOn = true;
  bool musicOn = true;
  bool hapticsOn = true;
  bool kidsMode = false;
  bool largeText = false;
  bool highContrast = false;
  bool reduceMotion = false;

  // Themes & shop
  String themeId = 'maharaja';
  final Set<String> unlockedThemes = {'maharaja'};
  String diceSkin = 'dice_ivory';
  String frame = 'frame_bronze';
  final Set<String> ownedItems = {'dice_ivory', 'frame_bronze'};

  // Tournament
  int ladderRung = 1; // next rung to play (1..5), 6 = complete
  final Set<GameMode> modesPlayed = {};

  // Support
  bool coffeeBought = false;

  // Pending achievement popups (consumed by UI)
  final List<String> _pendingPopups = [];
  List<String> takePopups() {
    final out = List<String>.from(_pendingPopups);
    _pendingPopups.clear();
    return out;
  }

  static Future<AppState> load() async {
    final s = AppState();
    s._prefs = await SharedPreferences.getInstance();
    final p = s._prefs;
    s.playerName = p.getString('playerName') ?? 'Royal Player';
    s.avatar = p.getString('avatar') ?? '👑';
    s.coins = p.getInt('coins') ?? 100;
    s.gamesPlayed = p.getInt('gamesPlayed') ?? 0;
    s.gamesWon = p.getInt('gamesWon') ?? 0;
    s.totalCaptures = p.getInt('totalCaptures') ?? 0;
    s.totalRolls = p.getInt('totalRolls') ?? 0;
    s.totalBlockades = p.getInt('totalBlockades') ?? 0;
    s.bestStreak = p.getInt('bestStreak') ?? 0;
    s.streak = p.getInt('streak') ?? 0;
    s.lastPlayDate = p.getString('lastPlayDate') ?? '';
    s.dailyRewardClaimed = p.getBool('dailyRewardClaimed') ?? false;
    s.soundOn = p.getBool('soundOn') ?? true;
    s.musicOn = p.getBool('musicOn') ?? true;
    s.hapticsOn = p.getBool('hapticsOn') ?? true;
    s.kidsMode = p.getBool('kidsMode') ?? false;
    s.largeText = p.getBool('largeText') ?? false;
    s.highContrast = p.getBool('highContrast') ?? false;
    s.reduceMotion = p.getBool('reduceMotion') ?? false;
    s.themeId = p.getString('themeId') ?? 'maharaja';
    s.unlockedThemes.addAll(p.getStringList('unlockedThemes') ?? const []);
    s.diceSkin = p.getString('diceSkin') ?? 'dice_ivory';
    s.frame = p.getString('frame') ?? 'frame_bronze';
    s.ownedItems.addAll(p.getStringList('ownedItems') ?? const []);
    s.ladderRung = p.getInt('ladderRung') ?? 1;
    s.coffeeBought = p.getBool('coffeeBought') ?? false;
    s.aiWins1 = p.getInt('aiWins1') ?? 0;
    s.aiWins2 = p.getInt('aiWins2') ?? 0;
    s.aiWins3 = p.getInt('aiWins3') ?? 0;
    for (final a in achievements) {
      final prog = p.getInt('ach_${a.id}') ?? 0;
      if (prog > 0) s.achievementProgress[a.id] = prog;
      if (p.getBool('achdone_${a.id}') ?? false) {
        s.achievementsUnlocked.add(a.id);
      }
    }
    for (final m in GameMode.values) {
      if (p.getBool('mode_${m.name}') ?? false) s.modesPlayed.add(m);
    }
    s._rollDaily();
    s.ready = true;
    return s;
  }

  Future<void> _save() async {
    final p = _prefs;
    await p.setString('playerName', playerName);
    await p.setString('avatar', avatar);
    await p.setInt('coins', coins);
    await p.setInt('gamesPlayed', gamesPlayed);
    await p.setInt('gamesWon', gamesWon);
    await p.setInt('totalCaptures', totalCaptures);
    await p.setInt('totalRolls', totalRolls);
    await p.setInt('totalBlockades', totalBlockades);
    await p.setInt('bestStreak', bestStreak);
    await p.setInt('streak', streak);
    await p.setString('lastPlayDate', lastPlayDate);
    await p.setBool('dailyRewardClaimed', dailyRewardClaimed);
    await p.setBool('soundOn', soundOn);
    await p.setBool('musicOn', musicOn);
    await p.setBool('hapticsOn', hapticsOn);
    await p.setBool('kidsMode', kidsMode);
    await p.setBool('largeText', largeText);
    await p.setBool('highContrast', highContrast);
    await p.setBool('reduceMotion', reduceMotion);
    await p.setString('themeId', themeId);
    await p.setStringList('unlockedThemes', unlockedThemes.toList());
    await p.setString('diceSkin', diceSkin);
    await p.setString('frame', frame);
    await p.setStringList('ownedItems', ownedItems.toList());
    await p.setInt('ladderRung', ladderRung);
    await p.setBool('coffeeBought', coffeeBought);
    await p.setInt('aiWins1', aiWins1);
    await p.setInt('aiWins2', aiWins2);
    await p.setInt('aiWins3', aiWins3);
    for (final e in achievementProgress.entries) {
      await p.setInt('ach_${e.key}', e.value);
    }
    for (final id in achievementsUnlocked) {
      await p.setBool('achdone_$id', true);
    }
    for (final m in GameMode.values) {
      await p.setBool('mode_${m.name}', modesPlayed.contains(m));
    }
  }

  // -- Daily streak ----------------------------------------------------------

  String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  void _rollDaily() {
    final today = _today();
    if (lastPlayDate == today) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yKey = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    if (lastPlayDate == yKey) {
      streak += 1;
    } else if (lastPlayDate.isNotEmpty) {
      streak = 1;
    } else {
      streak = 1;
    }
    if (streak > bestStreak) bestStreak = streak;
    lastPlayDate = today;
    dailyRewardClaimed = false;
    progress('streak_3', streak);
    progress('streak_7', streak);
    progress('streak_30', streak);
  }

  /// Claims the daily login reward (25 + 5*streak coins, capped at 100).
  int claimDailyReward() {
    if (dailyRewardClaimed) return 0;
    dailyRewardClaimed = true;
    final reward = (25 + streak * 5).clamp(25, 100);
    addCoins(reward);
    _save();
    notifyListeners();
    return reward;
  }

  // -- Coins -----------------------------------------------------------------

  void addCoins(int n) {
    coins += n;
    if (coins >= 500) progress('coins_500', coins);
    if (coins >= 5000) progress('coins_5000', coins);
    _save();
    notifyListeners();
  }

  bool spendCoins(int n) {
    if (coins < n) return false;
    coins -= n;
    _save();
    notifyListeners();
    return true;
  }

  // -- Achievements ----------------------------------------------------------

  Achievement? byId(String id) =>
      achievements.where((a) => a.id == id).firstOrNull;

  void progress(String id, int value) {
    final a = byId(id);
    if (a == null || achievementsUnlocked.contains(id)) return;
    final cur = achievementProgress[id] ?? 0;
    final next = value > cur ? value : cur;
    if (id == 'wins_5' || id == 'wins_25' || id == 'wins_100' ||
        id == 'captures_10' || id == 'captures_100' ||
        id == 'blockades_25' || id == 'rolls_1000' ||
        id == 'games_10' || id == 'games_50' || id == 'games_200' ||
        id == 'streak_3' || id == 'streak_7' || id == 'streak_30' ||
        id == 'coins_500' || id == 'coins_5000') {
      achievementProgress[id] = next;
      if (next >= a.target) _unlock(a);
    } else {
      _unlock(a);
    }
    _save();
    notifyListeners();
  }

  void _unlock(Achievement a) {
    if (achievementsUnlocked.contains(a.id)) return;
    achievementsUnlocked.add(a.id);
    achievementProgress[a.id] = a.target;
    if (a.coinReward > 0) coins += a.coinReward;
    _pendingPopups.add(a.id);
  }

  // -- Match reporting --------------------------------------------------------

  void reportMatch({
    required GameMode mode,
    required bool won,
    required int captures,
    required int rolls,
    required int blockades,
    required int piecesHome,
    required int aiOpponents,
    required AiDifficulty? hardestAi,
    required int turnCount,
    required bool lostAnyPiece,
    required bool capturedAnyone,
    required bool usedNonDefaultTheme,
  }) {
    gamesPlayed++;
    totalCaptures += captures;
    totalRolls += rolls;
    totalBlockades += blockades;
    modesPlayed.add(mode);
    progress('games_10', gamesPlayed);
    progress('games_50', gamesPlayed);
    progress('games_200', gamesPlayed);
    progress('captures_10', totalCaptures);
    progress('captures_100', totalCaptures);
    progress('blockades_25', totalBlockades);
    progress('rolls_1000', totalRolls);
    if (modesPlayed.length >= GameMode.values.length) progress('try_all_modes', 1);
    if (turnCount >= 150) progress('marathon', 1);
    if (mode == GameMode.timedBlitz && won) {
      progress('blitz_win', 1);
      if (piecesHome >= 3) progress('blitz_dominance', 1);
    }
    if (won) {
      gamesWon++;
      addCoins(50 + piecesHome * 10);
      progress('first_win', 1);
      progress('wins_5', gamesWon);
      progress('wins_25', gamesWon);
      progress('wins_100', gamesWon);
      if (!capturedAnyone) progress('win_no_capture', 1);
      if (!lostAnyPiece) progress('no_captured', 1);
      if (usedNonDefaultTheme) progress('themed_win', 1);
      if (hardestAi == AiDifficulty.expert) progress('win_vs_expert', 1);
      if (hardestAi == AiDifficulty.hard) progress('beat_hard', 1);
      if (aiOpponents == 1) aiWins1++;
      if (aiOpponents == 2) aiWins2++;
      if (aiOpponents == 3) aiWins3++;
      if (aiWins1 > 0 && aiWins2 > 0 && aiWins3 > 0) {
        progress('win_all_ai_counts', 1);
      }
      if (mode == GameMode.quickMatch && turnCount < 40) progress('quick_win', 1);
    } else {
      addCoins(10 + piecesHome * 5);
    }
    final hour = DateTime.now().hour;
    if (hour < 7) progress('early_bird', 1);
    if (hour >= 0 && hour < 5) progress('night_owl', 1);
    _save();
    notifyListeners();
  }

  void reportTournamentWin(int rung) {
    if (rung >= ladderRung) {
      ladderRung = rung + 1;
      if (ladderRung > tournamentLadder.length) progress('ladder_complete', 1);
      addCoins(100 * rung);
      _save();
      notifyListeners();
    }
  }

  // -- Shop / themes -----------------------------------------------------------

  bool buyItem(ShopItem item) {
    if (ownedItems.contains(item.id)) return true;
    if (!spendCoins(item.price)) return false;
    ownedItems.add(item.id);
    if (item.kind == 'dice') diceSkin = item.id;
    if (item.kind == 'frame') frame = item.id;
    progress('shop_first', 1);
    if (shopItems.where((i) => i.kind == 'dice').every((i) => ownedItems.contains(i.id))) {
      progress('shop_all_dice', 1);
    }
    _save();
    notifyListeners();
    return true;
  }

  bool unlockTheme(String id, int price) {
    if (unlockedThemes.contains(id)) {
      themeId = id;
      _save();
      notifyListeners();
      return true;
    }
    if (!spendCoins(price)) return false;
    unlockedThemes.add(id);
    themeId = id;
    if (unlockedThemes.length >= 4) progress('themes_4', 1);
    if (unlockedThemes.length >= gameThemesCount) progress('themes_all', 1);
    _save();
    notifyListeners();
    return true;
  }

  static int get gameThemesCount => 8;

  void setTheme(String id) {
    if (!unlockedThemes.contains(id)) return;
    themeId = id;
    _save();
    notifyListeners();
  }

  void equipItem(ShopItem item) {
    if (!ownedItems.contains(item.id)) return;
    if (item.kind == 'dice') diceSkin = item.id;
    if (item.kind == 'frame') frame = item.id;
    _save();
    notifyListeners();
  }

  // -- Settings -----------------------------------------------------------------

  void toggleSound() { soundOn = !soundOn; _save(); notifyListeners(); }
  void toggleMusic() { musicOn = !musicOn; _save(); notifyListeners(); }
  void toggleHaptics() { hapticsOn = !hapticsOn; _save(); notifyListeners(); }
  void toggleKidsMode() { kidsMode = !kidsMode; _save(); notifyListeners(); }
  void toggleLargeText() { largeText = !largeText; _save(); notifyListeners(); }
  void toggleHighContrast() { highContrast = !highContrast; _save(); notifyListeners(); }
  void toggleReduceMotion() { reduceMotion = !reduceMotion; _save(); notifyListeners(); }

  void setProfile(String name, String av) {
    playerName = name.trim().isEmpty ? 'Royal Player' : name.trim();
    avatar = av;
    progress('profile_set', 1);
    _save();
    notifyListeners();
  }

  void onCoffeeBought() {
    coffeeBought = true;
    addCoins(500);
    progress('coffee', 1);
    _save();
    notifyListeners();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
