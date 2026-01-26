import 'package:flutter/material.dart';

enum SFrameFilter { normal, warm, mono, contrast }

ColorFilter? filterToColor(SFrameFilter filter) {
  switch (filter) {
    case SFrameFilter.warm:
      return const ColorFilter.mode(
        Color(0x33FFB37A),
        BlendMode.overlay,
      );
    case SFrameFilter.mono:
      return const ColorFilter.matrix([
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case SFrameFilter.contrast:
      return const ColorFilter.mode(
        Colors.black26,
        BlendMode.overlay,
      );
    default:
      return null;
  }
}
SFrameFilter parseSFrameFilter(String? value) {
  switch (value) {
    case 'warm':
      return SFrameFilter.warm;
    case 'mono':
      return SFrameFilter.mono;
    case 'contrast':
      return SFrameFilter.contrast;
    default:
      return SFrameFilter.normal;
  }
}
