import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';

import 'ehentai/subscription.dart';
import 'jm/jm_comic_page.dart';
import 'webview.dart';

void openTool() {
  final context = App.globalContext!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primary = Theme.of(context).colorScheme.primary;

  Widget buildToolItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    IconData trailingIcon = Icons.chevron_right,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        shape: const MiuixSquircleBorder(cornerRadius: 14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: ShapeDecoration(
              shape: MiuixSquircleBorder(
                cornerRadius: 14,
                side: BorderSide(
                  color: isDark
                      ? const Color(0x18FFFFFF)
                      : const Color(0x0A000000),
                  width: 0.6,
                ),
              ),
              color: isDark
                  ? const Color(0x14FFFFFF)
                  : const Color(0x06000000),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: ShapeDecoration(
                    shape: const MiuixSquircleBorder(cornerRadius: 10),
                    color: primary.withOpacity(isDark ? 0.22 : 0.12),
                  ),
                  child: Icon(icon, color: primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  trailingIcon,
                  size: 18,
                  color: isDark
                      ? const Color(0x88FFFFFF)
                      : const Color(0x66000000),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  showMiuixBottomSheet<void>(
    context: context,
    title: "工具".tl,
    endAction: MiuixIconButton(
      onPressed: () => App.globalBack(),
      child: const Icon(Icons.close, size: 20),
    ),
    builder: (context, close) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildToolItem(
              icon: Icons.subscriptions,
              title: "EH订阅".tl,
              onTap: () {
                App.globalBack();
                App.mainNavigatorKey?.currentContext
                    ?.to(() => const SubscriptionPage());
              },
            ),
            buildToolItem(
              icon: Icons.image_search_outlined,
              title: "图片搜索 [搜图bot酱]".tl,
              trailingIcon: Icons.open_in_new,
              onTap: () async {
                App.globalBack();
                if (App.isMobile) {
                  App.mainNavigatorKey?.currentContext?.to(
                    () => AppWebview(
                      initialUrl: "https://soutubot.moe/",
                      onNavigation: (uri) {
                        return handleAppLinks(Uri.parse(uri),
                            showMessageWhenError: false);
                      },
                    ),
                  );
                } else {
                  var webview = DesktopWebview(
                    initialUrl: "https://soutubot.moe/",
                    onNavigation: (s, webview) {
                      if (handleAppLinks(Uri.parse(s),
                          showMessageWhenError: false)) {
                        Future.microtask(() => webview.close());
                      }
                    },
                  );
                  webview.open();
                }
              },
            ),
            buildToolItem(
              icon: Icons.image_search,
              title: "图片搜索 [SauceNAO]".tl,
              trailingIcon: Icons.open_in_new,
              onTap: () async {
                App.globalBack();
                if (App.isMobile || App.isMacOS) {
                  App.mainNavigatorKey?.currentContext?.to(
                    () => AppWebview(
                      initialUrl: "https://saucenao.com/",
                      onNavigation: (uri) {
                        return handleAppLinks(Uri.parse(uri),
                            showMessageWhenError: false);
                      },
                    ),
                  );
                } else {
                  var webview = DesktopWebview(
                    initialUrl: "https://saucenao.com/",
                    onNavigation: (s, webview) {
                      if (handleAppLinks(Uri.parse(s),
                          showMessageWhenError: false)) {
                        Future.microtask(() => webview.close());
                      }
                    },
                  );
                  webview.open();
                }
              },
            ),
            buildToolItem(
              icon: Icons.link,
              title: "打开链接".tl,
              onTap: () {
                final FocusNode focusNode = FocusNode();
                showDialog(
                  context: App.globalContext!,
                  builder: (context) {
                    final controller = TextEditingController();
                    focusNode.requestFocus();

                    validateText() {
                      var text = controller.text;
                      if (text == "") {
                        return null;
                      }

                      if (!text.contains("http://") &&
                          !text.contains("https://")) {
                        text = "https://$text";
                      }

                      if (!text.isURL) {
                        return "不支持的链接".tl;
                      }
                      var uri = Uri.parse(text);
                      if (![
                        "exhentai.org",
                        "e-hentai.org",
                        "hitomi.la",
                        "nhentai.net",
                        "nhentai.xxx"
                      ].contains(uri.host)) {
                        return "不支持的链接".tl;
                      }
                      return null;
                    }

                    void Function(void Function())? stateSetter;

                    onFinish() {
                      if (validateText() != null) {
                        stateSetter?.call(() {});
                      } else {
                        App.globalBack();
                        var text = controller.text;
                        if (!text.contains("http://") &&
                            !text.contains("https://")) {
                          text = "https://$text";
                        }
                        App.globalBack();
                        handleAppLinks(Uri.parse(text));
                      }
                    }

                    return AlertDialog(
                      shape: const MiuixSquircleBorder(cornerRadius: 20),
                      title: Text("输入链接".tl),
                      content: StatefulBuilder(
                        builder: (BuildContext context,
                            void Function(void Function()) setState) {
                          stateSetter = setState;
                          return TextField(
                            focusNode: focusNode,
                            controller: controller,
                            decoration: InputDecoration(
                              errorText: validateText(),
                            ),
                            onSubmitted: (s) => onFinish(),
                          );
                        },
                      ),
                      actions: [
                        MiuixTextButton("打开".tl, onPressed: onFinish),
                      ],
                    );
                  },
                );
              },
            ),
            buildToolItem(
              icon: Icons.numbers,
              title: "禁漫漫画ID".tl,
              onTap: () {
                var controller = TextEditingController();
                final FocusNode focusNode = FocusNode();
                showDialog(
                  context: context,
                  builder: (context) {
                    focusNode.requestFocus();
                    return AlertDialog(
                      shape: const MiuixSquircleBorder(cornerRadius: 20),
                      title: Text("输入禁漫漫画ID".tl),
                      content: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: TextField(
                          focusNode: focusNode,
                          keyboardType: TextInputType.number,
                          controller: controller,
                          onEditingComplete: () {
                            App.globalBack();
                            if (controller.text.isNum) {
                              context.to(() => JmComicPage(controller.text));
                            } else {
                              showToast(message: "输入的ID不是数字".tl);
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                          ],
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "ID",
                              prefix: Text("JM")),
                        ),
                      ),
                      actions: [
                        MiuixTextButton("提交".tl, onPressed: () {
                              App.globalBack();
                              if (controller.text.isNum) {
                                App.globalBack();
                                App.mainNavigatorKey?.currentContext
                                    ?.to(() => JmComicPage(controller.text));
                              } else {
                                showToast(message: "输入的ID不是数字".tl);
                              }
                            })
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
  );
}
