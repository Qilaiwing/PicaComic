/// Helpers for multi-keyword search queries.

/// Max length ([String.length]) for an auto-chip token / pending input.
/// Short tags like 全彩 / 蔚蓝档案 stay at or below this; pasted comic titles
/// are usually longer.
const int kSearchChipMaxChars = 24;

// Non-raw strings so \uXXXX escapes become real code points for RegExp.
final _cjkRe =
    RegExp('[\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff]');
final _titleMarkRe = RegExp('[\[\]【】()（）]');
final _spaceRe = RegExp(r'\s+');
final _openMarkRe = RegExp('[(\[【（]');

/// True when [s] contains title brackets/parens — never treat as multi-tag chips.
bool hasSearchTitleMarks(String s) => _titleMarkRe.hasMatch(s);

/// Auto-chip only short keyword tags. Pasted comic titles stay plain text —
/// neither space-splitting nor submit [commitPending] should turn them into chips.
///
/// Rule (any condition => plain text / one keyword, do not chip):
/// 1. trimmed length > [kSearchChipMaxChars] (24), or
/// 2. has whitespace AND contains ()[]【】 (any length title fragment), or
/// 3. 2+ tokens AND title markers, or
/// 4. length > 12 AND 2+ tokens AND CJK with an opening ( [ 【 （, or
/// 5. length > 16 AND 3+ whitespace-separated tokens.
///
/// Pure short multi-tags without marks (e.g. 全彩 蔚蓝档案) stay multi-term.
bool isSearchTitlePlainText(String s) {
  final t = s.trim();
  if (t.isEmpty) return false;
  if (t.length > kSearchChipMaxChars) return true;
  final terms = splitSearchTerms(t);
  final hasSpace = terms.length >= 2 ||
      s.contains(' ') ||
      s.contains('\t') ||
      s.contains('\u3000');
  // Spaced + ()[]【】 => title fragment, e.g. 粉幼檔案5 (ブルーアーカイブ)
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

/// Whether pending input should be turned into chip(s).
/// Titles / anything with ()[]【】 never auto-chip (editing pasted titles).
bool shouldAutoChipPending(String pending, {required int existingChipCount}) {
  final t = pending.trim();
  if (t.isEmpty) return false;
  if (isSearchTitlePlainText(t)) return false;
  if (hasSearchTitleMarks(t)) return false;
  final terms = splitSearchTerms(t);
  if (existingChipCount > 0) return true;
  return terms.length >= 2;
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
/// Keep spaces (titles are indexed with spaces). Send RAW — do NOT wrap in
/// quotes (quoted phrases return 0 hits on PicACG/JM). Spaces stay in the
/// string; callers skip AND/OR multi-term rewriting for title-like input.
String titleAsSingleKeyword(String raw) {
  var t = raw.trim();
  if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
    t = t.substring(1, t.length - 1);
  }
  // Drop inner quotes; collapse whitespace runs — keep spaces, no phrase quotes.
  t = t.replaceAll('"', ' ').replaceAll(_spaceRe, ' ').trim();
  if (t.isEmpty) return raw.trim();
  return t;
}

String picacgKeyword(String keyword) {
  final raw = keyword.trim();
  if (raw.isEmpty) return raw;
  if (isSearchTitlePlainText(raw) ||
      (splitSearchTerms(raw).length >= 2 && hasSearchTitleMarks(raw))) {
    return titleAsSingleKeyword(raw);
  }
  final terms = splitSearchTerms(raw);
  if (terms.length <= 1) return raw;
  return terms
      .map((t) => t.startsWith('"') || t.startsWith('-') ? t : '"$t"')
      .join(' ');
}

/// JM: spaces OR; leading + required.
String jmKeyword(String keyword) {
  final raw = keyword.trim();
  if (raw.isEmpty) return raw;
  if (isSearchTitlePlainText(raw) ||
      (splitSearchTerms(raw).length >= 2 && hasSearchTitleMarks(raw))) {
    return titleAsSingleKeyword(raw);
  }
  final terms = splitSearchTerms(raw);
  if (terms.length <= 1) return raw;
  return terms
      .map((t) => t.startsWith('+') || t.startsWith('-') ? t : '+$t')
      .join(' ');
}

/// Encode a JM `search_query` value for the URL.
///
/// [Uri.encodeComponent] leaves `()!~*'` unencoded. Bare parentheses in
/// titles like `(FF47) [骨頭蹦 (骨頭)] …` produce broken JM responses
/// (non-JSON body → FormatException). Encode those too; spaces → `+`.
String jmEncodeSearchQuery(String keyword) {
  return Uri.encodeComponent(keyword)
      .replaceAll('(', '%28')
      .replaceAll(')', '%29')
      .replaceAll('!', '%21')
      .replaceAll('*', '%2A')
      .replaceAll("'", '%27')
      .replaceAll('%20', '+');
}
