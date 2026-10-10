import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/storage.dart';

/// 1. Splash — royal crest reveal, then Home.
class SplashScreen extends StatefulWidget {
  final AppState app;
  const SplashScreen({super.key, required this.app});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    AudioService().init(soundOn: widget.app.soundOn, musicOn: widget.app.musicOn);
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      AudioService().menuMusic();
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash.png', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.25)),
          Center(
            child: ScaleTransition(
          scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 4),
                  color: const Color(0xFF8E0E2A),
                ),
                child: const Center(
                  child: Text('♛', style: TextStyle(fontSize: 64, color: Color(0xFFFFF8E7))),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'QAVEX PACHISI ROYAL',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The ancient game of kings',
                style: TextStyle(color: Color(0xFFFFF8E7), fontSize: 15),
              ),
            ],
          ),
        ),
          ),
        ],
      ),
    );
  }
}
