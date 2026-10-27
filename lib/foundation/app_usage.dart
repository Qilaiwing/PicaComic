import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 仅统计 App 前台使用时长（resumed），切到后台即暂停累计。
///
/// 持久化以同步文件为主（swipe-kill / 闪退后至多多丢一个周期），
/// SharedPreferences 仅作兼容备份。
class AppUsageTracker {
  AppUsageTracker._();
  static final AppUsageTracker instance = AppUsageTracker._();

  static const _prefKey = 'app_foreground_usage_ms';
  static const _fileName = 'app_foreground_usage_ms.txt';
  static const _checkpointInterval = Duration(seconds: 5);

  int _storedMs = 0;
  DateTime? _foregroundSince;
  bool _ready = false;
  Timer? _timer;

  File get _file => File('${App.dataPath}/$_fileName');

  Future<void> init() async {
    if (_ready) return;
    try {
      if (_file.existsSync()) {
        _storedMs = int.tryParse(_file.readAsStringSync().trim()) ?? 0;
      } else {
        final prefs = await SharedPreferences.getInstance();
        _storedMs = prefs.getInt(_prefKey) ?? 0;
        _persistSync();
      }
    } catch (_) {
      _storedMs = 0;
    }
    _foregroundSince = DateTime.now();
    _startPeriodicCheckpoint();
    _ready = true;
  }

  void handleLifecycle(AppLifecycleState state) {
    if (!_ready) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _foregroundSince ??= DateTime.now();
        _startPeriodicCheckpoint();
        break;
      case AppLifecycleState.inactive:
        // 多任务 / 通知栏等：先落盘，划掉后台时不至于整段回滚。
        _checkpoint(stop: false);
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _checkpoint(stop: true);
        break;
    }
  }

  void _startPeriodicCheckpoint() {
    _timer?.cancel();
    _timer = Timer.periodic(_checkpointInterval, (_) {
      if (_foregroundSince != null) {
        _checkpoint(stop: false);
      }
    });
  }

  void _stopPeriodicCheckpoint() {
    _timer?.cancel();
    _timer = null;
  }

  /// 把自 [_foregroundSince] 起的增量并入 [_storedMs] 并立即同步写盘。
  /// [stop] 为 true 时结束本轮前台会话并停掉周期写入。
  void _checkpoint({required bool stop}) {
    final since = _foregroundSince;
    if (since != null) {
      final now = DateTime.now();
      final delta = now.difference(since).inMilliseconds;
      if (delta > 0) {
        _storedMs += delta;
      }
      _foregroundSince = stop ? null : now;
    }
    if (stop) {
      _stopPeriodicCheckpoint();
    }
    _persistSync();
  }

  void _persistSync() {
    try {
      _file.writeAsStringSync('$_storedMs', flush: true);
    } catch (_) {
      // ignore IO errors; best-effort
    }
    // 异步镜像；杀进程时可能赶不上，不依赖它。
    unawaited(
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setInt(_prefKey, _storedMs))
          .catchError((_) => false),
    );
  }

  /// 当前累计前台毫秒（含本次未结算的一段）。
  int get totalMilliseconds {
    var total = _storedMs;
    if (_foregroundSince != null) {
      total += DateTime.now().difference(_foregroundSince!).inMilliseconds;
    }
    return total;
  }

  Duration get totalDuration => Duration(milliseconds: totalMilliseconds);
}
