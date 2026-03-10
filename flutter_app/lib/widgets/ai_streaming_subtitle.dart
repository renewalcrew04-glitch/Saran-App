import 'package:flutter/material.dart';
import 'dart:async';

class AIStreamingSubtitle extends StatefulWidget {

  final String text;

  const AIStreamingSubtitle({super.key, required this.text});

  @override
  State<AIStreamingSubtitle> createState() => _AIStreamingSubtitleState();
}

class _AIStreamingSubtitleState extends State<AIStreamingSubtitle> {

  String visibleText = "";
  int index = 0;

  @override
  void initState() {
    super.initState();
    streamText();
  }

  void streamText() {

    List<String> words = widget.text.split(" ");

    Timer.periodic(const Duration(milliseconds: 80), (timer) {

      if (index >= words.length) {
        timer.cancel();
        return;
      }

      setState(() {
        visibleText += "${words[index]} ";
      });

      index++;
    });

  }

  @override
  Widget build(BuildContext context) {

    return Text(
      visibleText,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
      ),
    );
  }
}