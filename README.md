# async_wrapper

A generic stateful Flutter widget that simplifies handling asynchronous operations with loading, success, and error states using a builder pattern.

## Features

- ✅ Trigger async operations from your widget
- 🔄 Automatically run on init with `autorun`
- ⚠️ Handles errors gracefully
- 🧱 Provides clear `AsyncState<T>` with `pending`, `success`, `error`, or `stale` states
- 🔧 Supports lifecycle hooks: `onSuccess` and `onError`
- ♻️ Prevents overlapping requests (configurable)

---

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  async_wrapper: ^1.0.0
```
