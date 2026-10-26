import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';


void setKeepScreenOn() async{
  if(!App.isMobile)  return;
  var channel = const MethodChannel("com.picacomic_miuix/keepScreenOn");
  await channel.invokeMethod("set");
}

void cancelKeepScreenOn() async{
  if(!App.isMobile)  return;
  var channel = const MethodChannel("com.picacomic_miuix/keepScreenOn");
  await channel.invokeMethod("cancel");
}