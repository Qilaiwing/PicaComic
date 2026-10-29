import 'dart:convert';
import 'dart:io';

import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/history.dart';

/// 阅读统计：仅在阅读器内计时与计页，按天 / 按漫画轻量存为 JSON。
class ReadingStats {
  ReadingStats._();
  static final ReadingStats instance = ReadingStats._();

  static const _fileName = 'reading_stats.json';

  /// yyyy-MM-dd -> [ms, pages]
  final Map<String, List<int>> days = {};

  /// target -> {title, cover, type, ms, pages, opens}
  final Map<String, Map<String, dynamic>> comics = {};

  bool _loaded = false;
  DateTime? _sessionStart;
  String? _target;
  int _lastFlush = 0;

  File get _file => File('${App.dataPath}/$_fileName');

  static String dayKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  void _load() {
    if (_loaded) return;
    _loaded = true;
    try {
      if (!_file.existsSync()) return;
      final json = jsonDecode(_file.readAsStringSync()) as Map<String, dynamic>;
      (json['days'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        final l = (v as List).cast<num>();
        days[k] = [l[0].toInt(), l.length > 1 ? l[1].toInt() : 0];
      });
      (json['comics'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        comics[k] = Map<String, dynamic>.from(v as Map);
      });
      // 回填：旧记录没有保存源名称时，从已安装（含停用）的源解析
      var changed = false;
      for (final c in comics.values) {
        if (c['sourceName'] == null && c['type'] is int) {
          final n = HistoryType(c['type'] as int).displayNameOrNull;
          if (n != null) {
            c['sourceName'] = n;
            changed = true;
          }
        }
      }
      if (changed) _save();
    } catch (_) {}
  }

  void _save() {
    try {
      _file.writeAsStringSync(jsonEncode({'days': days, 'comics': comics}),
          flush: true);
    } catch (_) {}
  }

  Map<String, dynamic> _comic(String target) =>
      comics.putIfAbsent(target, () => {'ms': 0, 'pages': 0, 'opens': 0});

  void startSession(
      {required String target,
      required String title,
      required String cover,
      required int type}) {
    _load();
    endSession();
    _target = target;
    _sessionStart = DateTime.now();
    final c = _comic(target);
    c['title'] = title;
    c['cover'] = cover;
    c['type'] = type;
    final sourceName = HistoryType(type).displayNameOrNull;
    if (sourceName != null) c['sourceName'] = sourceName;
    c['opens'] = (c['opens'] as int? ?? 0) + 1;
    c['last'] = DateTime.now().millisecondsSinceEpoch;
    _save();
  }

  void pageTurned() {
    if (_target == null) return;
    final d = days.putIfAbsent(dayKey(DateTime.now()), () => [0, 0]);
    d[1]++;
    final c = _comic(_target!);
    c['pages'] = (c['pages'] as int? ?? 0) + 1;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFlush > 15000) {
      _lastFlush = now;
      _flushTime(stop: false);
    }
  }

  void _flushTime({required bool stop}) {
    final start = _sessionStart;
    if (start != null && _target != null) {
      final now = DateTime.now();
      // 单次会话超过 3 小时视为挂机，截断。
      var ms = now.difference(start).inMilliseconds.clamp(0, 3 * 3600 * 1000);
      final d = days.putIfAbsent(dayKey(now), () => [0, 0]);
      d[0] += ms;
      final c = _comic(_target!);
      c['ms'] = (c['ms'] as int? ?? 0) + ms;
      c['last'] = now.millisecondsSinceEpoch;
      _sessionStart = stop ? null : now;
    }
    if (stop) _target = null;
    _save();
  }

  void endSession() {
    if (_target == null) return;
    _flushTime(stop: true);
  }

  void pause() {
    if (_sessionStart == null || _target == null) return;
    final t = _target;
    _flushTime(stop: false);
    _sessionStart = null;
    _target = t;
  }

  void resume() {
    if (_target != null && _sessionStart == null) {
      _sessionStart = DateTime.now();
    }
  }

  List<int> get today => _get(dayKey(DateTime.now()));

  List<int> _get(String k) {
    _load();
    return days[k] ?? const [0, 0];
  }

  /// 最近 [n] 天，旧 -> 新
  List<(DateTime, int, int)> lastDays(int n) {
    _load();
    final now = DateTime.now();
    return List.generate(n, (i) {
      final d = DateTime(now.year, now.month, now.day - (n - 1 - i));
      final v = _get(dayKey(d));
      return (d, v[0], v[1]);
    });
  }

  /// 所有有记录的月份（旧 -> 新），值为 (月首日, ms, pages)；中间空月补 0。
  List<(DateTime, int, int)> months() {
    _load();
    final agg = <String, List<int>>{};
    for (final e in days.entries) {
      final k = e.key.substring(0, 7);
      final v = agg.putIfAbsent(k, () => [0, 0]);
      v[0] += e.value[0];
      v[1] += e.value[1];
    }
    final now = DateTime.now();
    var start = DateTime(now.year, now.month);
    if (agg.isNotEmpty) {
      final first = (agg.keys.toList()..sort()).first.split('-');
      start = DateTime(int.parse(first[0]), int.parse(first[1]));
    }
    final res = <(DateTime, int, int)>[];
    for (var m = start;
        !m.isAfter(DateTime(now.year, now.month));
        m = DateTime(m.year, m.month + 1)) {
      final k = '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}';
      final v = agg[k] ?? const [0, 0];
      res.add((m, v[0], v[1]));
    }
    return res;
  }

  int get totalMs {
    _load();
    return days.values.fold(0, (a, b) => a + b[0]);
  }

  int get totalPages {
    _load();
    return days.values.fold(0, (a, b) => a + b[1]);
  }

  int get activeDays {
    _load();
    return days.values.where((e) => e[0] > 0 || e[1] > 0).length;
  }

  /// 显示用源名称：优先实时解析（含停用源），其次用记录中保存的名称
  static String sourceNameOf(Map<String, dynamic> record) {
    final type = record['type'] as int? ?? 0;
    return HistoryType(type).displayNameOrNull ??
        record['sourceName']?.toString() ??
        "Unknown";
  }

  List<MapEntry<String, Map<String, dynamic>>> topComics(int n) {
    _load();
    final list = comics.entries.toList()
      ..sort((a, b) => ((b.value['ms'] as int? ?? 0))
          .compareTo(a.value['ms'] as int? ?? 0));
    return list.where((e) => (e.value['ms'] as int? ?? 0) > 0).take(n).toList();
  }

  /// 合并从备份恢复的统计文件 (按天 / 按漫画取较大值), 用于导入与 WebDAV 同步。
  void mergeFromFile(File f) {
    _load();
    try {
      if (!f.existsSync()) return;
      final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      (json['days'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        final l = (v as List).cast<num>();
        final ms = l[0].toInt(), pages = l.length > 1 ? l[1].toInt() : 0;
        final old = days[k];
        days[k] = old == null
            ? [ms, pages]
            : [ms > old[0] ? ms : old[0], pages > old[1] ? pages : old[1]];
      });
      (json['comics'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
        final incoming = Map<String, dynamic>.from(v as Map);
        final old = comics[k];
        if (old == null) {
          comics[k] = incoming;
        } else {
          for (final key in ['ms', 'pages', 'opens']) {
            final a = (old[key] as num?)?.toInt() ?? 0;
            final b = (incoming[key] as num?)?.toInt() ?? 0;
            old[key] = a > b ? a : b;
          }
          incoming.forEach((key, value) => old.putIfAbsent(key, () => value));
        }
      });
      _save();
    } catch (_) {}
  }
}
