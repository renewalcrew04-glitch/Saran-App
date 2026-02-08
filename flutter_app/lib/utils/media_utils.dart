import 'dart:io';
import 'package:flutter/material.dart';

/// URLs that failed to load (404 etc.) - show placeholder immediately to avoid repeated exceptions.
/// Pre-populate with known missing files so we never request them.
final Set<String> _failedImageUrls = {
  'http://13.233.133.213:3000/uploads/1770150285426-432750637.jpg',
};

/// Shows full image with correct aspect ratio (portrait or landscape). No cropping.
class FullAspectNetworkImage extends StatefulWidget {
  final String url;
  final double? maxHeight;

  const FullAspectNetworkImage({
    super.key,
    required this.url,
    this.maxHeight,
  });

  @override
  State<FullAspectNetworkImage> createState() => _FullAspectNetworkImageState();
}

class _FullAspectNetworkImageState extends State<FullAspectNetworkImage> {
  double? _aspectRatio;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (_failedImageUrls.contains(widget.url)) {
      _failed = true;
      return;
    }
    _resolveDimensions();
  }

  @override
  void didUpdateWidget(FullAspectNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _failed = _failedImageUrls.contains(widget.url);
      _aspectRatio = null;
      if (!_failed) _resolveDimensions();
    }
  }

  void _resolveDimensions() {
    final provider = NetworkImage(widget.url);
    final stream = provider.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener(
      (ImageInfo info, bool synchronousCall) {
        if (!mounted) return;
        final image = info.image;
        final w = image.width.toDouble();
        final h = image.height.toDouble();
        if (w > 0 && h > 0) {
          setState(() => _aspectRatio = w / h);
        }
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        if (mounted) {
          _failedImageUrls.add(widget.url);
          setState(() => _failed = true);
        }
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _failedImageUrls.contains(widget.url)) {
      return Container(
        width: double.infinity,
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
      );
    }
    final ratio = _aspectRatio;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxH = widget.maxHeight ?? 600;
        final height = ratio != null
            ? (width / ratio).clamp(0.0, maxH)
            : 200.0; // placeholder until dimensions load
        return SizedBox(
          width: width,
          height: height,
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            width: width,
            height: height,
            errorBuilder: (_, __, ___) {
              _failedImageUrls.add(widget.url);
              return Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
              );
            },
          ),
        );
      },
    );
  }
}

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
