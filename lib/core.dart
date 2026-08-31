import 'dart:ui';
import 'package:flutter/material.dart';

/// Tokens del sistema de diseno — estilo glass financiero.
class T {
  static const bg = Color(0xFFF0F2F8);
  static const bg2 = Color(0xFFF8F9FC);
  static const ink = Color(0xFF0C1B2E);
  static const ink70 = Color(0xA80C1B2E);
  static const ink45 = Color(0x730C1B2E);
  static const ink25 = Color(0x400C1B2E);
  static const hair = Color(0x170C1B2E);

  static const volt = Color(0xFF3B5BDB);
  static const iris = Color(0xFF6C5CE0);
  static const sun = Color(0xFFFF9F43);
  static const clay = Color(0xFFE4573D);
  static const go = Color(0xFF10855A);
  static const mint = Color(0xFF00C9A7);

  static const edge = Color(0xEBFFFFFF);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [volt, iris],
  );

  static const budgetCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B5BDB), Color(0xFF5B4FCF), Color(0xFF6C5CE0)],
    stops: [0, .5, 1],
  );

  static const mono = 'monospace';

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: volt, surface: bg2),
      scaffoldBackgroundColor: bg,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ink,
      ),
    );
  }
}

class Ambient extends StatelessWidget {
  final Widget child;
  const Ambient({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: ColoredBox(color: T.bg)),
        Positioned(
          top: -140,
          right: -120,
          child: _Blob(color: T.volt.withOpacity(.28), size: 340),
        ),
        Positioned(
          bottom: -160,
          left: -120,
          child: _Blob(color: T.iris.withOpacity(.24), size: 360),
        ),
        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      ),
    );
  }
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? border;
  final VoidCallback? onTap;
  final Color? tint;

  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(15),
    this.radius = 20,
    this.border,
    this.onTap,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: r,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: tint != null
                  ? [tint!.withOpacity(.85), tint!.withOpacity(.65)]
                  : [Colors.white.withOpacity(.74), Colors.white.withOpacity(.54)],
            ),
            border: Border.all(color: border ?? T.edge, width: border != null ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0E2A4E).withOpacity(.10),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: r,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class Primary extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  const Primary({super.key, required this.label, this.onTap, this.height = 52});

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Opacity(
      opacity: on ? 1 : .45,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: T.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: on
                ? [BoxShadow(color: T.volt.withOpacity(.42), blurRadius: 20, offset: const Offset(0, 10))]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: height > 60 ? 18 : 15,
              letterSpacing: -.2,
            ),
          ),
        ),
      ),
    );
  }
}

class Readout extends StatelessWidget {
  final String value;
  final String? unit;
  final double size;
  final Color? color;
  const Readout(this.value, {super.key, this.unit, this.size = 34, this.color});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: T.mono,
          fontWeight: FontWeight.w700,
          fontSize: size,
          height: 1,
          letterSpacing: -1,
          color: color ?? T.ink,
        ),
        children: [
          if (unit != null)
            TextSpan(
              text: '  $unit',
              style: TextStyle(
                fontFamily: T.mono,
                fontWeight: FontWeight.w400,
                fontSize: size * .4,
                color: T.ink45,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}

class Label extends StatelessWidget {
  final String text;
  const Label(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
            fontFamily: T.mono, fontSize: 9, letterSpacing: 1.6, color: T.ink45),
      );
}

class H1 extends StatelessWidget {
  final String text;
  const H1(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.8, height: 1.1));
}

class KV extends StatelessWidget {
  final String k;
  final String v;
  final Color? color;
  const KV(this.k, this.v, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: T.hair)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 12.5, color: T.ink45)),
          Text(v,
              style: TextStyle(
                  fontFamily: T.mono,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: color ?? T.ink)),
        ],
      ),
    );
  }
}

String money(double v, {String symbol = '\$'}) {
  final abs = v.abs();
  final s = abs >= 1000
      ? '${(abs / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}k'
      : abs.toStringAsFixed(2);
  final prefix = v < 0 ? '-' : '';
  return '$prefix$symbol$s';
}

String moneyFull(double v, {String symbol = '\$'}) {
  final prefix = v < 0 ? '-' : '';
  return '$prefix$symbol${v.abs().toStringAsFixed(2)}';
}
