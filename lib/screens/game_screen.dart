import 'package:flutter/material.dart';

import '../engine/game_controller.dart';
import '../models/game_theme.dart';
import '../models/meta.dart';
import '../services/audio_service.dart';
import '../services/storage.dart';
import '../widgets/board_painter.dart';
import '../widgets/dice_widget.dart';
import '../widgets/royal_widgets.dart';

/// 5. Game — the royal cross-board, cowrie dice, and turn flow.
class GameScreen extends StatefulWidget {
  final AppState app;
  final MatchConfig config;
  const GameScreen({super.key, required this.app, required this.config});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameController _ctrl;
  late AnimationController _pulse;
  bool _winShown = false;

  @override
  void initState() {
    super.initState();
    _ctrl = GameController(app: widget.app, config: widget.config);
    _ctrl.addListener(_onUpdate);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    AudioService().gameMusic();
  }

  void _onUpdate() {
    if (!mounted) return;
    setState(() {});
    if (_ctrl.gameOver && !_winShown) {
      _winShown = true;
      Future.delayed(const Duration(milliseconds: 600), _showResult);
    } else {
      showAchievementPopups(context, widget.app);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onUpdate);
    _ctrl.dispose();
    _pulse.dispose();
    AudioService().menuMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeOf(widget.app, gameThemes);
    final movable = _ctrl.hasRolled && _ctrl.isHumanTurn
        ? _ctrl.moves.map((m) => m.piece).toSet()
        : <int>{};
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.mode.title),
        actions: [
          if (widget.config.mode == GameMode.timedBlitz)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  '⏱️ ${_fmt(_ctrl.blitzSecondsLeft)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          IconButton(
            icon: const Text('🏳️', style: TextStyle(fontSize: 20)),
            tooltip: 'Resign',
            onPressed: _ctrl.gameOver ? null : _confirmResign,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.app,
        builder: (context, _) => Column(
          children: [
            _turnBanner(theme),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boardSize =
                            Size(constraints.maxWidth, constraints.maxWidth);
                        return GestureDetector(
                          onTapDown: (d) => _onBoardTap(d.localPosition, boardSize),
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) => CustomPaint(
                              painter: BoardPainter(
                                state: _ctrl.state,
                                theme: theme,
                                activePlayers: widget.config.seats,
                                currentPlayer: _ctrl.currentPlayer,
                                movablePieces: movable,
                                highContrast: widget.app.highContrast,
                                pulse: _pulse.value,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            _statusBar(),
            _diceRow(theme),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(1, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _turnBanner(GameTheme theme) {
    final players = widget.config.seats;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: players.map((p) {
          final isCurrent = p == _ctrl.currentPlayer && !_ctrl.gameOver;
          final isAi = widget.config.isAi(p);
          final home = _ctrl.state.homeCount(p);
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent
                    ? theme.playerColors[p].withValues(alpha: 0.35)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrent
                      ? theme.playerColors[p]
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.playerColors[p],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          isAi
                              ? 'AI'
                              : (p == players.first
                                  ? widget.app.playerName.split(' ').first
                                  : 'P${players.indexOf(p) + 1}'),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text('🏠 $home/4',
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        _ctrl.statusMessage,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _diceRow(GameTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _ctrl.turnLabel,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        DiceWidget(
          d1: _ctrl.d1,
          d2: _ctrl.d2,
          rolling: _ctrl.rolling,
          canRoll: _ctrl.isHumanTurn && !_ctrl.hasRolled && !_ctrl.gameOver,
          onRoll: _ctrl.rollDice,
          diceColor: Colors.white,
          pipColor: theme.primary,
        ),
      ],
    );
  }

  void _onBoardTap(Offset local, Size boardSize) {
    if (!_ctrl.isHumanTurn || !_ctrl.hasRolled || _ctrl.gameOver) return;
    final hit = pieceAtTap(
      local: local,
      size: boardSize,
      state: _ctrl.state,
      activePlayers: widget.config.seats,
      onlyPlayer: _ctrl.currentPlayer,
    );
    if (hit != null) {
      _ctrl.tapPiece(hit.$1, hit.$2);
    }
  }

  Future<void> _confirmResign() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Resign the match?'),
        content: const Text('The court will declare your opponent the winner.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Resign')),
        ],
      ),
    );
    if (ok == true) _ctrl.resign();
  }

  Future<void> _showResult() async {
    if (!mounted) return;
    final won = !_ctrl.config.isAi(_ctrl.winner ?? -1);
    final statsWon = _ctrl.config.mode == GameMode.passAndPlay
        ? _ctrl.winner == _ctrl.config.seats.first
        : won;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(statsWon ? '👑 Victory!' : '🏁 Defeat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _ctrl.statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'Captures: ${_ctrl.humanCaptures}  •  Rolls: ${_ctrl.humanRolls}\nTurns: ${_ctrl.turnCount}',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // game screen
            },
            child: const Text('Return to Court'),
          ),
          if (widget.config.mode == GameMode.tournament && statsWon)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pushNamed(context, '/levels',
                    arguments: {'mode': GameMode.tournament});
              },
              child: const Text('Next Rung'),
            ),
        ],
      ),
    );
  }
}
