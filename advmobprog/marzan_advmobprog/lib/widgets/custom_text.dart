import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    required this.text,
    this.fontSize = 12,
    this.fontFamily = 'Poppins',
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.letterSpacing = 0,
    this.fontStyle = FontStyle.normal,
    this.maxLines,
    this.overflow,
    this.color,
  });

  final String text;
  final double fontSize, letterSpacing;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight fontWeight;
  final TextAlign textAlign;
  final String fontFamily;
  final FontStyle fontStyle;

  // Optional colour override. Left null almost everywhere so the colour
  // comes from the active theme instead.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // A TextStyle without a colour keeps whatever colour the parent widget
    // happens to supply, which is how text ends up low-contrast in light
    // mode. Resolve it explicitly instead: the explicit override, then the
    // nearest DefaultTextStyle, then the theme's onSurface colour.
    final resolvedColor =
        color ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;

    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        color: resolvedColor,
      ),
    );
  }
}
