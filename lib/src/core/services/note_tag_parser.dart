class NoteTagParser {
  /// Extracts hashtags from a given text.
  /// Example: "Eating #food" returns ["food"]
  static List<String> extractTags(String text) {
    if (text.isEmpty) return [];
    final RegExp tagRegex = RegExp(r'#([\p{L}\p{N}_]+)', unicode: true);
    final matches = tagRegex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }

  /// Extracts mentions from a given text.
  /// Example: "Hello @alice" returns ["alice"]
  static List<String> extractMentions(String text) {
    if (text.isEmpty) return [];
    final RegExp mentionRegex = RegExp(r'@([\p{L}\p{N}_]+)', unicode: true);
    final matches = mentionRegex.allMatches(text);
    return matches.map((m) => m.group(1)!).toList();
  }
}