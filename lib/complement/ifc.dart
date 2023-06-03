mixin InternetFileCheck {
  // Check if file from local or internet
  bool isFileFromInternet(String path) {
    return path.startsWith(RegExp(r'https?://'));
  }
}
