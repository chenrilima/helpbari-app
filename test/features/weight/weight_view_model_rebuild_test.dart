import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/meals/presentation/providers/meal_view_model_provider.dart';
import 'package:helpbari/features/water/presentation/providers/water_view_model_provider.dart';
import 'package:helpbari/features/weight/presentation/providers/weight_view_model_provider.dart';

void main() {
  test('sync consumers can rebuild after provider invalidation', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(weightViewModelProvider);
    container.read(waterViewModelProvider);
    container.read(mealViewModelProvider);

    container.invalidate(weightViewModelProvider);
    container.invalidate(waterViewModelProvider);
    container.invalidate(mealViewModelProvider);

    expect(container.read(weightViewModelProvider).isLoading, isFalse);
    expect(container.read(waterViewModelProvider).isLoading, isFalse);
    expect(container.read(mealViewModelProvider).isLoading, isFalse);
  });
}
