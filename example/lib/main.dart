import 'package:flutter/material.dart';
import 'package:async_wrapper/async_wrapper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AsyncWrapper Example',
      home: AsyncWrapperExample(),
    );
  }
}

class AsyncWrapperExample extends StatelessWidget {
  Future<String> _fetchData() async {
    await Future.delayed(Duration(seconds: 2));
    if (DateTime.now().millisecond % 2 == 0) {
      throw Exception('Random error occurred!');
    }
    return 'Data loaded successfully!';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AsyncWrapper Example')),
      body: Center(
        child: AsyncWrapper<String>(
          fetch: _fetchData,
          builder: (trigger, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.isPending)
                  CircularProgressIndicator()
                else if (state.isError)
                  Text('Error: ${state.error}',
                      style: TextStyle(color: Colors.red))
                else if (state.isSuccess)
                  Text(state.data!, style: TextStyle(color: Colors.green)),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: state.isPending ? null : trigger,
                  child: Text('Fetch Data'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
