import 'package:flutter_test/flutter_test.dart';
import 'package:async_wrapper/async_wrapper.dart';

void main() {
  group('AsyncState', () {
    test('should create stale state', () {
      final state = AsyncState<String>.stale();
      expect(state.stale, isTrue);
      expect(state.isPending, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isError, isFalse);
    });

    test('should create pending state', () {
      final state = AsyncState<String>.pending();
      expect(state.isPending, isTrue);
      expect(state.stale, isFalse);
    });

    test('should create success state with data', () {
      final state = AsyncState<String>.success('test data');
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
}
