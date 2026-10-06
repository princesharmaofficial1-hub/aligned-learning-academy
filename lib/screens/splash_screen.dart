import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Cinematic motion timeline animations
  late Animation<double> _cameraZoom;
  late Animation<double> _markScale;
  late Animation<double> _markOpacity;
  late Animation<double> _markTilt;
  late Animation<double> _markGlow;
  late Animation<double> _textWipe;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    // 1. Camera Push (Cinetic 3D momentum)
    _cameraZoom = Tween<double>(begin: 0.93, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.92, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Mark (aligned_mark.svg) Entrance
    _markScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.44, curve: Curves.easeOutBack),
      ),
    );

    _markOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.32, curve: Curves.easeIn),
      ),
    );

    _markTilt = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.06, 0.44, curve: Curves.easeOutCubic),
      ),
    );

    _markGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.50, curve: Curves.easeInOut),
      ),
    );

    // 3. Full Text (aligned_text_full.svg) Reveal
    _textWipe = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.36, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.36, 0.56, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<double>(begin: -10.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.36, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Subtitle & Tagline reveal
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.60, 0.88, curve: Curves.easeOut),
      ),
    );

    // Launch sequence
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const HomeNavigationScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A12), // Pure deep obsidian dark
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Sleek dark linear gradient background (No green circles or halos)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0E1626), // Subtle navy-slate top
                  Color(0xFF070A12), // Obsidian bottom
                ],
              ),
            ),
          ),

          // Main Centered Brand Reveal
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _cameraZoom.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 1. ANIMATED ALIGNED MARK (aligned_mark.svg)
                              Opacity(
                                opacity: _markOpacity.value,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0015)
                                    ..rotateY(_markTilt.value)
                                    ..scaleByDouble(_markScale.value, _markScale.value, 1.0, 1.0),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Soft brand aura glow
                                      if (_markGlow.value > 0.0)
                                        Container(
                                          width: 92,
                                          height: 82,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF1B77BC)
                                                    .withAlpha((130 * _markGlow.value).toInt()),
                                                blurRadius: 42,
                                                spreadRadius: 8,
                                              ),
                                              BoxShadow(
                                                color: const Color(0xFF4ED44E)
                                                    .withAlpha((100 * _markGlow.value).toInt()),
                                                blurRadius: 28,
                                                spreadRadius: 4,
                                                offset: const Offset(4, 4),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Crisp Vector Logo Mark
                                      SvgPicture.asset(
                                        'assets/images/aligned_mark.svg',
                                        height: 82,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 20),

                              // 2. ANIMATED FULL TEXT (aligned_text_full.svg)
                              Transform.translate(
                                offset: Offset(_textSlide.value, 0),
                                child: Opacity(
                                  opacity: _textOpacity.value,
                                  child: ClipRect(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: _textWipe.value,
                                      child: SvgPicture.asset(
                                        'assets/images/aligned_text_full.svg',
                                        height: 58,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Enterprise Subtitle (Clean minimal typography)
                      Opacity(
                        opacity: _taglineOpacity.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minimal tech line divider
                            Container(
                              width: 44,
                              height: 1.4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.brandBlue.withAlpha(220),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'ENTERPRISE TECHNICAL ACADEMY',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3.4,
                                color: AppTheme.textSecondary.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Minimal bottom label
          Positioned(
            bottom: 36,
            child: AnimatedBuilder(
              animation: _taglineOpacity,
              builder: (context, child) {
                return Opacity(
                  opacity: _taglineOpacity.value,
                  child: Text(
                    'Continuous Learning Environment',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.textMuted.withAlpha(160),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
