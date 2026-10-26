import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/tools/translations.dart';

class CookieManagementView extends StatefulWidget {
  const CookieManagementView({super.key});

  @override
  State<CookieManagementView> createState() => _CookieManagementViewState();
}

class _CookieManagementViewState extends State<CookieManagementView> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text("cookies"),
      shape: const RoundedRectangleBorder(),
      children: [
        MiuixBasicComponent(title: "ipb_member_id", summary: EhNetwork().id, onClick: () => setClipboard(EhNetwork().id),),
        MiuixBasicComponent(title: "ipb_pass_hash", summary: EhNetwork().hash, onClick: () => setClipboard(EhNetwork().hash),),
        MiuixBasicComponent(title: "igneous", summary: EhNetwork().igneous, onClick: () => setClipboard(EhNetwork().igneous), endActions: [MiuixIconButton(child: const Icon(Icons.edit_outlined), onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  String text = EhNetwork().igneous;
                  return AlertDialog(
                    title: const Text("igneous"),
                    content: TextField(
                      controller: TextEditingController(text: text),
                      onChanged: (s) => text = s,
                    ),
                    actions: [
                      TextButton(onPressed: context.pop, child: Text("取消".tl)),
                      TextButton(
                        onPressed: () {
                          EhNetwork().igneous = text;
                          EhNetwork().cookieJar.saveFromResponse(
                            Uri.parse("https://exhentai.org"),
                            [Cookie("igneous", text)],
                          );
                          EhNetwork().cookieJar.saveFromResponse(
                            Uri.parse("https://e-hentai.org"),
                            [Cookie("igneous", text)],
                          );
                          context.pop();
                          setState(() {});
                        },
                        child: Text("确定".tl),
                      ),
                    ],
                  );
                },
              );
            },)],),
      ],
    );
  }

  void setClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(message: "已复制".tl, icon: const Icon(Icons.check));
  }
}
