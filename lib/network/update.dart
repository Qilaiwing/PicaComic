import 'package:dio/dio.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/def.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/app_dio.dart';

String? _updateInfo;

const _githubApiLatest =
    "https://api.github.com/repos/Qilaiwing/PicaComic_miuix/releases/latest";
const _githubHtmlLatest =
    "https://github.com/Qilaiwing/PicaComic_miuix/releases/latest";
const _githubAtom =
    "https://github.com/Qilaiwing/PicaComic_miuix/releases.atom";

Dio _updateDio({bool followRedirects = true}) {
  return logDio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: {
        "User-Agent": "PicaComic-MIUIX/$appVersion",
        "Accept":
            "application/vnd.github+json, application/atom+xml, text/html, */*",
        "X-GitHub-Api-Version": "2022-11-28",
      },
      followRedirects: followRedirects,
      maxRedirects: followRedirects ? 5 : 0,
      validateStatus: (code) =>
          code != null &&
          ((code >= 200 && code < 300) || code == 301 || code == 302),
      responseType: ResponseType.plain,
    ),
  );
}

({String base, int miuix}) _parseAppTag(String raw) {
  var s = raw.trim();
  if (s.startsWith("v") || s.startsWith("V")) s = s.substring(1);
  final miuixMatch =
      RegExp(r'-miuix(\d+)$', caseSensitive: false).firstMatch(s);
  var miuix = 0;
  if (miuixMatch != null) {
    miuix = int.tryParse(miuixMatch.group(1)!) ?? 0;
    s = s.substring(0, miuixMatch.start);
  }
  s = s.split('-').first;
  return (base: s, miuix: miuix);
}

String _stripV(String tag) =>
    tag.startsWith("v") || tag.startsWith("V") ? tag.substring(1) : tag;

Future<String> getLatestVersion() async {
  final errors = <String>[];

  try {
    final dio = _updateDio();
    final res = await dio.get(
      _githubApiLatest,
      options: Options(
        responseType: ResponseType.json,
        headers: {"Accept": "application/vnd.github+json"},
      ),
    );
    if (res.statusCode == 200) {
      final data = res.data;
      if (data is Map) {
        _updateInfo = data["body"]?.toString();
        final tag = data["tag_name"]?.toString();
        if (tag != null && tag.isNotEmpty) {
          LogManager.addLog(
              LogLevel.info, "Update", "latest tag=$tag (api)");
          return _stripV(tag);
        }
      }
    }
    errors.add("api status=${res.statusCode}");
  } catch (e) {
    errors.add("api: $e");
    LogManager.addLog(LogLevel.warning, "Update", "api failed: $e");
  }

  try {
    final dio = _updateDio(followRedirects: false);
    final res = await dio.get(_githubHtmlLatest);
    final loc = res.headers.value("location") ?? "";
    final m = RegExp(r'/releases/tag/([^/?#]+)').firstMatch(loc);
    if (m != null) {
      final tag = Uri.decodeComponent(m.group(1)!);
      LogManager.addLog(
          LogLevel.info, "Update", "latest tag=$tag (html redirect)");
      if (_updateInfo == null) {
        try {
          await _loadUpdateInfoFromAtom();
        } catch (_) {}
      }
      return _stripV(tag);
    }
    errors.add("html loc=$loc status=${res.statusCode}");
  } catch (e) {
    errors.add("html: $e");
    LogManager.addLog(
        LogLevel.warning, "Update", "html redirect failed: $e");
  }

  try {
    final tag = await _latestTagFromAtom();
    if (tag != null) {
      LogManager.addLog(
          LogLevel.info, "Update", "latest tag=$tag (atom)");
      return _stripV(tag);
    }
    errors.add("atom: no tag");
  } catch (e) {
    errors.add("atom: $e");
    LogManager.addLog(LogLevel.warning, "Update", "atom failed: $e");
  }

  final msg = "getLatestVersion failed: ${errors.join(' | ')}";
  LogManager.addLog(LogLevel.error, "Update", msg);
  throw StateError(msg);
}

Future<void> _loadUpdateInfoFromAtom() async {
  final dio = _updateDio();
  final res = await dio.get(_githubAtom);
  final body = res.data?.toString() ?? "";
  final entry = RegExp(r'<entry>([\s\S]*?)</entry>').firstMatch(body);
  if (entry == null) return;
  final content = RegExp(r'<content[^>]*>([\s\S]*?)</content>')
      .firstMatch(entry.group(1)!);
  if (content != null) {
    var text = content
        .group(1)!
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isNotEmpty) _updateInfo = text;
  }
}

Future<String?> _latestTagFromAtom() async {
  final dio = _updateDio();
  final res = await dio.get(_githubAtom);
  final body = res.data?.toString() ?? "";
  final entry = RegExp(r'<entry>([\s\S]*?)</entry>').firstMatch(body);
  if (entry == null) return null;
  final block = entry.group(1)!;
  final link = RegExp(
          r'href="https://github\.com/[^"]+/releases/tag/([^"]+)"')
      .firstMatch(block);
  if (link != null) {
    await _loadUpdateInfoFromAtom();
    return Uri.decodeComponent(link.group(1)!);
  }
  final titles = RegExp(r'<title>([^<]*)</title>')
      .allMatches(block)
      .map((m) => m.group(1)!.trim())
      .toList();
  for (final t in titles) {
    final vm = RegExp(r'v?\d+\.\d+\.\d+(?:-miuix\d+)?',
            caseSensitive: false)
        .firstMatch(t);
    if (vm != null) {
      await _loadUpdateInfoFromAtom();
      return vm.group(0)!;
    }
  }
  return null;
}

Future<bool?> checkUpdate() async {
  try {
    final local = appVersion;
    final remote = await getLatestVersion();
    LogManager.addLog(
        LogLevel.info, "Update", "compare remote=$remote local=$local");
    return compareSemVer(remote, local);
  } catch (e) {
    LogManager.addLog(LogLevel.error, "Update", "checkUpdate: $e");
    return null;
  }
}

bool compareSemVer(String ver1, String ver2) {
  final a = _parseAppTag(ver1);
  final b = _parseAppTag(ver2);
  final v1 = a.base.split('.');
  final v2 = b.base.split('.');
  for (var i = 0; i < 3; i++) {
    final num1 = int.tryParse(v1.elementAtOrNull(i) ?? '0') ?? 0;
    final num2 = int.tryParse(v2.elementAtOrNull(i) ?? '0') ?? 0;
    if (num1 > num2) return true;
    if (num1 < num2) return false;
  }
  if (a.miuix != b.miuix) return a.miuix > b.miuix;
  return false;
}

Future<String?> getUpdatesInfo() async {
  if (_updateInfo == null) {
    try {
      await _loadUpdateInfoFromAtom();
    } catch (_) {}
  }
  if (_updateInfo == null) return "New release available";
  final text = _updateInfo!.replaceAll('\r\n', '\n');
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.length > 12) {
    return "${lines.take(12).join('\n')}\n...";
  }
  return text;
}

Future<String> getDownloadUrl() async {
  return "https://github.com/Qilaiwing/PicaComic_miuix/releases/latest";
}
