import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/pages/ehentai/eh_user_cookie_parser.dart';
import 'package:pica_comic/pages/webview.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../foundation/app.dart';
import '../../network/eh_network/eh_main_network.dart';

class EhLoginPage extends StatefulWidget {
  const EhLoginPage({super.key});

  @override
  State<EhLoginPage> createState() => _EhLoginPageState();
}

class _EhLoginPageState extends State<EhLoginPage> {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final c3 = TextEditingController();
  final c4 = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();
  final _f3 = FocusNode();
  final _f4 = FocusNode();

  bool logging = false;
  late EhUserCookieParserController cookieParserController;
  late final MiuixExitUntilCollapsedScrollBehavior _behavior;

  @override
  void initState() {
    super.initState();
    cookieParserController = EhUserCookieParserController();
    _behavior = MiuixExitUntilCollapsedScrollBehavior();
    for (final c in [c1, c2, c3, c4]) {
      c.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [c1, c2, c3, c4]) {
      c.removeListener(_onTextChanged);
      c.dispose();
    }
    for (final f in [_f1, _f2, _f3, _f4]) {
      f.dispose();
    }
    _behavior.state.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  bool get _canSubmit =>
      !logging && c1.text.trim().isNotEmpty && c2.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MiuixTheme.of(context).colors.background,
      child: MiuixScaffold(
        containerColor: MiuixTheme.of(context).colors.background,
        topBar: MiuixTopAppBar(
          color: MiuixTheme.of(context).colors.background,
          blurred: true,
          blurRadius: 0,
          blurTintAlpha: 0,
          title: "登录".tl,
          scrollBehavior: _behavior,
          navigationIcon: MiuixIconButton(
            child: MiuixIcon(
              vector: MiuixIcons.os4.chevronBackward,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        content: (padding) => MiuixScrollBehaviorListener(
          behavior: _behavior,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              padding.top + 8,
              20,
              padding.bottom + MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _buildHeader(),
                const SizedBox(height: 28),
                _buildForm(),
                const SizedBox(height: 12),
                _buildCookieParser(),
                const SizedBox(height: 28),
                _buildSubmitButton(),
                const SizedBox(height: 10),
                _buildWebviewButton(),
                const SizedBox(height: 4),
                Center(child: _buildRegisterButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = MiuixTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: ShapeDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: const MiuixSquircleBorder(cornerRadius: 18),
          ),
          child: Center(
            child: MiuixIcon(
              vector: MiuixIcons.os4.contactsCircle,
              size: 26,
              tint: colors.primary,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          "欢迎回到@name".tlParams({"name": "E-Hentai"}),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: colors.onBackground,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "使用 Cookie 登录 E-Hentai".tl,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: colors.onSurfaceVariantSummary,
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required dynamic icon,
    FocusNode? next,
    bool last = false,
  }) {
    final colors = MiuixTheme.of(context).colors;
    return MiuixTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      singleLine: true,
      insideMargin: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      onSubmitted: (_) {
        if (next != null) {
          next.requestFocus();
        } else if (_canSubmit) {
          login(c1.text, c2.text, c3.text, c4.text);
        }
      },
      leadingIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 10),
        child: MiuixIcon(
          vector: icon,
          size: 18,
          tint: colors.onSurfaceVariantSummary,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return MiuixCard(
      cornerRadius: 20,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          children: [
            _field(
              controller: c1,
              focusNode: _f1,
              label: "ipb_member_id",
              icon: MiuixIcons.os4.contacts,
              next: _f2,
            ),
            const SizedBox(height: 12),
            _field(
              controller: c2,
              focusNode: _f2,
              label: "ipb_pass_hash",
              icon: MiuixIcons.os4.lock,
              next: _f3,
            ),
            const SizedBox(height: 12),
            _field(
              controller: c3,
              focusNode: _f3,
              label: "igneous(非必要)".tl,
              icon: MiuixIcons.os4.addBookmark,
              next: _f4,
            ),
            const SizedBox(height: 12),
            _field(
              controller: c4,
              focusNode: _f4,
              label: "star(非必要)".tl,
              icon: MiuixIcons.os4.starred,
              last: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookieParser() {
    final colors = MiuixTheme.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: cookieParserController.visible
              ? Column(
                  key: const ValueKey('parser'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EhUserCookieParser(controller: cookieParserController),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        MiuixTextButton(
                          "隐藏".tl,
                          onPressed: () {
                            cookieParserController.hide();
                            setState(() {});
                          },
                        ),
                        const Spacer(),
                        MiuixButton(
                          cornerRadius: 14,
                          onPressed: () {
                            final cookieMap = cookieParserController.parse();
                            setState(() {
                              c1.text = cookieMap['ipb_member_id'] ?? '';
                              c2.text = cookieMap['ipb_pass_hash'] ?? '';
                              c3.text = cookieMap['igneous'] ?? '';
                              c4.text = cookieMap['star'] ?? '';
                            });
                          },
                          child: Text("解析".tl),
                        ),
                      ],
                    ),
                  ],
                )
              : Align(
                  key: const ValueKey('show'),
                  alignment: Alignment.centerLeft,
                  child: MiuixTextButton(
                    "通过 cookie 身份信息快速填写".tl,
                    onPressed: () {
                      cookieParserController.show();
                      setState(() {});
                    },
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          "Cookies",
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariantSummary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: MiuixButton(
        onPressed: _canSubmit
            ? () => login(c1.text, c2.text, c3.text, c4.text)
            : null,
        enabled: _canSubmit,
        cornerRadius: 16,
        minHeight: 48,
        minWidth: double.infinity,
        insideMargin: const EdgeInsets.symmetric(vertical: 12),
        colors: MiuixButtonDefaults.buttonColorsPrimary(context),
        child: logging
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MiuixCircularProgressIndicator(
                    size: 16,
                    strokeWidth: 2,
                    colors: MiuixProgressIndicatorColors(
                      foregroundColor:
                          MiuixTheme.of(context).colors.onPrimary,
                      disabledForegroundColor:
                          MiuixTheme.of(context).colors.onPrimary,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "登录中".tl,
                    style: TextStyle(
                      color: MiuixTheme.of(context).colors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                "登录".tl,
                style: TextStyle(
                  color: MiuixTheme.of(context).colors.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildWebviewButton() {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: MiuixButton(
        cornerRadius: 14,
        minHeight: 44,
        minWidth: double.infinity,
        onPressed: logging ? null : loginWithWebview,
        enabled: !logging,
        child: Text(
          "在Webview中登录".tl,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: MiuixTheme.of(context).colors.onBackground,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    final colors = MiuixTheme.of(context).colors;
    return MiuixButton(
      onPressed: () => launchUrlString(
        "https://forums.e-hentai.org/index.php?act=Reg&CODE=00",
        mode: LaunchMode.externalApplication,
      ),
      cornerRadius: 16,
      colors: MiuixButtonColors(
        color: Colors.transparent,
        disabledColor: Colors.transparent,
        contentColor: colors.primary,
        disabledContentColor: colors.onSurfaceVariantSummary,
      ),
      insideMargin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("没有账号？前往注册".tl),
          const SizedBox(width: 4),
          const Icon(Icons.open_in_new, size: 14),
        ],
      ),
    );
  }

  void loginWithWebview() async {
    if (App.isMobile) {
      App.globalTo(() => AppWebview(
            singlePage: true,
            initialUrl:
                "https://forums.e-hentai.org/index.php?act=Login&CODE=00",
            onTitleChange: (title, controller) async {
              if (title == "E-Hentai Forums") {
                var ua = await controller.getUA();
                if (ua != null) {
                  appdata.implicitData[3] = ua;
                  appdata.writeImplicitData();
                }
                var cookies1 =
                    await controller.getCookies("https://e-hentai.org") ?? {};
                var cookies2 =
                    await controller.getCookies("https://exhentai.org") ?? {};
                var cookies = <String, String>{};
                cookies1.forEach((key, value) {
                  cookies[key] = value;
                });
                cookies2.forEach((key, value) {
                  cookies[key] = value;
                });
                loginWithCookies(cookies);
                App.globalBack();
              }
            },
          ));
    } else if (App.isDesktop) {
      if (await DesktopWebview.isAvailable()) {
        var webview = DesktopWebview(
          initialUrl: "https://forums.e-hentai.org/index.php?act=Login&CODE=00",
          onTitleChange: (url, webview) async {
            if (url == "E-Hentai Forums") {
              var ua = webview.userAgent;
              if (ua != null) {
                appdata.implicitData[3] = ua;
                appdata.writeImplicitData();
              }
              var cookies1 = await webview.getCookies("https://e-hentai.org");
              var cookies2 = await webview.getCookies("https://exhentai.org");
              webview.close();
              var cookies = <String, String>{};
              cookies1.forEach((key, value) {
                cookies[key] = value;
              });
              cookies2.forEach((key, value) {
                cookies[key] = value;
              });
              loginWithCookies(cookies);
            }
          },
        );
        webview.open();
      } else {
        showToast(message: "Unsupported device".tl);
      }
    }
  }

  void login(String id, String hash, String igneous, String star) {
    FocusScope.of(context).unfocus();
    loginWithCookies({
      "ipb_member_id": id.trim(),
      "ipb_pass_hash": hash.trim(),
      if (igneous.trim() != "") "igneous": igneous.trim(),
      if (star.trim() != "") "star": star.trim(),
    });
  }

  void loginWithCookies(Map<String, String> cookiesMap) async {
    setState(() {
      logging = true;
    });

    EhNetwork().cookieJar.deleteUri(Uri.parse('https://e-hentai.org'));
    EhNetwork().cookieJar.deleteUri(Uri.parse('https://exhentai.org'));

    var cookies =
        cookiesMap.entries.map((e) => Cookie(e.key, e.value)).toList();
    for (final element in cookies) {
      element.domain = ".e-hentai.org";
    }
    EhNetwork()
        .cookieJar
        .saveFromResponse(Uri.parse("https://e-hentai.org"), cookies);
    for (final element in cookies) {
      element.domain = ".exhentai.org";
    }
    EhNetwork()
        .cookieJar
        .saveFromResponse(Uri.parse("https://exhentai.org"), cookies);

    EhNetwork().validateCookies().then((b) {
      if (!mounted) return;
      if (b) {
        context.pop();
        showToast(
          message: "登录成功".tl,
          icon: const Icon(Icons.check),
        );
      } else {
        EhNetwork().cookieJar.deleteUri(Uri.parse('https://e-hentai.org'));
        EhNetwork().cookieJar.deleteUri(Uri.parse('https://exhentai.org'));
        showToast(message: "登录失败".tl);
        setState(() {
          logging = false;
        });
      }
    });
  }
}
