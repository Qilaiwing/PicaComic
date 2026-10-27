/// Helpers for multi-keyword search queries.
///
/// Short space-separated tags (e.g. 全彩 蔚蓝档案) become AND queries.
/// Title-like input (long / with ()[]【】 / many tokens) is sent RAW —
/// no phrase quotes, no space stripping (upstream titles stay as pasted).

const int kSearchTitleMaxChars = 24;

// Non-raw strings so \uXXXX escapes become real code points for RegExp.
final _cjkRe =
    RegExp('[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');
final _titleMarkRe = RegExp('[\[\]【】()（）]');
final _openMarkRe = RegExp('[(\[【（]');

/// True when [s] contains title brackets/parens.
bool hasSearchTitleMarks(String s) => _titleMarkRe.hasMatch(s);

/// Split [s] on whitespace (ASCII + ideographic), keeping "quoted phrases".
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

/// True when [s] looks like a comic title — send raw, do not AND-split.
///
/// Any condition => title / plain:
/// 1. trimmed length > [kSearchTitleMaxChars] (24), or
/// 2. has whitespace AND contains ()[]【】, or
/// 3. 2+ tokens AND title markers, or
/// 4. length > 12 AND 2+ tokens AND CJK with opening ( [ 【 （, or
/// 5. length > 16 AND 3+ whitespace-separated tokens.
///
/// Pure short multi-tags without marks (e.g. 全彩 蔚蓝档案) stay multi-term.
bool isSearchTitlePlainText(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  if (t.length > kSearchTitleMaxChars) return true;
  final terms = splitSearchTerms(t);
  final hasSpace = terms.length >= 2 ||
      s.contains(' ') ||
      s.contains('\t') ||
      s.contains('\u3000');
  if (hasSpace && hasSearchTitleMarks(t)) return true;
  if (terms.length >= 2 && hasSearchTitleMarks(t)) return true;
  if (terms.length >= 2 &&
      t.length > 12 &&
      _cjkRe.hasMatch(t) &&
      _openMarkRe.hasMatch(t)) {
    return true;
  }
  if (t.length > 16 && terms.length >= 3) return true;
  return false;
}

/// PicACG: space-separated words are OR'ed; quoting each term makes AND.
/// Title-like input is returned unchanged (raw).
String picacgKeyword(String keyword) {
  final raw = keyword.trim();
  if (raw.isEmpty) return raw;
  if (isSearchTitlePlainText(raw)) return raw;
  final terms = splitSearchTerms(raw);
  if (terms.length <= 1) return raw;
  return terms
      .map((t) => t.startsWith('"') || t.startsWith('-') ? t : '"$t"')
      .join(' ');
}

/// JM: spaces OR; leading `+` makes a term required (AND).
/// Title-like input is returned unchanged (raw).
String jmKeyword(String keyword) {
  final raw = keyword.trim();
  if (raw.isEmpty) return raw;
  if (isSearchTitlePlainText(raw)) return raw;
  final terms = splitSearchTerms(raw);
  if (terms.length <= 1) return raw;
  return terms
      .map((t) => t.startsWith('+') || t.startsWith('-') ? t : '+$t')
      .join(' ');
}

/// Encode a JM `search_query` value for the URL.
///
/// [Uri.encodeComponent] leaves `()!~*'` unencoded; bare `()` break JM
/// (non-JSON body). Encode those; spaces → `+`.
String jmEncodeSearchQuery(String keyword) {
  return Uri.encodeComponent(keyword)
      .replaceAll('(', '%28')
      .replaceAll(')', '%29')
      .replaceAll('!', '%21')
      .replaceAll('*', '%2A')
      .replaceAll("'", '%27')
      .replaceAll('%20', '+');
}
