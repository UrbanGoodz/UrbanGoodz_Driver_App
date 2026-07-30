import 'package:flutter/material.dart';

/// Canonical Urban Goodz brand kit.
///
/// The palette and artwork here are the platform brand. Screens must use the
/// real wordmark from [UgBrand.wordmark] — never a generic Material icon or
/// hand-lettered "UG" text standing in for it.
class UgBrand {
  UgBrand._();

  // Palette — shared with the Shopper and Driver apps and the Admin panel.
  static const Color orange = Color(0xFFED9914);
  static const Color orangeDeep = Color(0xFFC97A08);
  static const Color ink = Color(0xFF161616);
  static const Color inkWarm = Color(0xFF241C12);
  static const Color beige = Color(0xFFE2D3BF);
  static const Color accent = Color(0xFFE5E276);
  static const Color white = Color(0xFFFFFFFF);

  // Artwork
  static const String wordmark = 'assets/brand/ug_wordmark.png';
  static const String appMark = 'assets/brand/ug_app_mark.png';

  static const String tagline = 'Your connection to local everything';

  /// The Urban Goodz wordmark. Keep [width] at or below 240 — the source art
  /// is 300x77, so it goes soft above that.
  static Widget wordmarkImage({double width = 200}) => Image.asset(
    wordmark,
    width: width,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
  );

  /// The Urban Goodz app mark. The source art is a launcher icon on an opaque
  /// square, so it is clipped to the icon's own rounded silhouette — otherwise
  /// it reads as a white sticker on the dark brand backdrop.
  static Widget appMarkImage({double size = 96}) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.235),
    child: Image.asset(
      appMark,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.high,
    ),
  );

  /// Letter-spaced role label, e.g. "VENDOR PORTAL".
  static Widget roleLabel(String text, {Color color = orange}) => Text(
    text.toUpperCase(),
    textAlign: TextAlign.center,
    style: TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 3.2,
    ),
  );
}

/// Dark brand backdrop carrying the angular orange swooshes from the Urban
/// Goodz brand system. Used behind sign-in, splash and empty states.
class UgBrandBackdrop extends StatelessWidget {
  final Widget child;

  const UgBrandBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [UgBrand.ink, UgBrand.inkWarm, UgBrand.ink],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _UgSwooshPainter(),
        child: child,
      ),
    );
  }
}

class _UgSwooshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Top-left swoosh.
    final topPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..color = const Color.fromRGBO(237, 153, 20, 0.16);
    final topArc = Path()
      ..moveTo(-w * 0.10, h * 0.20)
      ..quadraticBezierTo(w * 0.28, -h * 0.04, w * 0.86, h * 0.05);
    canvas.drawPath(topArc, topPaint);

    final topThin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.014
      ..strokeCap = StrokeCap.round
      ..color = const Color.fromRGBO(237, 153, 20, 0.32);
    final topArc2 = Path()
      ..moveTo(-w * 0.06, h * 0.27)
      ..quadraticBezierTo(w * 0.32, h * 0.03, w * 1.02, h * 0.11);
    canvas.drawPath(topArc2, topThin);

    // Bottom-right swoosh.
    final bottomPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..color = const Color.fromRGBO(237, 153, 20, 0.12);
    final bottomArc = Path()
      ..moveTo(w * 0.12, h * 1.02)
      ..quadraticBezierTo(w * 0.74, h * 0.97, w * 1.10, h * 0.76);
    canvas.drawPath(bottomArc, bottomPaint);

    // Warm glow behind the mark.
    final glow = Paint()
      ..shader = const RadialGradient(
        colors: [Color.fromRGBO(237, 153, 20, 0.22), Color.fromRGBO(237, 153, 20, 0.0)],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.5, h * 0.22), radius: w * 0.55));
    canvas.drawCircle(Offset(w * 0.5, h * 0.22), w * 0.55, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
