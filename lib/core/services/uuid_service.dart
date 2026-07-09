import 'package:uuid/uuid.dart';

abstract interface class UuidService {
  String generate();
}

class AppUuidService implements UuidService {
  const AppUuidService();

  static const _uuid = Uuid();

  @override
  String generate() {
    return _uuid.v4();
  }
}
