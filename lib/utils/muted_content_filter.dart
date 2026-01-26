import '../models/post_model.dart';

class MutedContentFilter {
  static bool shouldHide(
    Post post, {
    required List<String> mutedWords,
    required List<String> mutedHashtags,
  }) {
    final text = post.text.toLowerCase();

    for (final word in mutedWords) {
      if (text.contains(word.toLowerCase())) {
        return true;
      }
    }

    for (final tag in mutedHashtags) {
      if (post.hashtags
          .map((h) => h.toLowerCase())
          .contains(tag.toLowerCase())) {
        return true;
      }
    }

    return false;
  }
}
