import 'sync_operation.dart';

class SyncQueue {
  SyncQueue([Iterable<SyncOperation> operations = const []])
    : _operations = List.of(operations);

  final List<SyncOperation> _operations;

  bool get isEmpty => _operations.isEmpty;

  int get length => _operations.length;

  List<SyncOperation> get operations => List.unmodifiable(_operations);

  void add(SyncOperation operation) {
    _operations.add(operation);
  }

  void addAll(Iterable<SyncOperation> operations) {
    _operations.addAll(operations);
  }

  SyncOperation? next() {
    if (_operations.isEmpty) return null;
    return _operations.removeAt(0);
  }

  void clear() {
    _operations.clear();
  }
}
