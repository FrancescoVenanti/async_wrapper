import 'package:flutter_test/flutter_test.dart';
import 'package:async_wrapper/async_wrapper.dart';

void main() {
  group('AsyncState', () {
    test('should create stale state', () {
      const state = AsyncState<String>.stale();
      expect(state.isStale, isTrue);
      expect(state.isPending, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isFalse);
    });

    test('should create pending state', () {
      const state = AsyncState<String>.pending();
      expect(state.isPending, isTrue);
      expect(state.isStale, isFalse);
    });

    test('should create success state with data', () {
      const state = AsyncState<String>.success('test data');
      expect(state.isSuccess, isTrue);
      expect(state.data, equals('test data'));
    });

    test('should create error state', () {
      final error = Exception('test error');
      final state = AsyncState<String>.error(error);
      expect(state.isError, isTrue);
      expect(state.error, equals(error));
    });
  });

  // group('LoadState', () {
  //   test('should have all expected states', () {
  //     expect(LoadState.values, hasLength(4));
  //     expect(LoadState.values, contains(LoadState.stale));
  //     expect(LoadState.values, contains(LoadState.pending));
  //     expect(LoadState.values, contains(LoadState.success));
  //     expect(LoadState.values, contains(LoadState.error));
  //   });
  // });
}
