import 'package:pica_comic/foundation/def.dart';
import 'hitomi_main_network.dart';
import 'hitomi_models.dart';
import 'package:dio/dio.dart';

///获取图像url使用的一个临时的类
///
/// 需要发起一个网络请求获取gg.js并对其进行解析
///
/// gg.js内容会动态变化
class GG{
  String get baseDomain => HiNetwork().baseDomain;
  List<String> numbers = [];
  int initialG = 1;
  int mm(int g){
    if(numbers.contains(g.toString())){
      return ~initialG&1;
    }else{
      return initialG;
    }
  }

  static String s(String h) {
    RegExp exp = RegExp(r'(..)(.)$');
    Match? m = exp.firstMatch(h);
    if (m != null) {
      int g = int.parse(m.group(2)! + m.group(1)!, radix: 16);
      return g.toString();
    } else {
      return "";
    }
  }

  String? b;

  ///通过缓存减少请求时间, 短时间内gg.js不会变化
  static DateTime? cacheTime;
  static String? cacheB;
  static List<String>? cacheNumbers;

  Future<void> getGg(String galleryId) async{
    if(cacheTime!=null && DateTime.now().millisecondsSinceEpoch - cacheTime!.millisecondsSinceEpoch < 100){
      numbers = cacheNumbers!;
      b = cacheB!;
      return;
    }
    var dio = Dio(BaseOptions(
        responseType: ResponseType.plain,
        headers: {
          "User-Agent": webUA,
          "Referer": "https://hitomi.la/reader/$galleryId.html"
        }
    ));
    var res = await dio.get<String>("https://ltn.$baseDomain/gg.js?_=1683939645979");
    RegExp exp = RegExp(r'(?<=case )\d+');
    Iterable<RegExpMatch> matches = exp.allMatches(res.data!);
    numbers = [];
    for (RegExpMatch match in matches) {
      numbers.add(match.group(0)!);
    }
    exp = RegExp(r"(?<=b: ')\d+");
    b = exp.firstMatch(res.data!)![0];
    exp = RegExp(r"(?<=var o = )[0-9]+");
    initialG = int.parse(exp.firstMatch(res.data!)![0]!);
    cacheTime = DateTime.now();
    cacheB = b;
    cacheNumbers = numbers;
  }

  String subdomainFromUrl(String url, String? base){
    var retval = 'b';
    if (base != null) {
      retval = base;
    }

    var b = 16;
    var m = RegExp(r"/[0-9a-f]{61}([0-9a-f]{2})([0-9a-f])").firstMatch(url);
    if(m == null){
      return 'a';
    }
    int g = int.parse(m[2]! + m[1]!, radix: b);
    if (!g.isNaN) {
      var char = String.fromCharCode(97 + mm(g));
      if (retval == "tn") {
        retval = char + retval;
      } else if (retval == "w") {
        if (char == 'a') {
          retval = '${retval}1';
        }
        else if (char == 'b') {
          retval = '${retval}2';
        }
      }
    }
    return retval;
  }

  String fullPathFromHash(String hash) {
    return '$b/${GG.s(hash)}/$hash';
  }

  String realFullPathFromHash(String hash) {
    RegExp regex = RegExp(r'^.*(..)(.)$');
    String newPath = regex.stringMatch(hash)!.replaceAllMapped(regex, (match) {
      return '${match.group(2)}/${match.group(1)}/$hash';
    });
    return newPath;
  }

  String urlFromUrl(String url, String? base) {
    return url.replaceFirst("https://", "https://${subdomainFromUrl(url, base)}.");
  }

  String urlFromHash(HitomiFile image, String? dir, String? ext) {
    ext ??= dir ??= image.name.split('.').last;
    dir ??= 'images';
    var url = "";
    if(dir.contains('small')){
      url = urlFromUrl('https://$baseDomain/$dir/${realFullPathFromHash(image.hash)}.$ext', 'tn');
    } else {
      url = urlFromUrl('https://$baseDomain/${fullPathFromHash(image.hash)}.$ext', 'w');
    }
    return url;
  }

  ///获取图像信息
  Future<String> urlFromUrlFromHash(String galleryId, HitomiFile image, String? dir, String? ext) async{
    await getGg(galleryId);
    return urlFromHash(image, dir, ext);
  }
}