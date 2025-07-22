# AsyncWrapper

A lightweight Flutter package that simplifies async state management by providing built-in loading, success, and error states for asynchronous operations.

## Features

- 🔄 **Automatic state management** - Handles loading, success, and error states
- 🚀 **Easy to use** - Wrap any async operation with minimal boilerplate
- 🎯 **Type-safe** - Generic implementation with full type support
- ⚡ **Flexible** - Supports autorun, multiple fetches, and lifecycle callbacks
- 🎨 **Reactive UI** - Rebuild widgets based on async state changes

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  async_wrapper: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Example

```dart
import 'package:async_wrapper/async_wrapper.dart';

AsyncWrapper<String>(
  fetch: () async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 2));
    return "Hello, World!";
  },
  builder: (trigger, state) {
    if (state.isPending) {
      return CircularProgressIndicator();
    }

    if (state.isError) {
      return Text('Error: ${state.error}');
    }

    if (state.isSuccess) {
      return Text('Result: ${state.data}');
    }

    return ElevatedButton(
      onPressed: trigger,
      child: Text('Start Async Operation'),
    );
  },
)
```

### API Status Check Example

```dart
AsyncWrapper<bool>(
  autorun: true, // Automatically runs on initialization
  fetch: () async => await apiService.checkConnection(),
  onSuccess: (isConnected, retry) {
    if (isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to server!')),
      );
    }
  },
  onError: (error, retry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connection failed: $error')),
    );
  },
  builder: (checkConnection, state) {
    return Column(
      children: [
        if (state.isPending)
          CircularProgressIndicator()
        else
          Icon(
            state.isSuccess && state.data == true
              ? Icons.wifi
              : Icons.wifi_off,
            color: state.isSuccess && state.data == true
              ? Colors.green
              : Colors.red,
          ),
        ElevatedButton(
          onPressed: state.isPending ? null : checkConnection,
          child: Text('Check Connection'),
        ),
      ],
    );
  },
)
```

### User Profile Example

```dart
class UserProfile extends StatelessWidget {
  final String userId;

  const UserProfile({required this.userId});

  @override
  Widget build(BuildContext context) {
    return AsyncWrapper<User>(
      autorun: true,
      fetch: () => userRepository.fetchUser(userId),
      builder: (refetch, state) {
        return RefreshIndicator(
          onRefresh: refetch,
          child: ListView(
            children: [
              if (state.isPending && state.data == null)
                Center(child: CircularProgressIndicator())
              else if (state.isError)
                ErrorWidget(
                  error: state.error.toString(),
                  onRetry: refetch,
                )
              else if (state.isSuccess && state.data != null)
                UserCard(user: state.data!)
              else
                EmptyState(onRefresh: refetch),
            ],
          ),
        );
      },
    );
  }
}
```

## API Reference

### AsyncWrapper Properties

| Property        | Type                                      | Description                                   | Default      |
| --------------- | ----------------------------------------- | --------------------------------------------- | ------------ |
| `fetch`         | `AsyncCallback<T>`                        | The async operation to execute                | **required** |
| `builder`       | `AsyncBuilder<T>`                         | Builder function receiving trigger and state  | **required** |
| `autorun`       | `bool`                                    | Auto-execute fetch on initialization          | `false`      |
| `multipleFetch` | `bool`                                    | Allow multiple concurrent fetches             | `false`      |
| `onSuccess`     | `Function(T, AsyncCallback<void>)?`       | Success callback with data and retry function | `null`       |
| `onError`       | `Function(Object?, AsyncCallback<void>)?` | Error callback with error and retry function  | `null`       |

### AsyncState Properties

| Property | Type        | Description                                    |
| -------- | ----------- | ---------------------------------------------- |
| `state`  | `LoadState` | Current state (stale, pending, success, error) |
| `data`   | `T?`        | Success data (null if not successful)          |
| `error`  | `Object?`   | Error object (null if no error)                |

### AsyncState Getters

| Getter      | Type   | Description                          |
| ----------- | ------ | ------------------------------------ |
| `stale`     | `bool` | True if fetch hasn't started         |
| `isPending` | `bool` | True if fetch is in progress         |
| `isSuccess` | `bool` | True if fetch completed successfully |
| `isError`   | `bool` | True if fetch resulted in error      |

### LoadState Enum

```dart
enum LoadState { stale, pending, success, error }
```

## Advanced Usage

### Multiple Fetch Operations

```dart
AsyncWrapper<String>(
  multipleFetch: true, // Allows concurrent operations
  fetch: () => apiService.fetchData(),
  builder: (trigger, state) {
    return ElevatedButton(
      onPressed: trigger, // Can be called even while pending
      child: state.isPending
        ? CircularProgressIndicator()
        : Text('Fetch Data'),
    );
  },
)
```

### State Persistence During Updates

```dart
AsyncWrapper<List<Item>>(
  fetch: () => repository.fetchItems(),
  builder: (refresh, state) {
    // Show previous data while refreshing
    final items = state.data ?? [];

    return Column(
      children: [
        if (state.isPending && items.isEmpty)
          CircularProgressIndicator()
        else if (state.isPending)
          LinearProgressIndicator(), // Show loading bar during refresh

        if (state.isError && items.isEmpty)
          ErrorMessage(error: state.error, onRetry: refresh)
        else
          ItemList(items: items, onRefresh: refresh),
      ],
    );
  },
)
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
