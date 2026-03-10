import 'package:flutter/material.dart';

/// Combines post text with hashtags for display. Hashtags on a separate line.
String combinedPostText({required String text, required List<String> hashtags}) {
  if (hashtags.isEmpty) return text;
  final fromField = hashtags.join(' ');
  if (text.isEmpty) return fromField;
  return '$text\n$fromField';
}

/// Builds styled text spans with hashtags highlighted.
List<TextSpan> buildTextSpansWithHashtags(
  String text, {
  Color? textColor,
  Color? hashtagColor,
  double fontSize = 15,
  FontWeight textWeight = FontWeight.w500,
  FontWeight hashtagWeight = FontWeight.w600,
}) {
  if (text.isEmpty) return [];
  final baseColor = textColor ?? Colors.black87;
  final tagColor = hashtagColor ?? Colors.blue;
  final regex = RegExp(r'(#\w+)');
  final spans = <TextSpan>[];
  int lastEnd = 0;
  for (final match in regex.allMatches(text)) {
    if (match.start > lastEnd) {
      spans.add(TextSpan(
        text: text.substring(lastEnd, match.start),
        style: TextStyle(color: baseColor, fontSize: fontSize, fontWeight: textWeight),
      ));
    }
    spans.add(TextSpan(
      text: match.group(0),
      style: TextStyle(color: tagColor, fontSize: fontSize, fontWeight: hashtagWeight),
    ));
    lastEnd = match.end;
  }
  if (lastEnd < text.length) {
    spans.add(TextSpan(
      text: text.substring(lastEnd),
      style: TextStyle(color: baseColor, fontSize: fontSize, fontWeight: textWeight),
    ));
  }
  return spans;
}
