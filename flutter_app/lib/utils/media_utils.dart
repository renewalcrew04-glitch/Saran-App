import 'dart:io';
import 'package:flutter/material.dart';

/// URLs that failed to load (404 etc.) - show placeholder and avoid repeated requests/exceptions.
final Set<String> _failedImageUrls = {};

/// Call from error handlers to avoid retrying this URL. Also use to pre-add known 404s.
void markImageUrlFailed(String url) {
  if (url.isNotEmpty) _failedImageUrls.add(url);
}

/// Returns true if this URL previously failed (404 etc.) so callers can show placeholder without loading.
bool isKnownFailedImageUrl(String url) => url.isNotEmpty && _failedImageUrls.contains(url);

bool _knownFailedUrlsInitialized = false;
void _ensureKnownFailedUrls() {
  if (_knownFailedUrlsInitialized) return;
  _knownFailedUrlsInitialized = true;
  // Pre-add URLs that are known to 404 so we never request them (stops repeated exceptions).
  const known404 = [
    'http://13.233.133.213:3000/uploads/1770583615597-944127833.jpg',
  ];
  for (final u in known404) {
    _failedImageUrls.add(u);
  }
}

/// Shows full image with correct aspect ratio (portrait or landscape). No cropping.
class FullAspectNetworkImage extends StatefulWidget {
  final String url;
  final double? maxHeight;
  /// Minimum height to prevent thin-strip display when aspect ratio is wrong or image is very wide.
  final double? minHeight;

  const FullAspectNetworkImage({
    super.key,
    required this.url,
    this.maxHeight,
    this.minHeight,
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
    _ensureKnownFailedUrls();
    if (widget.url.isEmpty ||
        (!widget.url.startsWith('http://') && !widget.url.startsWith('https://')) ||
        _failedImageUrls.contains(widget.url)) {
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
    final urlInvalid = widget.url.isEmpty ||
        (!widget.url.startsWith('http://') && !widget.url.startsWith('https://'));
    if (urlInvalid || _failed || _failedImageUrls.contains(widget.url)) {
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
        final width = constraints.maxWidth.clamp(1.0, double.infinity);
        final maxH = widget.maxHeight ?? 600;
        final minH = widget.minHeight ?? 150.0;
        final height = ratio != null
            ? (width / ratio).clamp(minH, maxH)
            : 200.0; // placeholder until dimensions load
        return SizedBox(
          width: width,
          height: height,
          child: Image.network(
            widget.url,
            fit: BoxFit.contain,
            width: width,
            height: height,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.image_outlined, color: Colors.black45)),
              );
            },
            errorBuilder: (_, __, ___) {
              markImageUrlFailed(widget.url);
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

/// Auto-detects portrait (h>w) vs landscape and uses 4:5 or 1.91:1.
/// Used when backend doesn't return mediaDisplay.
class AutoAspectNetworkImage extends StatefulWidget {
  final String url;
  static const double portraitRatio = 4 / 5;
  static const double landscapeRatio = 1.91;

  const AutoAspectNetworkImage({super.key, required this.url});

  @override
  State<AutoAspectNetworkImage> createState() => _AutoAspectNetworkImageState();
}

class _AutoAspectNetworkImageState extends State<AutoAspectNetworkImage> {
  double? _aspectRatio;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ensureKnownFailedUrls();
    if (widget.url.isEmpty ||
        (!widget.url.startsWith('http://') && !widget.url.startsWith('https://')) ||
        _failedImageUrls.contains(widget.url)) {
      _failed = true;
      return;
    }
    _resolveDimensions();
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
    final isPortrait = ratio != null && ratio < 1.0;
    final aspectRatio = isPortrait ? AutoAspectNetworkImage.portraitRatio : AutoAspectNetworkImage.landscapeRatio;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Image.network(
        widget.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.image_outlined, color: Colors.black45)),
          );
        },
        errorBuilder: (_, __, ___) {
          markImageUrlFailed(widget.url);
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.broken_image, color: Colors.black45)),
          );
        },
      ),
    );
  }
}

bool isNetworkUrl(String url) {
  return url.startsWith("http://") || url.startsWith("https://");
}

Widget _avatarPlaceholder({required double size, Color? backgroundColor}) {
  return CircleAvatar(
    radius: size / 2,
    backgroundColor: backgroundColor ?? Colors.grey[300],
    child: Icon(Icons.person, color: Colors.black45, size: size * 0.5),
  );
}

/// Avatar (circle) that never shows 404: shows placeholder if URL failed or on error.
Widget safeAvatarNetworkImage({
  required String? url,
  double size = 40,
  Color? backgroundColor,
}) {
  _ensureKnownFailedUrls();
  if (url == null || url.isEmpty || _failedImageUrls.contains(url) ||
      (!url.startsWith('http://') && !url.startsWith('https://'))) {
    return _avatarPlaceholder(size: size, backgroundColor: backgroundColor);
  }
  return ClipOval(
    child: SizedBox(
      width: size,
      height: size,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: size,
        height: size,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return _avatarPlaceholder(size: size, backgroundColor: backgroundColor);
        },
        errorBuilder: (_, __, ___) {
          markImageUrlFailed(url);
          return _avatarPlaceholder(size: size, backgroundColor: backgroundColor);
        },
      ),
    ),
  );
}

/// Placeholder shown while loading or when image fails (404 etc.). Never shows HTTP error to user.
Widget _imagePlaceholder({double? width, double? height, IconData icon = Icons.image_outlined}) {
  return Container(
    width: width,
    height: height ?? 200,
    color: Colors.grey[300],
    child: Center(child: Icon(icon, color: Colors.black45)),
  );
}

/// Network image that never shows 404/errors to user: uses failed-URL cache, loadingBuilder, errorBuilder.
Widget safeNetworkImage({
  required String url,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder,
  IconData placeholderIcon = Icons.broken_image,
}) {
  _ensureKnownFailedUrls();
  if (url.isEmpty || (!url.startsWith('http://') && !url.startsWith('https://'))) {
    return _imagePlaceholder(width: width, height: height ?? 200, icon: placeholderIcon);
  }
  if (_failedImageUrls.contains(url)) {
    return _imagePlaceholder(width: width, height: height ?? 200, icon: placeholderIcon);
  }
  return Image.network(
    url,
    fit: fit,
    width: width,
    height: height,
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return _imagePlaceholder(width: width, height: height ?? 200, icon: Icons.image_outlined);
    },
    errorBuilder: (context, error, stackTrace) {
      markImageUrlFailed(url);
      if (errorBuilder != null) {
        return errorBuilder(context, error, stackTrace);
      }
      return _imagePlaceholder(width: width, height: height ?? 200, icon: placeholderIcon);
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
