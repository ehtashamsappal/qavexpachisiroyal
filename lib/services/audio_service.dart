import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// All game audio: 2 background tracks + 12 sound effects, generated offline
/// with numpy and shipped as WAV assets in assets/audio/.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _sfx = AudioPlayer();

  bool soundOn = true;
  bool musicOn = true;
  String _currentTrack = '';

  Future<void> init({required bool soundOn, required bool musicOn}) async {
    this.soundOn = soundOn;
    this.musicOn = musicOn;
    await _music.setReleaseMode(ReleaseMode.loop);
  }

  void syncSettings({required bool soundOn, required bool musicOn}) {
    this.soundOn = soundOn;
    this.musicOn = musicOn;
    if (!musicOn) {
      _music.stop();
      _currentTrack = '';
    }
  }

  Future<void> playMusic(String asset) async {
    if (!musicOn || _currentTrack == asset) return;
    _currentTrack = asset;
    try {
      await _music.play(AssetSource(asset));
    } catch (e) {
      debugPrint('music error: $e');
    }
  }

  Future<void> stopMusic() async {
    _currentTrack = '';
    await _music.stop();
  }

  Future<void> sfx(String asset) async {
    if (!soundOn) return;
    try {
      await _sfx.play(AssetSource(asset));
    } catch (e) {
      debugPrint('sfx error: $e');
    }
  }

  // Named helpers ------------------------------------------------------------
  Future<void> click() => sfx('audio/sfx_click.wav');
  Future<void> diceRoll() => sfx('audio/sfx_dice_roll.wav');
  Future<void> pieceMove() => sfx('audio/sfx_piece_move.wav');
  Future<void> capture() => sfx('audio/sfx_capture.wav');
  Future<void> enterBoard() => sfx('audio/sfx_enter_board.wav');
  Future<void> homeReach() => sfx('audio/sfx_home_reach.wav');
  Future<void> win() => sfx('audio/sfx_win.wav');
  Future<void> lose() => sfx('audio/sfx_lose.wav');
  Future<void> coin() => sfx('audio/sfx_coin.wav');
  Future<void> turnNotify() => sfx('audio/sfx_turn_notify.wav');
  Future<void> error() => sfx('audio/sfx_error.wav');
  Future<void> achievement() => sfx('audio/sfx_achievement.wav');

  Future<void> menuMusic() => playMusic('audio/bgm_royal_court.wav');
  Future<void> gameMusic() => playMusic('audio/bgm_monsoon_night.wav');
}
