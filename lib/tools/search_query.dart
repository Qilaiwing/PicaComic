/// Helpers for multi-keyword search queries.

/// Max length ([String.length]) for an auto-chip token / pending input.
/// Short tags like 全彩 / 蔚蓝档案 stay at or below this; pasted comic titles
/// are usually longer.
const int kSearchChipMaxChars = 24;

/// Auto-chip only short keyword tags. Pasted comic titles stay plain text —
/// neither space-splitting nor submit [commitPending] should turn them into chips.
///
/// Rule (either condition => plain text, do not chip):
/// 1. trimmed length > [kSearchChipMaxChars] (24), or
/// 2. length > 16 AND 3+ whitespace-separated tokens (English-style title).
bool isSearchTitlePlainText(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  if (t.length > kSearchChipMaxChars) return true;
  if (t.length > 16 && splitSearchTerms(t).length >= 3) return true;
  return false;
}

/// Split [s] on whitespace, keeping "quoted phrases" together.
List<String> splitSearchTerms(String s) {
  final res = <String>[];
  final buf = StringBuffer();
  var inQuote = false;
  for (final ch in s.split('')) {
    if (ch == '"') inQuote = !inQuote;
    if (!inQuote && (ch == ' ' || ch == '\t' || ch == '\n')) {
      if (buf.isNotEmpty) res.add(buf.toString());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  if (buf.isNotEmpty) res.add(buf.toString());
  return res;
}

/// Index of the last whitespace that is outside quotes, or -1.
int lastSearchBoundary(String s) {
  var inQuote = false;
  var last = -1;
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    if (ch == '"') inQuote = !inQuote;
    if (!inQuote && ch == ' ') last = i;
  }
  return last;
}

/// PicACG's keyword search is a MongoDB text search: plain space-separated
/// words are OR'ed. Quoting every term makes each one required (AND).
String picacgKeyword(String keyword) {
  final terms = splitSearchTerms(keyword);
  if (terms.length <= 1) return keyword.trim();
  return terms
      .map((t) => t.startsWith('"') || t.startsWith('-') ? t : '"$t"')
      .join(' ');
}

/// JM search: space-separated words are OR'ed; a leading `+` makes a word
/// required. Prefix every plain term with `+` so all terms must match.
String jmKeyword(String keyword) {
  final terms = splitSearchTerms(keyword);
  if (terms.length <= 1) return keyword.trim();
  return terms
      .map((t) => t.startsWith('+') || t.startsWith('-') ? t : '+$t')
      .join(' ');
}