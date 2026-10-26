import 'package:pica_comic/base.dart';

String getBaseUrl(){
  return appdata.settings[86];
}

String getJmCoverUrl(String id) {
  return "${getBaseUrl()}/media/albums/${id}_3x4.jpg";
}

String getJmImageUrl(String imageName, String id) {
  return "${getBaseUrl()}/media/photos/$id/$imageName";
}

String getJmAvatarUrl(String imageName) {
  return "${getBaseUrl()}/media/users/$imageName";
}
