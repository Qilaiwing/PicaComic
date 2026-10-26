import 'dart:async';
import 'dart:convert';

import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/http_client.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:url_launcher/url_launcher_string.dart';

export 'package:flutter_inappwebview/flutter_inappwebview.dart' show WebUri, URLRequest;

extension WebviewExtension on InAppWebViewController{
  Future<Map<String, String>?> getCookies(String url) async{
    if(url.contains("https://")){
      url.replaceAll("https://", "");
    }
    if(url[url.length-1] == '/'){
      url = url.substring(0, url.length-1);
    }
    CookieManager cookieManager = CookieManager.instance();
    final cookies = await cookieManager.getCookies(url: WebUri(url));
    Map<String, String> res = {};
    for(var cookie in cookies){
      res[cookie.name] = cookie.value;
    }
    return res;
  }

  Future<String?> getUA() async{
    var res = await evaluateJavascript(source: "navigator.userAgent");
    if(res is String){
      if(res[0] == "'" || res[0] == "\"") {
        res = res.substring(1, res.length-1);
      }
    }
    return res is String ? res : null;
  }
}

class AppWebview extends StatefulWidget {
  const AppWebview({required this.initialUrl, this.onTitleChange,
    this.onNavigation, this.singlePage = false, this.onStarted, super.key});

  final String initialUrl;

  final void Function(String title, InAppWebViewController controller)? onTitleChange;

  final bool Function(String url)? onNavigation;

  final void Function(InAppWebViewController controller)? onStarted;

  final bool singlePage;

  @override
  State<AppWebview> createState() => _AppWebviewState();
}

class _AppWebviewState extends State<AppWebview> {
  InAppWebViewController? controller;

  String title = "Webview";

  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    bool useCustomAppBar = !UiMode.m1(context) && !widget.singlePage;

    final actions = [
      AppTooltip(
        message: "More",
        child: Builder(builder: (buttonContext) => MiuixIconButton(
          child: const Icon(Icons.more_horiz),
          onPressed: () async {
            final index = await showMiuixMenu(
              context: context,
              anchorBounds: miuixAnchorRectOf(buttonContext),
              alignment: MiuixPopupAlign.end,
              items: ["在浏览器中打开".tl, "复制链接".tl, "重新加载".tl],
            );
            switch (index) {
              case 0:
                (() async => launchUrlString((await controller?.getUrl())!.path))();
              case 1:
                (() async => Clipboard.setData(ClipboardData(text: (await controller?.getUrl())!.path)))();
              case 2:
                controller?.reload();
            }
          },
        )),
      )
    ];

    Widget body = InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
      onTitleChanged: (c, t){
        if(mounted){
          setState(() {
            title = t ?? "Webview";
          });
        }
        widget.onTitleChange?.call(title, controller!);
      },
      shouldOverrideUrlLoading: (c, r) async {
        var res = widget.onNavigation?.call(r.request.url?.toString() ?? "") ?? false;
        if(res) {
          return NavigationActionPolicy.CANCEL;
        } else {
          return NavigationActionPolicy.ALLOW;
        }
      },
      onWebViewCreated: (c){
        controller = c;
        widget.onStarted?.call(c);
      },
      onProgressChanged: (c, p){
        if(mounted){
          setState(() {
            _progress = p / 100;
          });
        }
      },
    );

    body = Stack(
      children: [
        Positioned.fill(child: body),
        if(_progress < 1.0)
          const Positioned.fill(child: Center(
              child: MiuixCircularProgressIndicator()))
      ],
    );

    if(useCustomAppBar){
      body = Column(
        children: [
          Appbar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,),
            actions: actions,
          ),
          Expanded(child: body)
        ],
      );
    }

    return MiuixScaffold(
      topBar: !useCustomAppBar ? MiuixSmallTopAppBar(color: MiuixTheme.of(context).colors.background, 
        title: title,
        navigationIcon: MiuixIconButton(
          child: MiuixIcon(
            vector: MiuixIcons.os4.chevronBackward,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: actions,
      ) : null,
      content: (padding) => !useCustomAppBar
          ? Padding(padding: EdgeInsets.only(top: padding.top), child: body)
          : body,
    );
  }
}

class DesktopWebview {
  static Future<bool> isAvailable() => WebviewWindow.isWebviewAvailable();

  final String initialUrl;

  final void Function(String title, DesktopWebview controller)? onTitleChange;

  final void Function(String url, DesktopWebview webview)? onNavigation;

  final void Function(DesktopWebview controller)? onStarted;

  final void Function()? onClose;

  DesktopWebview({
    required this.initialUrl,
    this.onTitleChange,
    this.onNavigation,
    this.onStarted,
    this.onClose
  });

  Webview? _webview;

  String? _ua;

  String? title;

  void onMessage(String message) {
    var json = jsonDecode(message);
    if(json is Map){
      if(json["id"] == "document_created"){
        title = json["data"]["title"];
        _ua = json["data"]["ua"];
        onTitleChange?.call(title!, this);
      }
    }
  }

  String? get userAgent => _ua;

  Timer? timer;

  void _runTimer() {
    timer ??= Timer.periodic(const Duration(seconds: 2), (t) async {
      const js = '''
        function collect() {
          if(document.readyState === 'loading') {
            return '';
          }
          let data = {
            id: "document_created",
            data: {
              title: document.title,
              url: location.href,
              ua: navigator.userAgent
            }
          };
          return data;
        }
        collect();
      ''';
      if(_webview != null) {
        onMessage(await evaluateJavascript(js) ?? '');
      }
    });
  }

  void open() async {
    _webview = await WebviewWindow.create(configuration: CreateConfiguration(
      useWindowPositionAndSize: true,
      userDataFolderWindows: "${App.dataPath}\\webview",
      title: "webview",
      proxy: proxyHttpOverrides?.proxyStr,
    ));
    _webview!.addOnWebMessageReceivedCallback(onMessage);
    _webview!.setOnNavigation((s) => onNavigation?.call(s, this));
    _webview!.launch(initialUrl, triggerOnUrlRequestEvent: false);
    _runTimer();
    _webview!.onClose.then((value) {
      _webview = null;
      timer?.cancel();
      timer = null;
      onClose?.call();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      onStarted?.call(this);
    });
  }

  Future<String?> evaluateJavascript(String source) {
    return _webview!.evaluateJavaScript(source);
  }

  Future<Map<String, String>> getCookies(String url) async{
    var allCookies = await _webview!.getAllCookies();
    var res = <String, String>{};
    for(var c in allCookies) {
      if(_cookieMatch(url, c.domain)){
        res[_removeCode0(c.name)] = _removeCode0(c.value);
      }
    }
    return res;
  }

  String _removeCode0(String s) {
    var codeUints = List<int>.from(s.codeUnits);
    codeUints.removeWhere((e) => e == 0);
    return String.fromCharCodes(codeUints);
  }

  bool _cookieMatch(String url, String domain) {
    domain = _removeCode0(domain);
    var host = Uri.parse(url).host;
    var acceptedHost = _getAcceptedDomains(host);
    return acceptedHost.contains(domain.removeAllBlank);
  }

  List<String> _getAcceptedDomains(String host) {
    var acceptedDomains = <String>[host];
    var hostParts = host.split(".");
    for (var i = 0; i < hostParts.length - 1; i++) {
      acceptedDomains.add(".${hostParts.sublist(i).join(".")}");
    }
    return acceptedDomains;
  }

  void close() {
    _webview?.close();
    _webview = null;
  }
}