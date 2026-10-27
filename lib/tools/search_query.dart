/// Helpers for multi-keyword search queries.

/// Max length ([String.length]) for an auto-chip token / pending input.
/// Short tags like 全彩 / 蔚蓝档案 stay at or below this; pasted comic titles
/// are usually longer.
const int kSearchChipMaxChars = 24;

final _cjkRe = RegExp(r'[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');
final _titleMarkRe = RegExp(r'[\[\]【】\(\)（）]');
final _spaceRe = RegExp(r'\s+');

/// Auto-chip only short keyword tags. Pasted comic titles stay plain text —
/// neither space-splitting nor submit [commitPending] should turn them into chips.
///
/// Rule (any condition => plain text / one keyword, do not chip):
/// 1. trimmed length > [kSearchChipMaxChars] (24), or
/// 2. length > 16 AND 3+ whitespace-separated tokens, or
/// 3. 2+ tokens AND title markers like []【】()（）.
bool isSearchTitlePlainText(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  if (t.length > kSearchChipMaxChars) return true;
  final terms = splitSearchTerms(t);
  if (t.length > 16 && terms.length >= 3) return true;
  if (terms.length >= 2 && _titleMarkRe.hasMatch(t)) return true;
  return false;
}

/// Whether pending input should be turned into chip(s).
/// Single short keyword alone stays plain text; only multi-term / combining chips.
/// Titles still blocked by [isSearchTitlePlainText].
bool shouldAutoChipPending(String pending, {required int existingChipCount}) {
  final t = pending.trim();
  if (t.isEmpty) return false;
  if (isSearchTitlePlainText(t)) return false;
  final terms = splitSearchTerms(t);
  if (existingChipCount > 0) return true; // combining with existing chips
  return terms.length >= 2; // only chip when multiple terms
}

/// Split [s] on whitespace (ASCII + ideographic), keeping "quoted phrases" together.
List<String> splitSearchTerms(String s) {
  final res = <String>[];
  final buf = StringBuffer();
  var inQuote = false;
  for (final ch in s.split('')) {
    if (ch == '"') inQuote = !inQuote;
    if (!inQuote &&
        (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\u3000')) {
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
    if (!inQuote && (ch == ' ' || ch == '\u3000')) last = i;
  }
  return last;
}

/// Turn a pasted comic title into **one** network keyword.
///
/// PicACG / JM both treat raw spaces as term separators (OR / AND). That breaks
/// pasted titles like `甜美夢境 [Starship …] [DL版]`. Spaces must not act as
/// separators on the wire:
/// - CJK titles: strip all whitespace (indexed as contiguous text).
/// - Latin titles: wrap as one `"phrase"` so spaces stay inside one term.
String titleAsSingleKeyword(String raw) {
  var t = raw.trim();
  // Drop wrapping quotes; neutralize inner quotes so we own phrasing.
  if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
    t = t.substring(1, t.length - 1);
  }
  t = t.replaceAll('"', ' ').replaceAll(_spaceRe, ' ').trim();
  if (t.isEmpty) return raw.trim();
  if (_cjkRe.hasMatch(t)) {
    return t.replaceAll(_spaceRe, '');
  }
  return '"$t"';
}

/// PicACG's keyword search is a MongoDB text search: plain space-separated
/// words are OR'ed. Quoting every term makes each one required (AND).
String picacgKeyword(String keyword) {
  final raw = keyword.trim();
  if (raw.isEmpty) return raw;
  // Pasted comic titles: one keyword — spaces must not split server-side.
  if (isSearchTitlePlainText(raw)) {
    return titleAsSingleKeyword(raw);
  }
  final terms = splitSearchTerms(raw);
  if (terms.length <= 1) return raw;
  return terms
      .map((t) => t.startsWith('"') || t.startsWith('-') ? t : '"$t"')
      .join(' ');
}

/// JM search: space-separated words are OR'ed; a leading `+` makes a word
/// required. Prefix every plain term with `+` so all terms must match.
String jmKeyword(String keyword) {
  final raw = keyword.trim();
  if (raw.isEmpty) return raw;
  // Pasted comic titles: one keyword — no per-word +AND / space OR.
  if (isSearchTitlePlainText(raw)) {
    return titleAsSingleKeyword(raw);
  }
  final terms = splitSearchTerms(raw);
  if (terms.length <= 1) return raw;
  return terms
      .map((t) => t.startsWith('+') || t.startsWith('-') ? t : '+$t')
      .join(' ');
}
