import 'dart:io';

import 'package:mangw/complement/ifc.dart';
import 'package:path/path.dart';

class FileSaver with InternetFileCheck {
  FileSaver(String path) {
    _path = path;
  }

  late final String _path;

  Future<bool> saveTo(String dstPath, {String as = ''}) async {
    return await (isFileFromInternet(_path)
        ? _downloadFile(_path, dstPath, as)
        : _copyFile(_path, dstPath, as));
  }

  Future<bool> _downloadFile(String path, String dstPath, String as) async {
    bool result = true;
    var url = Uri.parse(path);
    var httpClient = HttpClient();
    var httpRequest = await httpClient.getUrl(url);
    var httpResponse = await httpRequest.close();
    var filename = as.isEmpty ? basename(path) : as;
    filename = filename.replaceAll(RegExp(r'(\?|\#).*'), '');
    var file = File(join(dstPath, filename));
    try {
      await httpResponse.forEach((bytes) {
        file.writeAsBytesSync(bytes, mode: FileMode.append);
      });
    } catch (err) {
      result = false;
    } finally {
      httpClient.close();
    }

    return result;
  }

  Future<bool> _copyFile(String path, String dstPath, String as) async {
    bool result = true;
    File file = File(path);
    String filename = as.isEmpty ? basename(path) : as;
    try {
      file.copy(join(dstPath, filename));
    } catch (err) {
      result = false;
    }
    return result;
  }
}
