abstract class Repository<T> {
  Future<List<T>> load(List<int> ids);
  Future<List<T>> loadAll();
  Future<int> save(List<T> objs);
  Future<int> delete(List<T> objs);
}
