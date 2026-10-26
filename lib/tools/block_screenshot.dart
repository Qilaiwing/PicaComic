import 'package:flutter/services.dart';

void blockScreenshot(){
  const MethodChannel("com.picacomic_miuix/screenshot").invokeMethod("blockScreenshot");
}