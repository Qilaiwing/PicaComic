import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 仅统计 App 前台使用时长（resumed），切到后台即暂停累计。
class AppUsageTracker {
  AppUsageTracker._();
  static final AppUsageTracker instance = AppUsageTracker._();

  static const _prefKey = 'app_foreground_usage_ms';

  int _storedMs = 0;
  DateTime? _foregroundSince;
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    final prefs = await SharedPreferences.getInstance();
    _storedMs = prefs.getInt(_prefKey) ?? 0;
    _foregroundSince = DateTime.now();
    _ready = true;
  }

  void handleLifecycle(AppLifecycleState state) {
    if (!_ready) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _foregroundSince ??= DateTime.now();
        break;
      case AppLifecycleState.inactive:
        // 通知栏 / 多任务预览等短暂 inactive，仍算前台，不结算。
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _flush();
        break;
    }
  }

  void _flush() {
    if (_foregroundSince == null) return;
    final delta = DateTime.now().difference(_foregroundSince!).inMilliseconds;
    if (delta > 0) {
      _storedMs += delta;
      _save();
    }
    _foregroundSince = null;
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, _storedMs);
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
