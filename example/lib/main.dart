import 'package:flutter/material.dart';
import 'package:async_wrapper/async_wrapper.dart';

/// The main entry point of the example application.
void main() {
  runApp(const MyApp());
}

/// The root widget of the example application.
class MyApp extends StatelessWidget {
  /// Creates a [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AsyncWrapper Example',
      home: AsyncWrapperExample(),
    );
  }
}

/// A widget demonstrating the usage of [AsyncWrapper].
class AsyncWrapperExample extends StatelessWidget {
  /// Creates an [AsyncWrapperExample] widget.
  const AsyncWrapperExample({super.key});

  /// Simulates an async data fetch operation.
  Future<String> _fetchData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (DateTime.now().millisecond % 2 == 0) {
      throw Exception('Random error occurred!');
    }
    return 'Data loaded successfully!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AsyncWrapper Example')),
      body: Center(
        child: AsyncWrapper<String>(
          fetch: _fetchData,
          builder: (trigger, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.isPending)
                  const CircularProgressIndicator()
                else if (state.isError)
                  Text('Error: ${state.error}',
                      style: const TextStyle(color: Colors.red))
                else if (state.isSuccess)
                  Text(state.data!,
                      style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: state.isPending ? null : trigger,
                  child: const Text('Fetch Data'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
