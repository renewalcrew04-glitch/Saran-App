import 'dart:ui';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// iOS 26.2 Liquid Glass — Correct Implementation
//
// What makes it look real:
//  ① Specular highlight: pure-white first stop (0%) — the "glint" of a lamp.
//  ② Slightly cool (blue-gray) body so the element reads AGAINST a white page.
//  ③ Deeper blue-gray depth at the bottom — gives the element a physical edge.
//  ④ Two-tone border: bright white top (reflection) + gray bottom (shadow edge).
//  ⑤ Elevated drop shadow in light mode — lifts glass off the background.
//  ⑥ Colored chips: vivid accent as thin tint + specular highlight.
// ═══════════════════════════════════════════════════════════════════════════════

// ─── Shared helpers ─────────────────────────────────────────────────────────

BorderRadius _shrink(BorderRadius br, double by) => BorderRadius.only(
      topLeft: Radius.circular((br.topLeft.x - by).clamp(0, 9999)),
      topRight: Radius.circular((br.topRight.x - by).clamp(0, 9999)),
      bottomLeft: Radius.circular((br.bottomLeft.x - by).clamp(0, 9999)),
      bottomRight: Radius.circular((br.bottomRight.x - by).clamp(0, 9999)),
    );

List<BoxShadow> _lightShadow({
  double alpha = 0.13,
  double blur = 20,
  double spread = -2,
  Offset offset = const Offset(0, 5),
}) =>
    [
      BoxShadow(
        color: const Color(0xFF7070A0).withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
    ];

// ─── GlassBox ────────────────────────────────────────────────────────────────

/// Generic iOS-26.2-style liquid glass container.
///
/// Layer anatomy (bottom → top inside the clip):
///   ① blur backdrop
///   ② fill gradient: specular (bright, 0–20%) → blue-tinted body → depth
///   ③ child / padding
///
/// Wrapped in a gradient border shell (white→gray in light / white→dim in dark).
class GlassBox extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final Color? tintColor;
  final double? width;
  final double? height;
  final BoxBorder? border;

  const GlassBox({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blur = 24,
    this.padding,
    this.tintColor,
    this.width,
    this.height,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ── Fill gradient: specular → cool body → depth ──────────────────────────
    final Color spec, body, depth;
    if (tintColor != null) {
      spec  = Colors.white.withValues(alpha: isDark ? 0.38 : 1.0);
      body  = tintColor!.withValues(alpha: isDark ? 0.16 : 0.72);
      depth = isDark
          ? Colors.black.withValues(alpha: 0.18)
          : tintColor!.withValues(alpha: 0.58);
    } else {
      // Light: pure white glint → nearly-white cool body → subtle edge
      spec  = Colors.white.withValues(alpha: isDark ? 0.38 : 1.0);
      body  = isDark
          ? Colors.white.withValues(alpha: 0.09)
          : Colors.white.withValues(alpha: 0.78);
      depth = isDark
          ? Colors.black.withValues(alpha: 0.16)
          : const Color(0xFFECECF8).withValues(alpha: 0.82);
    }

    // ── Border shell: white top (reflection) / soft gray bottom (shadow) ────
    final borderTop = isDark
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.white.withValues(alpha: 0.95);    // near-invisible on white bg
    final borderBot = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFD0D0E0).withValues(alpha: 0.80); // soft shadow edge

    // ── Shadow (light mode — lifts glass from page) ──────────────────────────
    final shadows = isDark ? const <BoxShadow>[] : _lightShadow();

    final inner = _shrink(borderRadius, 1);

    final glassCore = ClipRRect(
      borderRadius: inner,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [spec, body, depth],
              stops: const [0.0, 0.20, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );

    if (border != null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          border: border,
          boxShadow: shadows,
        ),
        child: glassCore,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: [borderTop, borderBot],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: shadows,
      ),
      padding: const EdgeInsets.all(1),
      child: glassCore,
    );
  }
}

// ─── GlassIconButton ─────────────────────────────────────────────────────────

/// Circular liquid glass icon button.
class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;
  final double iconSize;

  const GlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.iconColor,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: GlassBox(
        borderRadius: BorderRadius.circular(size / 2),
        blur: 20,
        width: size,
        height: size,
        child: Center(
          child: Icon(icon, size: iconSize,
              color: iconColor ?? scheme.onSurface),
        ),
      ),
    );
  }
}

// ─── GlassButton ─────────────────────────────────────────────────────────────

/// Pill-shaped glass action button.
/// [isPrimary] → vivid orange-to-purple gradient. [!isPrimary] → clear glass.
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isPrimary;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isPrimary = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      const kA = Color(0xFFFF6B35);
      const kB = Color(0xFF7B2D8B);
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [kA, kB],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                  color: kA.withValues(alpha: 0.40),
                  blurRadius: 14,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: _row(Colors.white),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: GlassBox(
        borderRadius: BorderRadius.circular(24),
        padding: padding,
        child: _row(Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _row(Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      );
}

// ─── LiquidGlassChip ─────────────────────────────────────────────────────────

/// iOS-26.2-style Liquid Glass chip / tag.
///
/// Three visual modes:
///  [isActive]        → solid orange gradient (primary selected state)
///  [fixedColor≠null] → accent-tinted glass with vivid specular highlight
///  [default]         → clear glass (filter tabs, unselected options)
class LiquidGlassChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback? onTap;
  final Color? activeColor;
  final Color? activeColorEnd;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;

  /// Accent color for colored chips (hashtags / interests).
  final Color? fixedColor;
  final Color? textColor;

  const LiquidGlassChip({
    super.key,
    required this.label,
    this.isActive = false,
    this.onTap,
    this.activeColor = const Color(0xFFFF9D5C),
    this.activeColorEnd = const Color(0xFFFF5722),
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    this.borderRadius = 999,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.fixedColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    // ── ① ACTIVE: vibrant gradient pill ─────────────────────────────────────
    if (isActive) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [activeColor!, activeColorEnd!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.28), width: 1),
            boxShadow: [
              BoxShadow(
                color: activeColorEnd!.withValues(alpha: 0.42),
                blurRadius: 12,
                spreadRadius: -2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(label,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: fontWeight)),
        ),
      );
    }

    // ── ② COLORED ACCENT: accent-tinted glass with gloss ────────────────────
    if (fixedColor != null) {
      final accent = fixedColor!;
      // Light mode: lower bg alpha so the chip reads as tinted, not opaque
      final bgAlpha = isDark ? 0.18 : 0.12;
      final borderAlpha = isDark ? 0.50 : 0.45;
      final effectiveText = textColor ?? accent;
      final shadows = isDark
          ? const <BoxShadow>[]
          : _lightShadow(
              alpha: 0.09, blur: 10, spread: -1, offset: const Offset(0, 3));

      return GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(this.borderRadius),
            border: Border.all(
                color: accent.withValues(alpha: borderAlpha), width: 1),
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(this.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      // Light: full-white glint at top, then accent tint
                      Colors.white.withValues(alpha: isDark ? 0.28 : 1.0),
                      accent.withValues(alpha: bgAlpha),
                      accent.withValues(alpha: bgAlpha * 0.55),
                    ],
                    stops: const [0.0, 0.22, 1.0],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(this.borderRadius),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: effectiveText,
                        fontSize: fontSize,
                        fontWeight: fontWeight)),
              ),
            ),
          ),
        ),
      );
    }

    // ── ③ CLEAR GLASS: frosted pill ──────────────────────────────────────────
    //
    // Light: white glint → cool blue-gray body → deeper edge, gray border.
    // Dark: dark glass, white gradient border.
    //
    final borderTop = isDark
        ? Colors.white.withValues(alpha: 0.26)
        : Colors.white.withValues(alpha: 0.95);  // near-invisible on white bg
    final borderBot = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFD0D0E0).withValues(alpha: 0.80); // soft shadow edge

    final spec  = Colors.white.withValues(alpha: isDark ? 0.38 : 1.0);
    final body  = isDark
        ? Colors.white.withValues(alpha: 0.09)
        : Colors.white.withValues(alpha: 0.78);
    final depth = isDark
        ? Colors.black.withValues(alpha: 0.14)
        : const Color(0xFFECECF8).withValues(alpha: 0.82);

    final shadows = isDark
        ? const <BoxShadow>[]
        : _lightShadow(alpha: 0.10, blur: 12, spread: -1, offset: const Offset(0, 3));

    final innerR = (this.borderRadius - 1).clamp(0.0, 9999.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(this.borderRadius),
          gradient: LinearGradient(
            colors: [borderTop, borderBot],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: shadows,
        ),
        padding: const EdgeInsets.all(1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerR),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [spec, body, depth],
                  stops: const [0.0, 0.20, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(innerR),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: textColor ??
                      scheme.onSurface.withValues(
                          alpha: isDark ? 0.88 : 0.82),
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
