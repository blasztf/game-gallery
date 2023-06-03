import 'dart:convert';

import 'package:mangw/utility/imageprovider.dart';

class SteamGridDBImageProvider extends ImageProvider {
  @override
  Future<ImageBundle> findImages(String title) async {
    String gameId = await getGameId(title);
    return await getGameImages(gameId);
  }

  Future<ImageBundle> getGameImages(String gameId) async {
    ImageBundle listImage = ImageBundle.empty;

    if (gameId.isEmpty) return listImage;

    Map<String, String> headers = {
      "Referer": "https://www.steamgriddb.com/game/$gameId",
      "Accept": "application/json, text/plain, */*",
      "User-Agent":
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/78.0.3904.108 Chrome/78.0.3904.108 Safari/537.36",
    };

    String url = "https://www.steamgriddb.com/api/public/game/$gameId/home";
    String response = await getResponse(url, headers: headers);

    try {
      var result = json.decode(response);

      if (result['success']) {
        listImage = createImageBundle();
        listImage.artworks.addAll([
          for (var item in result['data']['grids'])
            if (item['width'] == 600 && item['height'] == 900)
              item['url'] as String
        ]);
        listImage.banners.addAll(
            [for (var item in result['data']['heroes']) item['url'] as String]);
        listImage.bigPictures.addAll([
          for (var item in result['data']['grids'])
            if (item['width'] >= item['height']) item['url'] as String
        ]);
        listImage.logos.addAll(
            [for (var item in result['data']['logos']) item['url'] as String]);
      }
    } catch (e) {
      // pass
    }

    return listImage;
  }

  Future<String> getGameId(String title) async {
    String gameId = "";

    if (title.isEmpty) return gameId;

    Map<String, String> headers = {
      "Referer": "https://www.steamgriddb.com/",
      "Accept": "application/json, text/plain, */*",
      "User-Agent":
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/78.0.3904.108 Chrome/78.0.3904.108 Safari/537.36",
    };

    String response = await getResponse(
        "https://www.steamgriddb.com/api/public/search/autocomplete?term=$title",
        headers: headers);

    try {
      var result = json.decode(response);

      if (result['success']) {
        for (var item in result['data']) {
          if (item['name'] == title) {
            gameId = "${item['id']}";
            break;
          }
        }
      }
    } catch (e) {
      // pass
    }

    return gameId;
  }
}
