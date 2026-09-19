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

  // DARK / LIGHT MODE: optional colour override. Left null on purpose almost
  // everywhere so the colour comes from the active theme instead.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // DARK / LIGHT MODE HANDLING
    // A TextStyle without a colour keeps whatever colour the parent widget
    // happens to supply, which is how text ends up unreadable after a theme
    // switch. The colour is resolved here instead: first the nearest
    // DefaultTextStyle (AppBar, Card, Scaffold body), then the theme's
    // onSurface colour. Result: dark text in light mode, light text in dark
    // mode, for every CustomText in the app.
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
