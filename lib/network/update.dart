import 'package:dio/dio.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/def.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/app_dio.dart';

String? _updateInfo;

const _githubLatest =
    "https://api.github.com/repos/Qilaiwing/PicaComic_miuix/releases/latest";

Dio _updateDio() {
  final dio = logDio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        "User-Agent": "PicaComic-MIUIX/$appVersion",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
      },
      responseType: ResponseType.json,
      validateStatus: (code) => code != null && code >= 200 && code < 300,
    ),
  );
  return dio;
}

/// Normalize tags like `v4.2.11-miuix1` → comparable parts.
({String base, int miuix}) _parseAppTag(String raw) {
  var s = raw.trim();
  if (s.startsWith("v") || s.startsWith("V")) s = s.substring(1);
  final miuixMatch = RegExp(r'-miuix(\d+)$', caseSensitive: false).firstMatch(s);
  var miuix = 0;
  if (miuixMatch != null) {
    miuix = int.tryParse(miuixMatch.group(1)!) ?? 0;
    s = s.substring(0, miuixMatch.start);
  }
  // Drop other pre-release suffixes for base compare.
  s = s.split('-').first;
  return (base: s, miuix: miuix);
}

Future<String> getLatestVersion() async {
  final dio = _updateDio();
  try {
    final res = await dio.get(_githubLatest);
    final data = res.data;
    if (data is! Map) {
      throw StateError("Unexpected GitHub response type: ${data.runtimeType}");
    }
    _updateInfo = data["body"]?.toString();
    final tag = data["tag_name"]?.toString();
    if (tag == null || tag.isEmpty) {
      throw StateError("GitHub release missing tag_name");
    }
    LogManager.addLog(LogLevel.info, "Update", "latest tag=$tag");
    return tag.startsWith("v") || tag.startsWith("V") ? tag.substring(1) : tag;
  } catch (e, st) {
    LogManager.addLog(LogLevel.error, "Update", "getLatestVersion failed: $e\n$st");
    rethrow;
  }
}

Future<bool?> checkUpdate() async {
  try {
    final local = appVersion;
    final remote = await getLatestVersion();
    return compareSemVer(remote, local);
  } catch (e) {
    LogManager.addLog(LogLevel.error, "Update", "checkUpdate: $e");
    return null;
  }
}

/// True when [ver1] (remote) is newer than [ver2] (local).
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
  // Same base (e.g. 4.2.11): compare -miuixN build.
  if (a.miuix != b.miuix) return a.miuix > b.miuix;
  return false;
}

Future<String?> getUpdatesInfo() async {
  if (_updateInfo == null) return null;
  final text = _updateInfo!.replaceAll('\r\n', '\n');
  final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
  if (lines.length > 12) {
    return '${lines.take(12).join('\n')}\n...';
  }
  return text;
}

Future<String> getDownloadUrl() async {
  return "https://github.com/Qilaiwing/PicaComic_miuix/releases/latest";
}
