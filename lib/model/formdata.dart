import 'dart:collection';

class FormData {
  final Map<String, Object> _bundle = HashMap();

  void _put(String key, Object value) {
    _bundle[key] = value;
  }

  Object _get(String key, Object defaultValue) {
    return _bundle[key] ?? defaultValue;
  }

  T get<T extends Object>(String key, T defaultValue) {
    return _get(key, defaultValue) as T;
  }

  int getInt(String key, {int defaultValue = -1}) {
    return _get(key, defaultValue) as int;
  }

  String getString(String key, {String defaultValue = ''}) {
    return _get(key, defaultValue) as String;
  }

  void put<T extends Object>(String key, T value) {
    _put(key, value);
  }

  void putInt(String key, int value) {
    _put(key, value);
  }

  void putString(String key, String value) {
    _put(key, value);
  }

  Map<String, Object> flatten() {
    return HashMap.from(_bundle);
  }
}
