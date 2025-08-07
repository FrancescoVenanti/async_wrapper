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

  /// Creates an [AsyncWrapper] widget.
  const AsyncWrapper({
    super.key,
    required this.fetch,
    required this.builder,
    this.onSuccess,
    this.onError,
    this.autorun = false,
    this.multipleFetch = false,
  });

  @override
  State<AsyncWrapper<T>> createState() => _AsyncWrapperState<T>();
}

/// The internal state class for [AsyncWrapper].
class _AsyncWrapperState<T> extends State<AsyncWrapper<T>> {
  /// Holds the current async operation state (loading, success, error, etc.)
  AsyncState<T> state = const AsyncState.stale();

  /// Default async trigger function:
  /// - updates internal state to pending
  /// - runs [widget.fetch]
  /// - handles success/error state updates
  /// - invokes [onSuccess] or [onError] if provided
  Future<void> _defaultAsync() async {
    if (state.isPending && !widget.multipleFetch) return;
    try {
      _changeState(const AsyncState.pending());
      final res = await widget.fetch();
      _changeState(AsyncState.success(res));
      if (widget.onSuccess != null) widget.onSuccess!(res, _defaultAsync);
    } catch (e) {
      _changeState(AsyncState.error(e));
      if (widget.onError != null) widget.onError!(e, _defaultAsync);
    }
  }

  void _changeState(AsyncState<T> newState) {
    if (!mounted || !context.mounted) return;
    setState(() => state = newState);
  }

  @override
  void initState() {
    super.initState();
    // Automatically triggers the async call on init if enabled
    if (widget.autorun) _defaultAsync();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_defaultAsync, state);
  }
}

/// Describes the lifecycle of an asynchronous operation.
enum LoadState {
  /// The initial state before any operation has been started.
  stale,

  /// The operation is currently in progress.
  pending,

  /// The operation completed successfully.
  success,

  /// The operation failed with an error.
  error,
}

/// A typed wrapper around async state with optional data and error values.
class AsyncState<T> {
  /// The current state of the async operation.
  final LoadState state;

  /// The data returned from a successful operation, if any.
  final T? data;

  /// The error that occurred during the operation, if any.
  final Object? error;

  /// Creates a stale [AsyncState] indicating no operation has started.
  const AsyncState.stale() : state = LoadState.stale, data = null, error = null;

  /// Creates a pending [AsyncState] indicating an operation is in progress.
  const AsyncState.pending()
    : state = LoadState.pending,
      data = null,
      error = null;

  /// Creates a success [AsyncState] with the given [data].
  const AsyncState.success(this.data) : state = LoadState.success, error = null;

  /// Creates an error [AsyncState] with the given [error].
  const AsyncState.error(this.error) : state = LoadState.error, data = null;

  /// Returns true if the fetch hasn't started yet.
  bool get stale => state == LoadState.stale;

  /// Returns true if the fetch is ongoing.
  bool get isPending => state == LoadState.pending;

  /// Returns true if fetched successfully.
  bool get isSuccess => state == LoadState.success;

  /// Returns true if there was an error while fetching.
  bool get isError => state == LoadState.error;
}
