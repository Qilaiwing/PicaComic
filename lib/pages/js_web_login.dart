import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/js_engine.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/cookie_jar.dart';
import 'package:pica_comic/pages/webview.dart';
import 'package:pica_comic/tools/translations.dart';

/// Open the JS-source web login page (account.loginWithWebview).
///
/// Copies WebView cookies into [SingleInstanceCookieJar] (same jar JS Network
/// uses), marks the source logged in, then closes. Cookie values are never logged.
///
/// Detection: run checkStatus on every main-frame navigation and title change;
/// when it passes, save cookies and leave. URL checkStatus is the source of truth.
Future<void> openJsSourceWebLogin(BuildContext context, String sourceKey) async {
  String? loginUrl;
  try {
    final v = JsEngine()
        .runCode("ComicSource.sources.$sourceKey.account.loginWithWebview.url");
    if (v is String) loginUrl = v;
  } catch (e, s) {
    Log.error("JS WebLogin", "$e\n$s");
  }
  if (loginUrl == null || loginUrl.isEmpty) {
    showToast(message: "未配置登录页面".tl);
    return;
  }

  if (App.isDesktop && (await DesktopWebview.isAvailable())) {
    final completer = Completer<void>();
    var finished = false;
    String currentUrl = loginUrl;

    Future<void> tryFinish(String? url, String title, DesktopWebview webview) async {
      if (finished) return;
      final u = (url != null && url.isNotEmpty) ? url : currentUrl;
      if (url != null && url.isNotEmpty) currentUrl = url;
      if (!await _jsWebLoginCheck(sourceKey, u, title)) return;
      if (finished) return;
      finished = true;
      try {
        final cookies = await webview.getCookies(u);
        _saveWebCookies(u, cookies);
        webview.close();
        showToast(message: "登录成功".tl, icon: const Icon(Icons.check));
        // ignore: unawaited_futures
        _markJsWebLoggedIn(sourceKey);
      } catch (e, s) {
        finished = false;
        Log.error("JS WebLogin", "$e\n$s");
        showToast(message: "登录失败".tl);
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    }

    final webview = DesktopWebview(
      initialUrl: loginUrl,
      onTitleChange: (title, controller) async {
        String? url;
        try {
          final raw = await controller.evaluateJavascript("location.href");
          if (raw is String) {
            url = raw;
            if ((url.startsWith('"') && url.endsWith('"')) ||
                (url.startsWith("'") && url.endsWith("'"))) {
              url = url.substring(1, url.length - 1);
            }
          }
        } catch (_) {}
        await tryFinish(url, title, controller);
      },
      onNavigation: (url, controller) {
        currentUrl = url;
        Future.microtask(() async {
          String title = "";
          try {
            final raw = await controller.evaluateJavascript("document.title");
            if (raw is String) {
              title = raw;
              if ((title.startsWith('"') && title.endsWith('"')) ||
                  (title.startsWith("'") && title.endsWith("'"))) {
                title = title.substring(1, title.length - 1);
              }
            }
          } catch (_) {}
          await tryFinish(url, title, controller);
        });
      },
      onClose: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
    webview.open();
    await completer.future;
    return;
  }

  if (App.isMobile) {
    await App.globalTo(
      () => _JsWebLoginPage(sourceKey: sourceKey, loginUrl: loginUrl!),
    );
    return;
  }

  showToast(message: "当前设备不支持".tl);
}

Future<bool> _jsWebLoginCheck(String sourceKey, String? url, String title) async {
  if (url == null || url.isEmpty) return false;
  try {
    final res = JsEngine().runCode("""
      (function(){
        var cfg = ComicSource.sources.$sourceKey.account.loginWithWebview;
        if(!cfg || typeof cfg.checkStatus !== 'function') return false;
        return !!cfg.checkStatus(${jsonEncode(url)}, ${jsonEncode(title)});
      })()
    """);
    return res == true;
  } catch (e, s) {
    Log.error("JS WebLogin", "$e\n$s");
    return false;
  }
}

void _saveWebCookies(String url, Map<String, String> cookies) {
  if (cookies.isEmpty) return;
  final uri = Uri.parse(url);
  var domain = uri.host;
  final splits = domain.split('.');
  if (splits.length > 1) {
    domain = ".${splits[splits.length - 2]}.${splits[splits.length - 1]}";
  }
  if (uri.host.endsWith("mangadex.org")) {
    domain = ".mangadex.org";
  }
  final list = <io.Cookie>[];
  cookies.forEach((name, value) {
    final c = io.Cookie(name, value);
    c.domain = domain;
    list.add(c);
  });
  SingleInstanceCookieJar.instance!.saveFromResponse(uri, list);
}

Future<void> _markJsWebLoggedIn(String sourceKey) async {
  final source = ComicSource.find(sourceKey);
  if (source == null) return;
  source.data["account"] = "ok";
  try {
    final has = JsEngine().runCode(
            "typeof ComicSource.sources.$sourceKey.account.loginWithWebview.onLoginSuccess === 'function'") ==
        true;
    if (has) {
      await JsEngine().runCode(
          "ComicSource.sources.$sourceKey.account.loginWithWebview.onLoginSuccess()");
    }
  } catch (e, s) {
    Log.error("JS WebLogin", "$e\n$s");
  }
  try {
    final hasCheck = JsEngine().runCode(
            "typeof ComicSource.sources.$sourceKey.account.checkStatus === 'function'") ==
        true;
    if (hasCheck) {
      final res = await JsEngine()
          .runCode("ComicSource.sources.$sourceKey.account.checkStatus()");
      if (res is Map && res["username"] != null) {
        source.data["username"] = res["username"].toString();
      }
    }
  } catch (e, s) {
    Log.error("JS WebLogin", "$e\n$s");
  }
  source.saveData();
}

class _JsWebLoginPage extends StatefulWidget {
  const _JsWebLoginPage({required this.sourceKey, required this.loginUrl});

  final String sourceKey;
  final String loginUrl;

  @override
  State<_JsWebLoginPage> createState() => _JsWebLoginPageState();
}

class _JsWebLoginPageState extends State<_JsWebLoginPage> {
  var _finished = false;
  var _checking = false;
  InAppWebViewController? _controller;
  Timer? _timer;
  late String _currentUrl = widget.loginUrl;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final c = _controller;
    if (c == null || _finished || !mounted) return;
    try {
      final u = await c.getUrl().timeout(const Duration(seconds: 2));
      if (u != null) _currentUrl = u.toString();
      final t = await c.getTitle().timeout(const Duration(seconds: 2)) ?? "";
      await _handle(_currentUrl, t);
    } catch (_) {}
  }

  Future<void> _handle(String? url, String title) async {
    if (_finished || _checking || !mounted) return;
    _checking = true;
    try {
      final u = (url != null && url.isNotEmpty) ? url : _currentUrl;
      if (url != null && url.isNotEmpty) _currentUrl = url;
      if (!await _jsWebLoginCheck(widget.sourceKey, u, title)) return;
      final c = _controller;
      if (c == null) return;
      if (_finished || !mounted) return;
      _finished = true;
      _timer?.cancel();
      try {
        final cookies =
            await c.getCookies(u).timeout(const Duration(seconds: 5)) ?? {};
        _saveWebCookies(u, cookies);
      } catch (e) {
        Log.error("JS WebLogin", "save cookies failed: ${e.runtimeType}");
      }
      if (mounted) {
        showToast(message: "登录成功".tl, icon: const Icon(Icons.check));
        App.globalBack();
      }
      try {
        await _markJsWebLoggedIn(widget.sourceKey)
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        Log.error("JS WebLogin", "mark logged in: ${e.runtimeType}");
        ComicSource.find(widget.sourceKey)
          ?..data["account"] = "ok"
          ..saveData();
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppWebview(
      initialUrl: widget.loginUrl,
      singlePage: true,
      onStarted: (c) => _controller = c,
      onTitleChange: (title, c) async {
        _controller = c;
        try {
          final u = await c.getUrl();
          if (u != null) _currentUrl = u.toString();
        } catch (_) {}
        await _handle(_currentUrl, title);
      },
      onLoadStop: (url, c) async {
        _controller = c;
        if (url.isNotEmpty) _currentUrl = url;
        String title = "";
        try {
          title = await c.getTitle() ?? "";
        } catch (_) {}
        await _handle(_currentUrl, title);
      },
      onNavigation: (url) {
        _currentUrl = url;
        final c = _controller;
        if (c != null) {
          Future.microtask(() async {
            String title = "";
            try {
              title = await c.getTitle() ?? "";
            } catch (_) {}
            await _handle(url, title);
          });
        }
        return false;
      },
    );
  }
}