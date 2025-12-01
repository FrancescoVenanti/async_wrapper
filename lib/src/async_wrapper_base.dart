import 'package:flutter/material.dart';

/// A typedef for an asynchronous function that returns a value of type [T].
typedef AsyncCallback<T> = Future<T> Function();

/// A typedef for a builder function that receives the current [AsyncState<T>].
typedef AsyncBuilder<T> = Widget Function(AsyncState<T>, AsyncController<T>);

/// A typedef for success callback that receives the result and a refetch function.
typedef OnSuccessCallback<T> = void Function(T, AsyncController<T>);

/// A typedef for error callback that receives the error and a refetch function.
typedef OnErrorCallback<T> = void Function(Object, AsyncController<T>);

/// Controller for managing async operations in [AsyncWrapper].
///
/// This controller allows you to trigger async operations from outside
/// the widget tree.
///
/// **Important**: Each controller should be used with exactly one [AsyncWrapper].
/// Attempting to attach multiple wrappers will throw an exception.
///
/// ### Example:
/// ```dart
/// final controller = AsyncController<User>(
///   () => userRepository.getCurrentUser(),
/// );
///
/// // Later, trigger the fetch from anywhere
/// controller.fetch();
/// ```
class AsyncController<T> {
  /// Construct the [AsyncController].
  AsyncController(AsyncCallback<T> callback) : _future = callback;

  /// The async operation to execute.
  final AsyncCallback<T> _future;

  VoidCallback? _onFetch;
  bool _isDisposed = false;

  /// Triggers the async operation.
  ///
  /// Throws [StateError] if the controller is not attached to a widget
  /// or if the controller has been disposed.
  void fetch() {
    if (_isDisposed) {
      throw StateError('Cannot call fetch() on a disposed AsyncController');
    }
    if (_onFetch == null) {
      throw StateError(
        'AsyncController is not attached to any AsyncWrapper. '
        'Make sure the AsyncWrapper is mounted before calling fetch().',
      );
    }
    _onFetch!();
  }

  /// Internal method to attach the controller to a widget.
  void _attach(VoidCallback callback) {
    if (_isDisposed) {
      throw StateError('Cannot attach a disposed AsyncController');
    }
    if (_onFetch != null) {
      throw StateError(
        'AsyncController is already attached to another AsyncWrapper. '
        'Each controller can only be used with one AsyncWrapper at a time.',
      );
    }
    _onFetch = callback;
  }

  /// Internal method to detach the controller from a widget.
  void _detach() {
    _onFetch = null;
  }

  /// Disposes the controller and prevents further use.
  ///
  /// Call this when the controller is no longer needed to prevent memory leaks.
  void dispose() {
    _isDisposed = true;
    _onFetch = null;
  }

  /// Whether this controller has been disposed.
  bool get isDisposed => _isDisposed;

  /// Whether this controller is currently attached to a widget.
  bool get isAttached => _onFetch != null && !_isDisposed;
}

/// A generic stateful widget that handles loading, success, and error states
/// during asynchronous operations.
///
/// ### Features:
/// - Automatic state management (stale → pending → success/error)
/// - External triggering via [AsyncController]
/// - Lifecycle hooks ([onSuccess], [onError])
/// - Auto-run on initialization
/// - Prevents duplicate requests (configurable via [allowConcurrent])
///
/// ### Basic Usage with Controller:
/// ```dart
/// final controller = AsyncController<bool>(
///   () => api.checkStatus(),
/// );
///
/// AsyncWrapper<bool>(
///   controller: controller,
///   builder: (state) {
///     if (state.isPending) {
///       return CircularProgressIndicator();
///     }
///     if (state.isError) {
///       return Text('Error: ${state.error}');
///     }
///     if (state.isSuccess) {
///       return Text('Status: ${state.data}');
///     }
///     return ElevatedButton(
///       onPressed: controller.fetch,
///       child: Text('Check Status'),
///     );
///   },
/// )
/// ```
///
/// ### Basic Usage without Controller:
/// ```dart
/// AsyncWrapper<User>(
///   future: () => api.getCurrentUser(),
///   autorun: true,
///   builder: (state) {
///     return state.when(
///       stale: () => Text('Not loaded'),
///       pending: () => CircularProgressIndicator(),
///       success: (user) => Text('Hello ${user.name}'),
///       error: (error, _) => Text('Error: $error'),
///     );
///   },
/// )
/// ```
///
/// ### With Callbacks:
/// ```dart
/// AsyncWrapper<User>(
///   future: () => api.getCurrentUser(),
///   autorun: true,
///   onSuccess: (user) {
///     print('Loaded user: ${user.name}');
///   },
///   onError: (error, stackTrace) {
///     print('Failed to load user: $error');
///   },
///   builder: (state) => UserProfile(state: state),
/// )
/// ```
class AsyncWrapper<T> extends StatefulWidget {
  /// Controller that manages the async operation.
  final AsyncController<T> controller;

  /// Builder function that receives the current async state.
  final AsyncBuilder<T> builder;

  /// If true, the async operation runs automatically on widget initialization.
  ///
  /// Defaults to `false`.
  final bool autorun;

  /// If true, allows multiple concurrent fetch operations.
  ///
  /// When `false` (default), subsequent fetch calls while a request is pending
  /// will be ignored.
  final bool allowConcurrent;

  /// Optional callback invoked when the async operation succeeds.
  ///
  /// Receives:
  /// - `data`: The successful result
  final OnSuccessCallback<T>? onSuccess;

  /// Optional callback invoked when the async operation fails.
  ///
  /// Receives:
  /// - `error`: The error object
  /// - `stackTrace`: The stack trace where the error occurred
  final OnErrorCallback? onError;

  /// Indicates whether the controller was created internally and should be
  /// disposed when the widget is disposed.
  final bool _disposeController;

  /// Creates an [AsyncWrapper] with an explicit controller.
  ///
  /// Use this constructor when you need to trigger the fetch operation
  /// from outside the widget tree.
  ///
  /// ### Example:
  /// ```dart
  /// final controller = AsyncController<User>(() => api.getUser());
  ///
  /// // In your widget tree
  /// AsyncWrapper(
  ///   controller: controller,
  ///   builder: (state) => UserWidget(state),
  /// )
  ///
  /// // Elsewhere in your code
  /// ElevatedButton(
  ///   onPressed: controller.fetch,
  ///   child: Text('Refresh'),
  /// )
  /// ```
  const AsyncWrapper({
    super.key,
    required this.controller,
    required this.builder,
    this.onSuccess,
    this.onError,
    this.autorun = false,
    this.allowConcurrent = false,
  }) : _disposeController = false;

  /// Creates an [AsyncWrapper] without an explicit controller.
  ///
  /// Use this constructor for simpler use cases where you don't need
  /// to trigger the fetch operation from outside the widget tree.
  ///
  /// A controller is created internally and disposed automatically.
  ///
  /// ### Example:
  /// ```dart
  /// AsyncWrapper<User>(
  ///   future: () => api.getUser(),
  ///   autorun: true,
  ///   builder: (state) => state.maybeWhen(
  ///     success: (user) => Text(user.name),
  ///     orElse: () => CircularProgressIndicator(),
  ///   ),
  /// )
  /// ```
  AsyncWrapper.future({
    super.key,
    required AsyncCallback<T> future,
    required this.builder,
    this.onSuccess,
    this.onError,
    this.autorun = false,
    this.allowConcurrent = false,
  })  : controller = AsyncController<T>(future),
        _disposeController = true;

  @override
  State<AsyncWrapper<T>> createState() => _AsyncWrapperState<T>();
}

class _AsyncWrapperState<T> extends State<AsyncWrapper<T>> {
  /// Current state of the async operation.
  AsyncState<T> _state = const AsyncState.stale();

  /// Tracks if a request is currently in progress.
  bool _isFetching = false;

  /// Executes the async operation and manages state transitions.
  Future<void> _executeFetch() async {
    // Prevent concurrent requests if not allowed
    if (_isFetching && !widget.allowConcurrent) {
      return;
    }

    _isFetching = true;
    _updateState(const AsyncState.pending());

    try {
      final result = await widget.controller._future();

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      _updateState(AsyncState.success(result));
      widget.onSuccess?.call(result, widget.controller);
    } catch (error, stackTrace) {
      // Check if widget is still mounted before updating state
      if (!mounted) return;

      _updateState(AsyncState.error(error, stackTrace));
      widget.onError?.call(error, widget.controller);
    } finally {
      _isFetching = false;
    }
  }

  /// Updates the state and triggers a rebuild if the widget is still mounted.
  void _updateState(AsyncState<T> newState) {
    if (!mounted) return;
    setState(() {
      _state = newState;
    });
  }

  @override
  void initState() {
    super.initState();
    widget.controller._attach(_executeFetch);
    if (widget.autorun) {
      // Schedule the fetch for after the first frame to avoid
      // calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _executeFetch();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller._detach();
    // Only dispose the controller if it was created internally
    if (widget._disposeController) {
      widget.controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(AsyncWrapper<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the controller changed, reattach to the new one
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      // Dispose old controller only if it was created internally
      if (oldWidget._disposeController) {
        oldWidget.controller.dispose();
      }
      widget.controller._attach(_executeFetch);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_state, widget.controller);
  }
}

/// Describes the lifecycle of an asynchronous operation.
enum AsyncStatus {
  /// Initial state before any fetch has been triggered.
  stale,

  /// A fetch operation is currently in progress.
  pending,

  /// The fetch completed successfully.
  success,

  /// The fetch failed with an error.
  error,
}

/// Represents the state of an asynchronous operation.
///
/// This class is immutable and provides type-safe access to the result
/// or error of an async operation.
@immutable
class AsyncState<T> {
  /// The current status of the async operation.
  final AsyncStatus status;

  /// The successful result, if [status] is [AsyncStatus.success].
  final T? data;

  /// The error object, if [status] is [AsyncStatus.error].
  final Object? error;

  /// The stack trace, if [status] is [AsyncStatus.error].
  final StackTrace? stackTrace;

  /// Creates a state representing an operation that hasn't started yet.
  const AsyncState.stale()
      : status = AsyncStatus.stale,
        data = null,
        error = null,
        stackTrace = null;

  /// Creates a state representing an operation in progress.
  const AsyncState.pending()
      : status = AsyncStatus.pending,
        data = null,
        error = null,
        stackTrace = null;

  /// Creates a state representing a successful operation.
  const AsyncState.success(this.data)
      : status = AsyncStatus.success,
        error = null,
        stackTrace = null;

  /// Creates a state representing a failed operation.
  const AsyncState.error(this.error, [this.stackTrace])
      : status = AsyncStatus.error,
        data = null;

  /// Returns true if the operation hasn't started yet.
  bool get isStale => status == AsyncStatus.stale;

  /// Returns true if the operation is currently in progress.
  bool get isPending => status == AsyncStatus.pending;

  /// Returns true if the operation completed successfully.
  bool get isSuccess => status == AsyncStatus.success;

  /// Returns true if the operation failed with an error.
  bool get isError => status == AsyncStatus.error;

  /// Returns true if the operation has completed (either success or error).
  bool get isComplete => isSuccess || isError;

  /// Returns the data if successful, otherwise throws [StateError].
  ///
  /// Use this when you're certain the state is successful, or when you
  /// want to explicitly handle the error case.
  T get requireData {
    if (isSuccess && data != null) {
      return data as T;
    }
    throw StateError(
      'Cannot access data when status is $status. '
      'Check isSuccess before accessing data.',
    );
  }

  /// Returns the error if failed, otherwise throws [StateError].
  ///
  /// Use this when you're certain the state is an error, or when you
  /// want to explicitly handle other cases.
  Object get requireError {
    if (isError && error != null) {
      return error!;
    }
    throw StateError(
      'Cannot access error when status is $status. '
      'Check isError before accessing error.',
    );
  }

  /// Executes a callback based on the current state.
  ///
  /// Exactly one callback will be executed based on the current status.
  ///
  /// ### Example:
  /// ```dart
  /// state.when(
  ///   stale: () => Text('Not loaded yet'),
  ///   pending: () => CircularProgressIndicator(),
  ///   success: (data) => Text('Result: $data'),
  ///   error: (error, stackTrace) => Text('Error: $error'),
  /// );
  /// ```
  R when<R>({
    required R Function() stale,
    required R Function() pending,
    required R Function(T data) success,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) {
    switch (status) {
      case AsyncStatus.stale:
        return stale();
      case AsyncStatus.pending:
        return pending();
      case AsyncStatus.success:
        return success(requireData);
      case AsyncStatus.error:
        return error(requireError, stackTrace);
    }
  }

  /// Executes a callback based on the current state, with optional handlers.
  ///
  /// Only the matching callback is executed. If a callback is not provided,
  /// [orElse] is called instead.
  ///
  /// ### Example:
  /// ```dart
  /// state.maybeWhen(
  ///   success: (data) => Text('Result: $data'),
  ///   orElse: () => Text('Loading or error...'),
  /// );
  /// ```
  R maybeWhen<R>({
    R Function()? stale,
    R Function()? pending,
    R Function(T data)? success,
    R Function(Object error, StackTrace? stackTrace)? error,
    required R Function() orElse,
  }) {
    switch (status) {
      case AsyncStatus.stale:
        return stale?.call() ?? orElse();
      case AsyncStatus.pending:
        return pending?.call() ?? orElse();
      case AsyncStatus.success:
        return success?.call(requireData) ?? orElse();
      case AsyncStatus.error:
        return error?.call(requireError, stackTrace) ?? orElse();
    }
  }

  @override
  String toString() {
    switch (status) {
      case AsyncStatus.stale:
        return 'AsyncState<$T>.stale()';
      case AsyncStatus.pending:
        return 'AsyncState<$T>.pending()';
      case AsyncStatus.success:
        return 'AsyncState<$T>.success($data)';
      case AsyncStatus.error:
        return 'AsyncState<$T>.error($error)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AsyncState<T> &&
        other.status == status &&
        other.data == data &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(status, data, error);
}

