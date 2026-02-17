import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'login.dart';

// ── Top-level palette consts ────────────────────────────────────────────────
const Color _kNavy  = Color(0xFF0D3B7A);
const Color _kMid   = Color(0xFF1976D2);
const Color _kSky   = Color(0xFF64B5F6);
const Color _kIce   = Color(0xFFD6EAFB);
const Color _kWhite = Color(0xFFFFFFFF);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Controllers ────────────────────────────────────────────────
  late AnimationController _entryCtrl;   // page entry stagger
  late AnimationController _pulseCtrl;   // icon heartbeat
  late AnimationController _floatCtrl;   // bg float
  late AnimationController _slideInCtrl; // content slides IN (up from below)
  late AnimationController _slideOutCtrl;// content slides OUT (up, fades)
  late AnimationController _exitCtrl;    // whole-screen exit

  // ── Entry ──────────────────────────────────────────────────────
  late Animation<double> _bgFade;
  late Animation<double> _iconFade;
  late Animation<double> _iconScale;
  late Animation<double> _nameFade;
  late Animation<Offset>  _nameSlide;
  late Animation<double> _dividerW;
  late Animation<double> _cardFade;
  late Animation<Offset>  _cardRise;

  // ── Loop ───────────────────────────────────────────────────────
  late Animation<double> _pulse;
  late Animation<double> _float;

  // ── Slide IN ───────────────────────────────────────────────────
  late Animation<double> _inFade;
  late Animation<Offset>  _inSlide;

  // ── Slide OUT ──────────────────────────────────────────────────
  late Animation<double> _outFade;
  late Animation<Offset>  _outSlide;

  // ── Exit ───────────────────────────────────────────────────────
  late Animation<double> _exitFade;

  int  _slide    = 0;
  bool _animOut  = false; // true while exit animation running
  bool _exiting  = false;

  // ── Content ────────────────────────────────────────────────────
  static const _slides = [
    _SlideData(icon: Icons.volunteer_activism,  label: 'COMPASSIONATE CARE',
        title: 'OncoSoul',
        body: 'Your trusted companion through\nevery step of the healing journey'),
    _SlideData(icon: Icons.video_call,          label: 'ONLINE CONSULTATION',
        title: 'Your doctor,\nanytime',
        body: 'Secure video calls with licensed\nhospital doctors & nurses'),
    _SlideData(icon: Icons.folder_open,         label: 'MEDICAL RECORDS',
        title: 'Reports always\nat hand',
        body: 'Real-time access to test results\nand your full treatment history'),
    _SlideData(icon: Icons.people_outline,      label: 'COMMUNITY',
        title: 'You are\nnever alone',
        body: 'Share your story, find strength\nand connect with those who care'),
  ];

  static const _bgIcons = [
    _BgIcon(Icons.medical_services,  0.08, 0.09, 80),
    _BgIcon(Icons.monitor_heart,     0.72, 0.06, 60),
    _BgIcon(Icons.science,           0.80, 0.68, 70),
    _BgIcon(Icons.medication,        0.05, 0.60, 55),
    _BgIcon(Icons.vaccines,          0.45, 0.82, 65),
    _BgIcon(Icons.health_and_safety, 0.60, 0.18, 58),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // ── Entry stagger (2 s) ─────────────────────────────────────
    _entryCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000));

    _bgFade    = _iv(0.00, 0.40, Curves.easeOut);
    _iconFade  = _iv(0.10, 0.50, Curves.easeOut);
    _iconScale = Tween<double>(begin: 0.55, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.10, 0.58, curve: Curves.elasticOut)));
    _nameFade  = _iv(0.32, 0.65, Curves.easeOut);
    _nameSlide = Tween<Offset>(begin: const Offset(0, 0.45), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.32, 0.65, curve: Curves.easeOutCubic)));
    _dividerW  = _iv(0.48, 0.78, Curves.easeOutCubic);
    _cardFade  = _iv(0.55, 0.90, Curves.easeOut);
    _cardRise  = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl,
            curve: const Interval(0.55, 0.92, curve: Curves.easeOutCubic)));

    // ── Pulse ───────────────────────────────────────────────────
    _pulseCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000));
    _pulse = Tween<double>(begin: 1.0, end: 1.065).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ── Float ───────────────────────────────────────────────────
    _floatCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 4500));
    _float = Tween<double>(begin: -12.0, end: 12.0).animate(
        CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // ── Slide IN — content rises from below, fades in ───────────
    // Duration 480 ms feels natural, not rushed
    _slideInCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 480));
    _inFade  = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _slideInCtrl, curve: Curves.easeOut));
    _inSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideInCtrl,
            curve: Curves.easeOutCubic));

    // ── Slide OUT — content drifts upward, fades out ─────────────
    // Shorter (280 ms) so the swap feels crisp but not jarring
    _slideOutCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 280));
    _outFade  = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _slideOutCtrl, curve: Curves.easeIn));
    _outSlide = Tween<Offset>(begin: Offset.zero,
            end: const Offset(0, -0.10))
        .animate(CurvedAnimation(parent: _slideOutCtrl,
            curve: Curves.easeIn));

    // ── Exit ────────────────────────────────────────────────────
    _exitCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInOut));

    // ── Start ───────────────────────────────────────────────────
    _entryCtrl.forward().then((_) => _slideInCtrl.forward());
    _pulseCtrl.repeat(reverse: true);
    _floatCtrl.repeat(reverse: true);

    // Slide timer: OUT (drift up + fade) → swap → IN (rise + fade)
    Timer.periodic(const Duration(milliseconds: 3400), (t) {
      if (!mounted) { t.cancel(); return; }
      _slideInCtrl.stop();
      setState(() => _animOut = true);
      _slideOutCtrl.forward(from: 0).then((_) {
        if (!mounted) return;
        setState(() {
          _slide   = (_slide + 1) % _slides.length;
          _animOut = false;
        });
        _slideInCtrl.forward(from: 0);
      });
    });

    Timer(const Duration(milliseconds: 13600), _navigateToLogin);
  }

  Animation<double> _iv(double from, double to, Curve curve) =>
      Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
          parent: _entryCtrl, curve: Interval(from, to, curve: curve)));

  Future<void> _navigateToLogin() async {
    if (!mounted) return;
    // Stop slide timer interference
    setState(() => _exiting = true);
    // Fade the whole splash out
    await _exitCtrl.forward();
    if (!mounted) return;
    // Login page fades in cleanly — no slide, no jitter
    Navigator.pushReplacement(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => LoginPage(),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
        child: child,
      ),
    ));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _slideInCtrl.dispose();
    _slideOutCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F9FF),
        body: AnimatedBuilder(
          animation: Listenable.merge([
            _entryCtrl, _pulseCtrl, _floatCtrl,
            _slideInCtrl, _slideOutCtrl, _exitCtrl,
          ]),
          builder: (_, __) {
            Widget content = Stack(fit: StackFit.expand, children: [

              // 1 ── Background gradient
              Opacity(opacity: _bgFade.value, child: const _Bg()),

              // 2 ── Dot texture
              Opacity(opacity: _bgFade.value * 0.5,
                  child: CustomPaint(size: sz,
                      painter: const _DotTexturePainter())),

              // 3 ── White radial wash (top-left)
              Positioned(top: -sz.width * 0.4, left: -sz.width * 0.2,
                child: Opacity(opacity: _bgFade.value, child: Container(
                  width: sz.width * 1.3, height: sz.width * 1.3,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _kWhite.withOpacity(0.55),
                      _kWhite.withOpacity(0.18),
                      Colors.transparent,
                    ], stops: const [0.0, 0.5, 1.0])),
                )),
              ),

              // 4 ── Blue orb (bottom-right)
              Positioned(bottom: -sz.width * 0.35, right: -sz.width * 0.25,
                child: Opacity(opacity: _bgFade.value * 0.7, child: Container(
                  width: sz.width * 0.9, height: sz.width * 0.9,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _kMid.withOpacity(0.45), Colors.transparent])),
                )),
              ),

              // 5 ── Medical bg icons (float)
              ..._bgIcons.asMap().entries.map((e) {
                final i = e.key; final ico = e.value;
                return Positioned(left: ico.x * sz.width, top: ico.y * sz.height,
                  child: Opacity(opacity: _bgFade.value * 0.055,
                    child: Transform.translate(
                        offset: Offset(0, _float.value * (i.isEven ? 0.7 : -0.7)),
                      child: Transform.rotate(angle: i * math.pi / 7,
                        child: Icon(ico.icon, size: ico.size, color: _kNavy)))));
              }),

              // 6 ── Side orbs
              Positioned(top: sz.height * 0.30, left: -20,
                  child: _Orb(90, 0.12, Offset(0, _float.value * 0.5))),
              Positioned(top: sz.height * 0.55, right: -15,
                  child: _Orb(70, 0.10, Offset(0, _float.value * -0.6))),

              // 7 ── ECG line
              Positioned(bottom: sz.height * 0.10, left: 0, right: 0,
                child: Opacity(opacity: _bgFade.value * 0.10,
                  child: CustomPaint(size: Size(sz.width, 36),
                      painter: const _EcgPainter()))),

              // 8 ── Main content
              SafeArea(child: Column(children: [
                const Spacer(flex: 3),
                _buildIcon(),
                const SizedBox(height: 28),
                _buildName(),
                const Spacer(flex: 3),
                _buildCard(),
                const Spacer(flex: 2),
                _buildFooter(),
                const SizedBox(height: 44),
              ])),
            ]);

            if (_exiting) {
              content = FadeTransition(opacity: _exitFade, child: content);
            }
            return content;
          },
        ),
      ),
    );
  }

  // ── Icon ───────────────────────────────────────────────────────
  Widget _buildIcon() => Opacity(opacity: _iconFade.value,
    child: ScaleTransition(scale: _iconScale,
      child: AnimatedBuilder(animation: _pulseCtrl, builder: (_, __) {
        final p = _pulse.value;
        return Stack(alignment: Alignment.center, children: [
          // Pulse ring
          Container(
            width: 130 + (p - 1.0) * 80,
            height: 130 + (p - 1.0) * 80,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: _kNavy.withOpacity(0.06 * (2.0 - p)))),
          // White circle
          Container(width: 118, height: 118,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(
                  colors: [_kWhite, _kIce.withOpacity(0.8)]),
              boxShadow: [
                BoxShadow(color: _kNavy.withOpacity(0.15),
                    blurRadius: 28, spreadRadius: 2,
                    offset: const Offset(0, 8)),
                BoxShadow(color: _kWhite.withOpacity(0.8),
                    blurRadius: 20, spreadRadius: 4),
                BoxShadow(color: _kSky.withOpacity(0.3 * p),
                    blurRadius: 40, spreadRadius: 8),
              ],
            )),
          const Icon(Icons.volunteer_activism, size: 54, color: _kNavy),
        ]);
      }),
    ),
  );

  // ── Name block ─────────────────────────────────────────────────
  Widget _buildName() => SlideTransition(position: _nameSlide,
    child: FadeTransition(opacity: _nameFade,
      child: Column(children: [
        const Text('OncoSoul', style: TextStyle(
          fontSize: 42, fontWeight: FontWeight.w800,
          color: _kNavy, letterSpacing: 1.4, height: 1.0)),
        const SizedBox(height: 10),
        Container(width: 200 * _dividerW.value, height: 1.5,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(colors: [Colors.transparent,
              _kNavy.withOpacity(0.38), Colors.transparent]))),
        const SizedBox(height: 8),
        Opacity(opacity: _dividerW.value,
          child: Text('C O M P R E H E N S I V E   C A N C E R   C A R E',
            style: TextStyle(fontSize: 9, color: _kNavy.withOpacity(0.48),
                letterSpacing: 2.0, fontWeight: FontWeight.w500))),
      ]),
    ),
  );

  // ── Slide card ─────────────────────────────────────────────────
  Widget _buildCard() {
    final s = _slides[_slide];
    // Pick correct animation based on whether we're animating out or in
    final fade  = _animOut ? _outFade  : _inFade;
    final slide = _animOut ? _outSlide : _inSlide;

    return SlideTransition(position: _cardRise,
      child: FadeTransition(opacity: _cardFade,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_kWhite.withOpacity(0.82), _kWhite.withOpacity(0.65)]),
            border: Border.all(color: _kWhite.withOpacity(0.90), width: 1.5),
            boxShadow: [
              BoxShadow(color: _kNavy.withOpacity(0.11),
                  blurRadius: 40, offset: const Offset(0, 16)),
              BoxShadow(color: _kWhite.withOpacity(0.7),
                  blurRadius: 1, offset: const Offset(0, -1)),
            ],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(28),
            child: Stack(children: [
              // Card inner top sheen
              Positioned(top: 0, left: 0, right: 0,
                child: Container(height: 56,
                  decoration: BoxDecoration(gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [_kWhite.withOpacity(0.55), Colors.transparent])))),

              Padding(padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                  // ── Label pill (own fade, slides from left) ─
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 380),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                            begin: const Offset(-0.12, 0),
                            end: Offset.zero).animate(
                            CurvedAnimation(parent: anim,
                                curve: Curves.easeOutCubic)),
                        child: child)),
                    child: Container(key: ValueKey('pill$_slide'),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: _kNavy.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: _kNavy.withOpacity(0.14), width: 1)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(s.icon, size: 13,
                            color: _kNavy.withOpacity(0.72)),
                        const SizedBox(width: 7),
                        Text(s.label, style: TextStyle(fontSize: 10,
                          color: _kNavy.withOpacity(0.72),
                          fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Headline & body (slide up/down smoothly) ─
                  SlideTransition(position: slide,
                    child: FadeTransition(opacity: fade,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w800,
                            color: _kNavy, height: 1.22, letterSpacing: 0.1)),
                          const SizedBox(height: 10),
                          Text(s.body, style: TextStyle(fontSize: 14,
                            color: _kNavy.withOpacity(0.58), height: 1.65)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Dots ─────────────────────────────────────
                  Row(children: List.generate(_slides.length, (i) {
                    final active = i == _slide;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(right: 7),
                      width: active ? 28 : 8, height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: active
                            ? _kNavy
                            : _kNavy.withOpacity(0.18)));
                  })),
                ])),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────
  Widget _buildFooter() => Opacity(opacity: _cardFade.value,
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 17, height: 17,
        child: CircularProgressIndicator(strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(
              _kNavy.withOpacity(0.45)))),
      const SizedBox(width: 14),
      Text('Getting things ready…', style: TextStyle(fontSize: 13,
          color: _kNavy.withOpacity(0.45), letterSpacing: 0.3,
          fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Static background widget ───────────────────────────────────────────────
class _Bg extends StatelessWidget {
  const _Bg();
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          _kWhite, _kIce,
          Color(0xFFBBD9F5), Color(0xFF4A90D9), _kMid,
        ],
        stops: [0.0, 0.22, 0.48, 0.74, 1.0],
      )));
}

// ── Floating orb ──────────────────────────────────────────────────────────
class _Orb extends StatelessWidget {
  final double size, opacity;
  final Offset offset;
  const _Orb(this.size, this.opacity, this.offset);
  @override
  Widget build(BuildContext context) => Transform.translate(offset: offset,
    child: Container(width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          _kWhite.withOpacity(opacity), Colors.transparent]))));
}

// ── Data models ────────────────────────────────────────────────────────────
class _SlideData {
  final IconData icon;
  final String label, title, body;
  const _SlideData({required this.icon, required this.label,
      required this.title, required this.body});
}

class _BgIcon {
  final IconData icon;
  final double x, y, size;
  const _BgIcon(this.icon, this.x, this.y, this.size);
}

// ── Dot texture ────────────────────────────────────────────────────────────
class _DotTexturePainter extends CustomPainter {
  const _DotTexturePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = _kNavy.withOpacity(0.028)
      ..style  = PaintingStyle.fill;
    const gap = 28.0;
    for (double x = gap / 2; x < size.width;  x += gap)
      for (double y = gap / 2; y < size.height; y += gap)
        canvas.drawCircle(Offset(x, y), 1.4, p);
  }
  @override bool shouldRepaint(_) => false;
}

// ── ECG line ───────────────────────────────────────────────────────────────
class _EcgPainter extends CustomPainter {
  const _EcgPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color       = _kNavy
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;
    final path = Path();
    const seg = 80.0;
    final mid = s.height / 2;
    double x = 0;
    while (x < s.width) {
      path.moveTo(x, mid);
      path.lineTo(x + seg * 0.30, mid);
      path.lineTo(x + seg * 0.38, mid - s.height * 0.60);
      path.lineTo(x + seg * 0.45, mid + s.height * 0.90);
      path.lineTo(x + seg * 0.52, mid - s.height * 0.30);
      path.lineTo(x + seg * 0.58, mid);
      path.lineTo(x + seg, mid);
      x += seg;
    }
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(_) => false;
}