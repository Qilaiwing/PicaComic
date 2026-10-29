import 'package:flutter/material.dart';
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
      child: MiuixPressable(shape: const MiuixSquircleBorder(cornerRadius: 14), onPressed: onTap, child: Container(
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
          )),
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
              onTap: () async {
                final controller = TextEditingController();
                String? errorText;
                String? validateText() {
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

                final ok = await showMiuixDialog<bool>(
                  context: App.globalContext!,
                  title: "输入链接".tl,
                  contentBuilder: (context, close) => StatefulBuilder(
                    builder: (context, setState) {
                      void onFinish() {
                        errorText = validateText();
                        if (errorText != null) {
                          setState(() {});
                        } else {
                          close(true);
                        }
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MiuixTextField(
                            controller: controller,
                            autofocus: true,
                            singleLine: true,
                            onChanged: (_) {
                              if (errorText != null) {
                                setState(() => errorText = validateText());
                              }
                            },
                            onSubmitted: (s) => onFinish(),
                          ),
                          if (errorText != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                              child: Text(
                                errorText!,
                                style: TextStyle(
                                    color: context.colorScheme.error,
                                    fontSize: 12),
                              ),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: MiuixTextButton("打开".tl,
                                colors: MiuixButtonDefaults.buttonColorsPrimary(
                                    context),
                                onPressed: onFinish),
                          ),
                        ],
                      );
                    },
                  ),
                );
                if (ok != true || validateText() != null) return;
                var text = controller.text;
                if (!text.contains("http://") && !text.contains("https://")) {
                  text = "https://$text";
                }
                App.globalBack();
                handleAppLinks(Uri.parse(text));
              },
            ),
            buildToolItem(
              icon: Icons.numbers,
              title: "禁漫漫画ID".tl,
              onTap: () async {
                var controller = TextEditingController();
                final action = await showMiuixDialog<String>(
                  context: context,
                  title: "输入禁漫漫画ID".tl,
                  contentBuilder: (context, close) => MiuixTextField(
                    controller: controller,
                    autofocus: true,
                    singleLine: true,
                    keyboardType: TextInputType.number,
                    label: "ID",
                    leadingIcon: const Padding(
                      padding: EdgeInsets.only(left: 12, right: 4),
                      child: Text("JM"),
                    ),
                    onSubmitted: (_) => close("edit"),
                  ),
                  actionsBuilder: (context, close) => [
                    MiuixTextButton("提交".tl,
                        colors: MiuixButtonDefaults.buttonColorsPrimary(context),
                        onPressed: () => close("submit")),
                  ],
                );
                if (action == null) return;
                final id = controller.text.replaceAll(RegExp("[^0-9]"), "");
                if (id.isNum) {
                  if (action == "submit") App.globalBack();
                  App.mainNavigatorKey?.currentContext
                      ?.to(() => JmComicPage(id));
                } else {
                  showToast(message: "输入的ID不是数字".tl);
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
  );
}
