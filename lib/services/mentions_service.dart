class MentionsService {
  /// Matches @username from text
  List<String> extractMentions(String text) {
    final regex = RegExp(r'@([a-zA-Z0-9_]+)');
    return regex.allMatches(text).map((m) => m.group(1)!).toSet().toList();
  }

  /// FUTURE: resolve usernames -> userIds from backend
  Future<List<String>> resolveMentionsToUserIds(List<String> usernames) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return usernames.map((u) => "mock_uid_$u").toList();
  }

  /// FUTURE: backend notification
  Future<void> notifyMentionedUsers({
    required String postId,
    required List<String> mentionedUserIds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
