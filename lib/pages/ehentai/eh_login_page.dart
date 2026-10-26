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
  const EhLoginPage({Key? key}) : super(key: key);

  @override
  State<EhLoginPage> createState() => _EhLoginPageState();
}

class _EhLoginPageState extends State<EhLoginPage> {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final c3 = TextEditingController();
  final c4 = TextEditingController();
  bool logging = false;
  late EhUserCookieParserController cookieParserController;

  @override
  void initState() {
    super.initState();
    cookieParserController = EhUserCookieParserController();
  }

  @override
  void dispose() {
    c1.dispose();
    c2.dispose();
    c3.dispose();
    c4.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(topBar: MiuixSmallTopAppBar(color: MiuixTheme.of(context).colors.background, title: "登录".tl, navigationIcon: MiuixIconButton(child: MiuixIcon(vector: MiuixIcons.os4.chevronBackward, size: 20), onPressed: () => Navigator.of(context).maybePop())), content: (padding) => ScrollUnderBar(padding: EdgeInsets.only(top: padding.top), child: SingleChildScrollView(padding: EdgeInsets.only(top: padding.top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Cookies",
                      style: TextStyle(fontSize: 18),
                    ).paddingLeft(6),
                    const SizedBox(
                      height: 8,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: MiuixTextField(controller: c1, label: "ipb_member_id", singleLine: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: MiuixTextField(controller: c2, label: "ipb_pass_hash", singleLine: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: MiuixTextField(controller: c3, label: "igneous(非必要)".tl, singleLine: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: MiuixTextField(controller: c4, label: "star(非必要)".tl, singleLine: true),
                    ),
                    EhUserCookieParser(
                      controller: cookieParserController,
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: cookieParserController.visible
                          ? _buildCookieParserButtonGroup(cookieParserController)
                          : MiuixTextButton('通过 cookie 身份信息快速填写'.tl, onPressed: () {
                          if (cookieParserController.visible) return;
                          cookieParserController.show();
                          setState(() {});
                        },),
                    ),
                    const SizedBox(height: 8,),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                        child: !logging
                            ? MiuixButton(colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                                child: Text("登录".tl),
                                onPressed: () {
                                  if (c1.text == "" || c2.text == "") {
                                    showToast(message: "请填写完整".tl);
                                  } else {
                                    login(c1.text, c2.text, c3.text, c4.text);
                                  }
                                },
                              )
                            : const MiuixInfiniteProgressIndicator(),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: SizedBox(
                        height: 40,
                        child: MiuixButton(onPressed: loginWithWebview,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("在Webview中登录".tl),
                              const Icon(
                                Icons.arrow_outward,
                                size: 15,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Center(
                      child: SizedBox(
                        height: 40,
                        child: MiuixButton(onPressed: () => launchUrlString(
                              "https://forums.e-hentai.org/index.php?act=Reg&CODE=00",
                              mode: LaunchMode.externalApplication),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("注册".tl),
                              const Icon(
                                Icons.arrow_outward,
                                size: 15,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      )),
    );
  }

  Row _buildCookieParserButtonGroup(
      EhUserCookieParserController cookieParserController) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Button.text(
          onPressed: () {
            cookieParserController.hide();
            setState(() {});
          },
          child: Text('隐藏'.tl),
        ),
        const SizedBox(width: 16),
        Button.outlined(
          onPressed: () {
            final cookieMap = cookieParserController.parse();
            setState(() {
              c1.text = cookieMap['ipb_member_id'] ?? '';
              c2.text = cookieMap['ipb_pass_hash'] ?? '';
              c3.text = cookieMap['igneous'] ?? '';
              c4.text = cookieMap['star'] ?? '';
            });
          },
          child: Text('解析'.tl),
        ),
        const SizedBox(width: 4),
      ],
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
                if(ua != null){
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
              if(ua != null){
                appdata.implicitData[3] = ua;
                appdata.writeImplicitData();
              }
              var cookies1 =
                  await webview.getCookies("https://e-hentai.org");
              var cookies2 =
                  await webview.getCookies("https://exhentai.org");
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
    loginWithCookies({
      "ipb_member_id": id,
      "ipb_pass_hash": hash,
      if (igneous != "") "igneous": igneous,
      if (star != "") "star": star,
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
    cookies.forEach((element) => element.domain = ".e-hentai.org");
    EhNetwork()
        .cookieJar
        .saveFromResponse(Uri.parse("https://e-hentai.org"), cookies);
    cookies.forEach((element) => element.domain = ".exhentai.org");
    EhNetwork()
        .cookieJar
        .saveFromResponse(Uri.parse("https://exhentai.org"), cookies);

    // EhNetwork().getUserName().then((b) {
    EhNetwork().validateCookies().then((b) {
      if(!mounted)  return;
      if (b) {
        context.pop();
        showToast(message: "登录成功".tl);
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
