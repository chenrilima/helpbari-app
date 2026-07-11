import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/home/presentation/providers/home_view_model_provider.dart';

void main() {
  test('HomeViewModel can rebuild after provider invalidation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(homeViewModelProvider).isLoading, isFalse);

    container.invalidate(homeViewModelProvider);

    expect(container.read(homeViewModelProvider).isLoading, isFalse);
  });
}
