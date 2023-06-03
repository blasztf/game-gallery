import 'dart:convert';

import 'package:mangw/utility/imageprovider.dart';
import 'package:mangw/utility/steamgriddbprovider.dart';
import 'package:http/http.dart' as http;

class SteamPoweredImageProvider extends SteamGridDBImageProvider {
  @override
  Future<String> getGameId(String title) async {
    String gameId = await super.getGameId(title);

    if (gameId.isEmpty) return gameId;

    Map<String, String> headers = {
      "Referer": "https://www.steamgriddb.com/",
      "Accept": "application/json, text/plain, */*",
      "User-Agent":
          "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Ubuntu Chromium/78.0.3904.108 Chrome/78.0.3904.108 Safari/537.36",
    };

    String url = "https://www.steamgriddb.com/api/public/game/$gameId";
    String response = await getResponse(url, headers: headers);

    try {
      var result = json.decode(response);

      if (result['success']) {
        gameId = result['data']['platforms']['steam']['id'];
      }
    } catch (e) {
      // pass
    }

    return gameId;
  }

  @override
  Future<ImageBundle> getGameImages(String gameId) async {
    ImageBundle result = ImageBundle.empty;

    if (gameId.isEmpty) return result;

    result = createImageBundle();

    result.banners.add(
        "https://cdn.cloudflare.steamstatic.com/steam/apps/$gameId/library_hero.jpg");

    result.artworks.add(
        "https://cdn.cloudflare.steamstatic.com/steam/apps/$gameId/library_600x900_2x.jpg");

    result.bigPictures.add(
        "https://cdn.cloudflare.steamstatic.com/steam/apps/$gameId/header.jpg");

    result.logos.add(
        "https://cdn.cloudflare.steamstatic.com/steam/apps/$gameId/logo.png");

    result = await validateResult(result);

    return result;
  }

  Future<ImageBundle> validateResult(ImageBundle imageBundle) async {
    var result = createImageBundle();
    var client = http.Client();
    await validateLinks(imageBundle.artworks, client);
    await validateLinks(imageBundle.banners, client);
    await validateLinks(imageBundle.bigPictures, client);
    await validateLinks(imageBundle.logos, client);

    return result.combine(imageBundle);
  }

  Future<List<String>> validateLinks(
      List<String> list, http.Client client) async {
    for (var image in list.toList()) {
      if (!await isLinkValid(image, client)) {
        list.remove(image);
      }
    }

    return list;
  }

  Future<bool> isLinkValid(String image, http.Client client) async {
    Uri url = Uri.parse(image);
    http.Response response = await client.head(url);
    return response.statusCode < 400;
  }
}
