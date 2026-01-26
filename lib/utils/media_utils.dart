bool isNetworkUrl(String url) {
  return url.startsWith("http://") || url.startsWith("https://");
}
final mediaUrl = post.media != null && post.media!.isNotEmpty ? post.media!.first : null;

if (mediaUrl != null) {
  if (isNetworkUrl(mediaUrl)) {
    Image.network(mediaUrl, fit: BoxFit.cover);
  } else {
    Image.file(File(mediaUrl), fit: BoxFit.cover);
  }
}
