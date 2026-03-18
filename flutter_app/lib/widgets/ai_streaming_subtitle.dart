import 'package:flutter/material.dart';
import 'dart:async';

class AIStreamingSubtitle extends StatefulWidget {
  final String text;
  final bool isDark;

  const AIStreamingSubtitle({
    super.key,
    required this.text,
    this.isDark = true,
  });

  @override
  State<AIStreamingSubtitle> createState() => _AIStreamingSubtitleState();
}

class _AIStreamingSubtitleState extends State<AIStreamingSubtitle> {
  String _visible = "";
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startStream() {
    _timer?.cancel();
    _visible = "";
    _index = 0;

    final words = widget.text.split(" ");

    _timer = Timer.periodic(const Duration(milliseconds: 75), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_index >= words.length) {
        t.cancel();
        return;
      }
      setState(() {
        _visible += "${words[_index]} ";
        _index++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark
        ? Colors.white.withOpacity(0.92)
        : const Color(0xFF3D1A6B);

    return Text(
      _visible,
      textAlign: TextAlign.center,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
