// lib/features/pet/pet_stage.dart
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'pet_catalog.dart';

// ─────────────────────────────────────────────────────────────
// Avatar de la mascota con cosméticos
// ─────────────────────────────────────────────────────────────
class PetAvatar extends StatelessWidget {
  final PetSpecies species;
  final Map<String, String> equipped;
  final double size;

  const PetAvatar({
    super.key,
    required this.species,
    required this.equipped,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final aura = cosmeticById(equipped[CosmeticSlot.aura]);
    final hat = cosmeticById(equipped[CosmeticSlot.hat]);
    final face = cosmeticById(equipped[CosmeticSlot.face]);
    final neck = cosmeticById(equipped[CosmeticSlot.neck]);
    final glow = aura?.color ?? species.color;

    Widget sparkle(Alignment a, double scale) => Align(
          alignment: a,
          child: Text(aura!.emoji, style: TextStyle(fontSize: size * scale)),
        );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  glow.withValues(alpha: 0.35),
                  glow.withValues(alpha: 0.05),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: glow.withValues(alpha: aura != null ? 0.6 : 0.3),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          if (aura != null) ...[
            sparkle(const Alignment(-0.85, -0.6), 0.16),
            sparkle(const Alignment(0.85, -0.3), 0.13),
            sparkle(const Alignment(0.7, 0.75), 0.17),
            sparkle(const Alignment(-0.7, 0.65), 0.12),
          ],
          Text(species.emoji, style: TextStyle(fontSize: size * 0.55)),
          if (neck != null)
            Align(
              alignment: const Alignment(0, 0.62),
              child: Text(neck.emoji, style: TextStyle(fontSize: size * 0.22)),
            ),
          if (face != null)
            Align(
              alignment: const Alignment(0, -0.12),
              child: Text(face.emoji, style: TextStyle(fontSize: size * 0.24)),
            ),
          if (hat != null)
            Align(
              alignment: const Alignment(0, -0.78),
              child: Text(hat.emoji, style: TextStyle(fontSize: size * 0.28)),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Partícula (emoji que se mueve según una función del tiempo 0..1)
// ─────────────────────────────────────────────────────────────
class _Particle {
  final String emoji;
  final double size;
  final int bornMs;
  final int lifeMs;
  final Offset Function(double t) pos;
  final double Function(double t)? scaleF;
  final double Function(double t)? opacityF;
  final double Function(double t)? rotF;

  const _Particle({
    required this.emoji,
    required this.size,
    required this.bornMs,
    required this.lifeMs,
    required this.pos,
    this.scaleF,
    this.opacityF,
    this.rotF,
  });
}

double _defaultFade(double t) => t < 0.12 ? t / 0.12 : (t > 0.7 ? (1 - t) / 0.3 : 1.0);
double _defaultPop(double t) => t < 0.15 ? 0.5 + (t / 0.15) * 0.5 : 1.0;

String _foodFor(String speciesId) => switch (speciesId) {
      'cat' => '🐟',
      'rabbit' => '🥕',
      'panda' => '🎋',
      'fox' => '🍗',
      'wolf' => '🥩',
      'owl' => '🐭',
      'unicorn' => '🍎',
      'phoenix' => '🍓',
      _ => '🍖',
    };

// ─────────────────────────────────────────────────────────────
// Escenario interactivo
//  · toca o desliza el dedo sobre la mascota → corazones + se inclina
//  · play('alimentar') → la comida cae a su boca y mastica
//  · play('jugar') → una pelota rebota y la mascota salta
//  · play('dormir') → cae la noche, se duerme y salen Zzz
// ─────────────────────────────────────────────────────────────
class PetStage extends StatefulWidget {
  final PetSpecies species;
  final Map<String, String> equipped;
  final String? message;
  final VoidCallback onPet;
  final double avatarSize;

  const PetStage({
    super.key,
    required this.species,
    required this.equipped,
    required this.onPet,
    this.message,
    this.avatarSize = 220,
  });

  @override
  State<PetStage> createState() => PetStageState();
}

class PetStageState extends State<PetStage> with TickerProviderStateMixin {
  static const double _stageH = 300;

  final _rnd = math.Random();
  final _sw = Stopwatch()..start();
  final List<_Particle> _ps = [];
  late final Ticker _ticker = createTicker(_onTick);

  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final AnimationController _react = AnimationController(vsync: this);

  String? _action;
  int _playId = 0;
  bool _sleeping = false;
  Timer? _sleepTimer;

  double _lean = 0;
  double _stroked = 0;
  int _lastHeartMs = 0;
  Size _stage = const Size(320, _stageH);

  @override
  void dispose() {
    _ticker.dispose();
    _idle.dispose();
    _react.dispose();
    _sleepTimer?.cancel();
    super.dispose();
  }

  Offset get _c => Offset(_stage.width / 2, _stage.height / 2);
  double get _size => widget.avatarSize;

  // ───────── motor de partículas ─────────
  void _spawn(_Particle p) {
    _ps.add(p);
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration _) {
    final now = _sw.elapsedMilliseconds;
    _ps.removeWhere((p) => now > p.bornMs + p.lifeMs);
    if (_ps.isEmpty) _ticker.stop();
    if (mounted) setState(() {});
  }

  // ───────── API pública ─────────
  void play(String action) {
    final id = ++_playId;
    _action = action;

    int ms;
    switch (action) {
      case 'acariciar':
        ms = 1100;
        _hearts(count: 7);
        break;
      case 'alimentar':
        ms = 2300;
        _feed();
        break;
      case 'jugar':
        ms = 2400;
        _ball();
        break;
      default: // dormir
        ms = 3600;
        _sleep();
        break;
    }

    _react.duration = Duration(milliseconds: ms);
    _react.forward(from: 0).whenComplete(() {
      if (mounted && id == _playId) setState(() => _action = null);
    });
    setState(() {});
  }

  // ───────── efectos ─────────
  void _hearts({int count = 6, Offset? at, int delayMs = 0}) {
    final now = _sw.elapsedMilliseconds;
    const emojis = ['❤️', '💕', '💖', '💗'];
    for (var i = 0; i < count; i++) {
      final base = at != null
          ? at + Offset((_rnd.nextDouble() - 0.5) * 20, 0)
          : _c + Offset((_rnd.nextDouble() - 0.5) * _size * 0.7, -_size * 0.25);
      final sway = (_rnd.nextDouble() * 2 - 1) * 14;
      final rise = 90 + _rnd.nextDouble() * 60;
      final phase = _rnd.nextDouble() * math.pi * 2;
      _spawn(_Particle(
        emoji: emojis[_rnd.nextInt(emojis.length)],
        size: 20 + _rnd.nextDouble() * 14,
        bornMs: now + delayMs + i * 90,
        lifeMs: 1100 + _rnd.nextInt(400),
        pos: (t) =>
            base +
            Offset(
              math.sin(t * math.pi * 3 + phase) * sway,
              -rise * Curves.easeOut.transform(t),
            ),
      ));
    }
  }

  void _feed() {
    final now = _sw.elapsedMilliseconds;
    final mouth = _c + Offset(0, _size * 0.12);
    const startY = 8.0;

    // la comida cae hacia la boca
    _spawn(_Particle(
      emoji: _foodFor(widget.species.id),
      size: 38,
      bornMs: now,
      lifeMs: 800,
      pos: (t) => Offset(
        mouth.dx + math.sin(t * math.pi) * 20,
        startY + (mouth.dy - startY) * Curves.easeIn.transform(t),
      ),
      scaleF: (t) => t < 0.7 ? 1.0 : 1 - ((t - 0.7) / 0.3) * 0.85,
      opacityF: (t) => t < 0.92 ? 1.0 : (1 - t) / 0.08,
      rotF: (t) => t * math.pi * 2,
    ));

    // migajas / destellos al morder
    for (var i = 0; i < 6; i++) {
      final angle = i / 6 * math.pi * 2;
      _spawn(_Particle(
        emoji: '✨',
        size: 18,
        bornMs: now + 780,
        lifeMs: 700,
        pos: (t) =>
            mouth +
            Offset(math.cos(angle), math.sin(angle)) *
                (46 * Curves.easeOut.transform(t)),
      ));
    }

    // "ñam ñam" y corazones al terminar
    _spawn(_Particle(
      emoji: '😋',
      size: 26,
      bornMs: now + 1000,
      lifeMs: 1000,
      pos: (t) => _c + Offset(_size * 0.34, -_size * 0.15 - 40 * t),
    ));
    _hearts(count: 3, delayMs: 1500);
  }

  void _ball() {
    final now = _sw.elapsedMilliseconds;
    final w = _stage.width;
    final ground = _c.dy + _size * 0.38;

    _spawn(_Particle(
      emoji: '🎾',
      size: 36,
      bornMs: now,
      lifeMs: 2300,
      pos: (t) => Offset(
        w * 0.10 + w * 0.80 * t,
        ground - math.sin(t * math.pi * 4).abs() * 120 * (1 - 0.35 * t),
      ),
      rotF: (t) => t * math.pi * 10,
      scaleF: (_) => 1.0,
      opacityF: (t) => t < 0.05 ? t / 0.05 : (t > 0.92 ? (1 - t) / 0.08 : 1.0),
    ));

    for (final k in [0.25, 0.5, 0.75]) {
      final base = _c + Offset((_rnd.nextDouble() - 0.5) * _size * 0.6, -_size * 0.3);
      _spawn(_Particle(
        emoji: '⭐',
        size: 22,
        bornMs: now + (2300 * k).toInt(),
        lifeMs: 700,
        pos: (t) => base + Offset(0, -50 * Curves.easeOut.transform(t)),
      ));
    }
  }

  void _sleep() {
    final now = _sw.elapsedMilliseconds;
    _sleepTimer?.cancel();
    _sleeping = true;
    _sleepTimer = Timer(const Duration(milliseconds: 3400), () {
      if (mounted) setState(() => _sleeping = false);
    });

    final base = _c + Offset(_size * 0.28, -_size * 0.22);
    for (var i = 0; i < 4; i++) {
      _spawn(_Particle(
        emoji: '💤',
        size: 22.0 + i * 4,
        bornMs: now + i * 750,
        lifeMs: 1700,
        pos: (t) => base + Offset(40 * t + math.sin(t * math.pi * 2) * 8, -90 * t),
      ));
    }
  }

  // ───────── gestos ─────────
  void _onPanUpdate(DragUpdateDetails d) {
    final origin = Offset(_stage.width / 2 - _size / 2, _stage.height / 2 - _size / 2);
    final now = _sw.elapsedMilliseconds;
    _stroked += d.delta.distance;
    if (now - _lastHeartMs > 140) {
      _lastHeartMs = now;
      _hearts(count: 1, at: origin + d.localPosition);
    }
    setState(() => _lean = ((d.localPosition.dx - _size / 2) / (_size / 2)).clamp(-1.0, 1.0));
  }

  void _onPanEnd() {
    setState(() => _lean = 0);
    if (_stroked > 120) widget.onPet();
    _stroked = 0;
  }

  // ───────── build ─────────
  Widget _avatar() {
    final size = _size;

    final child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onPet,
      onPanUpdate: _onPanUpdate,
      onPanEnd: (_) => _onPanEnd(),
      onPanCancel: _onPanEnd,
      child: AnimatedOpacity(
        opacity: _sleeping ? 0.8 : 1,
        duration: const Duration(milliseconds: 400),
        child: PetAvatar(species: widget.species, equipped: widget.equipped, size: size),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _lean),
      duration: const Duration(milliseconds: 150),
      builder: (_, lean, __) => AnimatedBuilder(
        animation: Listenable.merge([_idle, _react]),
        child: child,
        builder: (_, child) {
          final breathe = 1.0 + 0.035 * Curves.easeInOut.transform(_idle.value);
          final t = _react.value;
          double dx = 0, dy = 0, rot = 0, sx = 1, sy = 1;

          switch (_action) {
            case 'acariciar':
              rot = math.sin(t * math.pi * 6) * 0.10 * (1 - t);
              final s = math.sin(t * math.pi);
              sx = 1 + 0.06 * s;
              sy = 1 - 0.04 * s;
              break;
            case 'alimentar':
              if (t < 0.36) {
                dy = -8 * math.sin(t / 0.36 * math.pi);
              } else {
                final k = (t - 0.36) / 0.64;
                final chew = math.sin(k * math.pi * 8).abs() * (1 - k * 0.5);
                sy = 1 - 0.09 * chew;
                sx = 1 + 0.06 * chew;
              }
              break;
            case 'jugar':
              dy = -38 * math.sin(t * math.pi * 4).abs();
              rot = math.sin(t * math.pi * 8) * 0.07;
              dx = (t * 2 - 1) * 28;
              break;
            case 'dormir':
              final k = t < 0.15 ? t / 0.15 : (t > 0.85 ? (1 - t) / 0.15 : 1.0);
              rot = 0.16 * k;
              dy = 10 * k;
              sx = 1 - 0.05 * k;
              break;
          }

          final jump = dy < 0 ? -dy : 0.0;
          final shadow = (1 - jump / 160).clamp(0.5, 1.0);

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Align(
                alignment: const Alignment(0, 0.95),
                child: Transform.scale(
                  scale: shadow,
                  child: Container(
                    width: size * 0.55,
                    height: size * 0.07,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28 * shadow),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(dx + lean * 10, dy),
                child: Transform.rotate(
                  angle: rot + lean * 0.08,
                  child: Transform.scale(
                    scaleX: sx * breathe,
                    scaleY: sy * breathe,
                    alignment: Alignment.bottomCenter,
                    child: child,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget? _buildParticle(_Particle p, int now) {
    final t = (now - p.bornMs) / p.lifeMs;
    if (t < 0 || t > 1) return null;
    final o = p.pos(t);
    final opacity = (p.opacityF ?? _defaultFade)(t).clamp(0.0, 1.0);
    final scale = (p.scaleF ?? _defaultPop)(t);
    final rot = p.rotF?.call(t) ?? 0.0;
    return Positioned(
      left: o.dx - p.size,
      top: o.dy - p.size,
      width: p.size * 2,
      height: p.size * 2,
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: scale,
            child: Center(child: Text(p.emoji, style: TextStyle(fontSize: p.size))),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _stage = Size(c.maxWidth.isFinite ? c.maxWidth : 320, _stageH);
      final now = _sw.elapsedMilliseconds;
      final particles = [
        for (final p in _ps) _buildParticle(p, now),
      ].whereType<Widget>().toList();

      return SizedBox(
        height: _stageH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // noche al dormir
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _sleeping ? 1 : 0,
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xCC0A1238), Color(0xCC1A1050)],
                      ),
                    ),
                    child: const Stack(
                      children: [
                        Positioned(top: 14, right: 20, child: Text('🌙', style: TextStyle(fontSize: 30))),
                        Positioned(top: 34, left: 26, child: Text('⭐', style: TextStyle(fontSize: 14))),
                        Positioned(top: 70, right: 76, child: Text('✨', style: TextStyle(fontSize: 12))),
                        Positioned(top: 90, left: 60, child: Text('⭐', style: TextStyle(fontSize: 10))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // mascota
            Center(child: SizedBox(width: _size, height: _size, child: _avatar())),
            // partículas
            Positioned.fill(child: IgnorePointer(child: Stack(children: particles))),
            // globo de mensaje
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: widget.message == null
                        ? const SizedBox.shrink(key: ValueKey('none'))
                        : Container(
                            key: ValueKey(widget.message),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.message!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF06122E),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}