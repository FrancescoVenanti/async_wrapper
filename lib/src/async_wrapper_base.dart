import 'package:flutter/material.dart';

/// A typedef for an asynchronous function that returns a value of type [T].
typedef AsyncCallback<T> = Future<T> Function();

/// A typedef for a builder function that provides:
/// - [AsyncCallback<void>] to trigger the async call
/// - [AsyncState<T>] representing the current fetch state
typedef AsyncBuilder<T> = Widget Function(AsyncCallback<void>, AsyncState<T>);

/// ## AsyncWrapper
/// A generic stateful widget that handles loading, success, and error states
/// during asynchronous operations.
///
/// ### Features:
/// - Triggers an async operation via [fetch]
/// - Provides loading/error/success states via [AsyncState]
/// - Exposes lifecycle hooks [onSuccess] and [onError]
/// - Optionally runs automatically on init via [autorun]
///
/// ### Usage:
/// ```dart
/// AsyncWrapper<bool>(
///   fetch: () async => await api.checkStatus(),
///   builder: (run, state) {
///     if (state.isPending) return CircularProgressIndicator();
///     return ElevatedButton(
///       onPressed: run,
///       child: Text(state.isSuccess ? 'Connected' : 'Check Connection'),
///     );
///   },
/// )
/// ```
class AsyncWrapper<T> extends StatefulWidget {
  /// The asynchronous operation to execute.
  final AsyncCallback<T> fetch;

  /// The builder function that receives:
  /// - the async trigger function
  /// - the current [AsyncState<T>]
  final AsyncBuilder<T> builder;

  /// If true, the async operation runs automatically on widget initialization.
  final bool autorun;

  /// if true, the component will execute the fetch even while pending.
  final bool multipleFetch;

  /// Optional callback called on successful result.
  final Function(T, AsyncCallback<void>)? onSuccess;

  /// Optional callback called when an error is caught.
  final Function(Object?, AsyncCallback<void>)? onError;

  const AsyncWrapper(
      {super.key,
      required this.fetch,
      required this.builder,
      this.onSuccess,
      this.onError,
      this.autorun = false,
      this.multipleFetch = false});

  @override
  State<AsyncWrapper<T>> createState() => _AsyncWrapperState<T>();
}

class _AsyncWrapperState<T> extends State<AsyncWrapper<T>> {
  /// Holds the current async operation state (loading, success, error, etc.)
  AsyncState<T> state = AsyncState.stale();

  /// Default async trigger function:
  /// - updates internal state to pending
  /// - runs [widget.fetch]
  /// - handles success/error state updates
  /// - invokes [onSuccess] or [onError] if provided
  Future<void> _defaultAsync() async {
    if (state.isPending && !widget.multipleFetch) return;
    try {
      setState(() {
        state = AsyncState.pending();
      });
      final res = await widget.fetch();
      setState(() {
        state = AsyncState.success(res);
      });
      if (widget.onSuccess != null) widget.onSuccess!(res, _defaultAsync);
    } catch (e) {
      setState(() {
        state = AsyncState.error(e);
      });
      if (widget.onError != null) widget.onError!(e, _defaultAsync);
    }
  }

  @override
  void initState() {
    super.initState();
    // Automatically triggers the async call on init if enabled
    if (widget.autorun) _defaultAsync();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      _defaultAsync,
      state,
    );
  }
}

/// Describes the lifecycle of an asynchronous operation.
enum LoadState { stale, pending, success, error }

/// A typed wrapper around async state with optional data and error values.
class AsyncState<T> {
  final LoadState state;
  final T? data;
  final Object? error;

  const AsyncState.stale()
      : state = LoadState.stale,
        data = null,
        error = null;

  const AsyncState.pending()
      : state = LoadState.pending,
        data = null,
        error = null;

  const AsyncState.success(this.data)
      : state = LoadState.success,
        error = null;

  const AsyncState.error(this.error)
      : state = LoadState.error,
        data = null;

  /// Returns true if the fetch hasn't started yet.
  bool get stale => state == LoadState.stale;

  /// Returns true if the fetch is ongoing.
  bool get isPending => state == LoadState.pending;

  /// Returns true if fetched succesfully.
  bool get isSuccess => state == LoadState.success;

  /// Returns true if there was an error while fetching.
  bool get isError => state == LoadState.error;
}
