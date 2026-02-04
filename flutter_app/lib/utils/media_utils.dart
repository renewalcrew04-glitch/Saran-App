import 'dart:io';
import 'package:flutter/material.dart';

bool isNetworkUrl(String url) {
  return url.startsWith("http://") || url.startsWith("https://");
}

/// Returns a widget showing the first media from [mediaUrls], or null if empty.
Widget? buildPostMediaWidget(List<String>? mediaUrls) {
  final mediaUrl = mediaUrls != null && mediaUrls.isNotEmpty ? mediaUrls.first : null;
  if (mediaUrl == null) return null;
  if (isNetworkUrl(mediaUrl)) {
    return Image.network(
      mediaUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
    );
  }
  return Image.file(
    File(mediaUrl),
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) =>
        const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
  );
}
