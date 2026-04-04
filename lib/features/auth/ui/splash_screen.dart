import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _particleCtrl;
  late final AnimationController _pulseCtrl;

  // ── Logo animations ───────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoRotate;

  // ── Text animations ───────────────────────────────────────────────────────
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;

  // ── Pulse animation ───────────────────────────────────────────────────────
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Logo controller: 0 → 900ms
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Text controller: starts at 600ms, 600ms duration
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Particle controller: continuous loop
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Pulse controller: continuous subtle pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // ── Logo animations ──────────────────────────────────────────────────
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_logoCtrl);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _logoRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic),
    );

    // ── Text animations ──────────────────────────────────────────────────
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: const Interval(0.0, 0.6)),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Pulse animation ──────────────────────────────────────────────────
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // ── Sequence: logo → text → navigate ────────────────────────────────
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    await _logoCtrl.forward();
    if (!mounted) return;

    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Gradient background ─────────────────────────────────────
          const _GradientBackground(),

          // ── Floating particles ──────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(_particleCtrl.value),
              size: size,
            ),
          ),

          // ── Centered content ────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo ──────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _logoCtrl,
                  builder: (_, child) => FadeTransition(
                    opacity: _logoOpacity,
                    child: Transform.rotate(
                      angle: _logoRotate.value,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: child,
                      ),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseScale.value,
                      child: child,
                    ),
                    child: const _LogoWidget(),
                  ),
                ),

                const SizedBox(height: 36),

                // ── App name ──────────────────────────────────────────
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleOpacity,
                    child: const Text(
                      'G13 Money',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Color(0x40000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Tagline ───────────────────────────────────────────
                FadeTransition(
                  opacity: _subtitleOpacity,
                  child: Text(
                    'Quản lý tài chính thông minh',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom loading indicator ────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _subtitleOpacity,
              child: const _BottomLoader(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient Background ───────────────────────────────────────────────────────

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A5C60),
            Color(0xFF0D7377),
            Color(0xFF14A085),
            Color(0xFF1BBF9A),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
    );
  }
}

// ── Logo Widget ───────────────────────────────────────────────────────────────

class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFE8F8F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D7377).withValues(alpha: 0.45),
            blurRadius: 40,
            spreadRadius: 8,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring glow
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),
          // Main icon
          CustomPaint(
            size: const Size(68, 68),
            painter: _FinanceIconPainter(),
          ),
        ],
      ),
    );
  }
}

// ── Custom Finance Icon Painter ───────────────────────────────────────────────

class _FinanceIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final primary = const Color(0xFF0D7377);
    final accent = const Color(0xFF14A085);
    final gold = const Color(0xFFF5A623);

    // ── Wallet body ──────────────────────────────────────────────────
    final walletPaint = Paint()
      ..color = primary
      ..style = PaintingStyle.fill;

    final walletRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 16, size.width - 4, size.height - 26),
      const Radius.circular(10),
    );
    canvas.drawRRect(walletRect, walletPaint);

    // ── Wallet flap / top ────────────────────────────────────────────
    final flapPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    final flapRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 12, size.width - 4, 18),
      const Radius.circular(8),
    );
    canvas.drawRRect(flapRect, flapPaint);

    // ── Coin circle ──────────────────────────────────────────────────
    final coinPaint = Paint()
      ..color = gold
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.62),
      9,
      coinPaint,
    );

    // Coin shine
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.72 - 2, size.height * 0.62 - 2),
      4,
      shinePaint,
    );

    // ── Trend arrow / chart bars ─────────────────────────────────────
    final barPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    // Three ascending bars
    final barHeights = [10.0, 15.0, 20.0];
    final barWidth = 7.0;
    final startX = size.width * 0.12;
    final baseY = size.height * 0.78;
    const gap = 11.0;

    for (var i = 0; i < 3; i++) {
      final left = startX + i * (barWidth + gap);
      final top = baseY - barHeights[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, barHeights[i]),
          const Radius.circular(3),
        ),
        barPaint,
      );
    }

    // ── Upward trend arrow ───────────────────────────────────────────
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arrowPath = Path()
      ..moveTo(size.width * 0.15, size.height * 0.38)
      ..lineTo(size.width * 0.28, size.height * 0.26)
      ..lineTo(size.width * 0.42, size.height * 0.33)
      ..lineTo(size.width * 0.56, size.height * 0.20);

    canvas.drawPath(arrowPath, arrowPaint);

    // Arrow head
    final headPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final headPath = Path()
      ..moveTo(size.width * 0.56, size.height * 0.20)
      ..lineTo(size.width * 0.50, size.height * 0.18)
      ..lineTo(size.width * 0.58, size.height * 0.14)
      ..lineTo(size.width * 0.62, size.height * 0.22)
      ..close();
    canvas.drawPath(headPath, headPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Particle Painter ──────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;

  _ParticlePainter(this.progress);

  static final List<_Particle> _particles = List.generate(18, (i) {
    final rng = math.Random(i * 37 + 13);
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: rng.nextDouble() * 4 + 2,
      speed: rng.nextDouble() * 0.12 + 0.04,
      phase: rng.nextDouble(),
      opacity: rng.nextDouble() * 0.25 + 0.06,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = (p.y - t * 0.8) % 1.0;
      final wobble = math.sin((t + p.phase) * math.pi * 2) * 0.04;
      final x = p.x + wobble;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, size, speed, phase, opacity;
  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.opacity,
  });
}

// ── Bottom Loader ─────────────────────────────────────────────────────────────

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Đang khởi động...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
