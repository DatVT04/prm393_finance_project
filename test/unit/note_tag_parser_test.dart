import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_finance_project/src/core/services/note_tag_parser.dart';

void main() {
  group('NoteTagParser.extractTags', () {
    test('returns empty for empty string or text without hashtags', () {
      expect(NoteTagParser.extractTags(''), isEmpty);
      expect(NoteTagParser.extractTags('Mua sắm bình thường'), isEmpty);
    });

    test('extracts a single hashtag', () {
      expect(NoteTagParser.extractTags('Ăn phở #food'), ['food']);
    });

    test('extracts multiple hashtags including Vietnamese characters', () {
      expect(
        NoteTagParser.extractTags('Chi tiêu #ănuống #food'),
        ['ănuống', 'food'],
      );
    });

    test('ignores # not followed by a word character', () {
      expect(NoteTagParser.extractTags('Giá: 50# '), isEmpty);
    });

    test('does not confuse @mentions with #tags', () {
      expect(NoteTagParser.extractTags('@alice #food'), ['food']);
    });
  });

  group('NoteTagParser.extractMentions', () {
    test('returns empty for empty string or text without mentions', () {
      expect(NoteTagParser.extractMentions(''), isEmpty);
      expect(NoteTagParser.extractMentions('Mua sắm bình thường'), isEmpty);
    });

    test('extracts a single @mention', () {
      expect(NoteTagParser.extractMentions('Gửi tiền @friend'), ['friend']);
    });

    test('extracts multiple @mentions including underscore', () {
      expect(
        NoteTagParser.extractMentions('Chia với @alice và @nguyen_van_an'),
        ['alice', 'nguyen_van_an'],
      );
    });

    test('text with both tags and mentions — each method returns correct list', () {
      const text = 'Trả tiền cơm #food @alice @bob';
      expect(NoteTagParser.extractTags(text), ['food']);
      expect(NoteTagParser.extractMentions(text), ['alice', 'bob']);
    });
  });
}
