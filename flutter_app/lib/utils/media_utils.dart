import 'dart:io';
import 'package:flutter/material.dart';

/// URLs that failed to load (404 etc.) - show placeholder immediately to avoid repeated exceptions.
/// Pre-populate with known missing files so we never request them.
final Set<String> _failedImageUrls = {
  'http://13.233.133.213:3000/uploads/1770150285426-432750637.jpg',
};

bool isNetworkUrl(String url) {
  return url.startsWith("http://") || url.startsWith("https://");
}

/// Network image that shows placeholder for known-failed URLs (stops repeated 404 exceptions).
Widget safeNetworkImage({
  required String url,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder,
}) {
  if (_failedImageUrls.contains(url)) {
    return Container(
      width: width,
      height: height ?? 200,
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
    );
  }
  return Image.network(
    url,
    fit: fit,
    width: width,
    height: height,
    errorBuilder: (context, error, stackTrace) {
      _failedImageUrls.add(url);
      if (errorBuilder != null) {
        return errorBuilder(context, error, stackTrace);
      }
      return Container(
        width: width,
        height: height ?? 200,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
      );
    },
  );
}

/// Returns a widget showing the first media from [mediaUrls], or null if empty.
Widget? buildPostMediaWidget(List<String>? mediaUrls) {
  final mediaUrl = mediaUrls != null && mediaUrls.isNotEmpty ? mediaUrls.first : null;
  if (mediaUrl == null) return null;
  if (isNetworkUrl(mediaUrl)) {
    return safeNetworkImage(url: mediaUrl, height: 200);
  }
  return Image.file(
    File(mediaUrl),
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) =>
        const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
  );
}
