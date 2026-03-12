/// Extract #tags and @mentions from note text.
class NoteTagParser {
  static final RegExp _tagRegex = RegExp(r'#(\w+)');
  static final RegExp _mentionRegex = RegExp(r'@(\w+)');

  static List<String> extractTags(String note) {
    if (note.isEmpty) return [];
    return _tagRegex.allMatches(note).map((m) => m.group(1)!).toList();
  }

  static List<String> extractMentions(String note) {
    if (note.isEmpty) return [];
    return _mentionRegex.allMatches(note).map((m) => m.group(1)!).toList();
  }
}
