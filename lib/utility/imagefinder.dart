import 'package:mangw/utility/imageprovider.dart';

class ImageFinder {
  ImageFinder.use(this.providers);

  final List<ImageProvider> providers;

  Future<ImageBundle> find(String title) async {
    ImageBundle imageBundle = ImageBundle.empty;
    for (ImageProvider provider in providers) {
      if (imageBundle == ImageBundle.empty) {
        imageBundle = await provider.findImages(title);
      } else {
        imageBundle.combine(await provider.findImages(title));
      }
    }
    return imageBundle;
  }
}
