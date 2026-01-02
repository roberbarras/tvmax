import 'dart:math' as math;
import 'package:flutter/material.dart';

class AvailabilityBanner extends StatelessWidget {
  final String text;
  final Color color;
  final double size; // The square size of the banner widget container
  final double bannerHeight; // Thickness of the ribbon
  final double fontSize;

  const AvailabilityBanner({
    super.key,
    required this.text,
    required this.color,
    this.size = 40, // Reduced from 50
    this.bannerHeight = 12, // Reduced from 16
    this.fontSize = 7, // Reduced from 8
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect( 
        child: CustomPaint(
          painter: _BannerPainter(
            color: color, 
            text: text, 
            bannerHeight: bannerHeight,
            fontSize: fontSize
          ),
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  final Color color;
  final String text;
  final double bannerHeight;
  final double fontSize;

  _BannerPainter({
    required this.color, 
    required this.text,
    required this.bannerHeight,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw diagonal ribbon
    // User wants it "more to the top right".
    
    canvas.save();
    // Translate to top-right corner
    canvas.translate(size.width, 0);
    canvas.rotate(math.pi / 4);
    
    // The previous implementation center was offset by size.width / 2.5
    // To move it closer to the corner, we decrease the offset.
    // Ideally, the bottom edge of the banner should just clear the corner? 
    // Or it should cut the corner cleanly.
    
    // For a 40x40 box:
    // Diagonal length is approx 56.
    // If we want the ribbon center to be closer to the corner (0,0 of rotated frame).
    
    double offsetFromCorner = size.width / 3.0; // Decreased denominator moves it further down? No.
    // 0 is the corner. Positive Y is down.
    // size.width / 2.5 was creating a triangle.
    // Let's try to put it closer to the tip.
    
    offsetFromCorner = size.width / 3.2;

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, offsetFromCorner), 
        width: size.width * 2, 
        height: bannerHeight
      ), 
      paint,
    );
    
    // Draw Text
    final textSpan = TextSpan(
      text: text.toUpperCase(),
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas, 
      Offset(-textPainter.width / 2, offsetFromCorner - textPainter.height / 2),
    );
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
