import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppProgressState extends Equatable {
  final int runningCount;

  final double? value;

  const AppProgressState({this.runningCount = 0, this.value});

  bool get isActive => value != null || runningCount > 0;
  bool get isDeterminate => value != null;

  AppProgressState copyWith({
    int? runningCount,
    double? value,
    bool clearValue = false,
  }) {
    return AppProgressState(
      runningCount: runningCount ?? this.runningCount,
      value: clearValue ? null : (value ?? this.value),
    );
  }

  @override
  List<Object?> get props => [runningCount, value];
}

/// App-wide progress signal, rendered as the thin line beneath the main app
/// bar (see `AppProgressLine`). Any screen, bloc, or service can switch it on
/// or off.
///
/// Concurrent callers are reference-counted, so the line only disappears once
/// the last task finishes. Registered as a singleton in `getIt`, so it is
/// reachable from anywhere without prop-drilling:
///
/// ```dart
/// final token = getIt<AppProgressCubit>().start();
/// // ... work ...
/// getIt<AppProgressCubit>().stop(token);
///
/// // or, simplest:
/// await getIt<AppProgressCubit>().run(() => repo.fetch());
///
/// // or drive it from a bloc's loading state:
/// getIt<AppProgressCubit>().track('products', loading: state.isLoading);
/// ```
class AppProgressCubit extends Cubit<AppProgressState> {
  AppProgressCubit() : super(const AppProgressState());

  final Set<Object> _tokens = <Object>{};

  /// Start an indeterminate task. Pass a stable [id] (e.g. `'products'`) to
  /// pair with [stop], or omit it to receive a token you hold and pass to
  /// [stop] yourself.
  Object start([Object? id]) {
    final token = id ?? Object();
    _tokens.add(token);
    emit(state.copyWith(runningCount: _tokens.length, clearValue: true));
    return token;
  }

  /// Stop a task previously started with [start] (matched by identity / id).
  void stop(Object id) {
    if (_tokens.remove(id)) {
      emit(state.copyWith(runningCount: _tokens.length));
    }
  }

  /// Drive [start]/[stop] from a boolean — handy in a `BlocListener` that maps
  /// `status == loading`. Idempotent for a given [id].
  void track(Object id, {required bool loading}) {
    if (loading) {
      if (_tokens.add(id)) {
        emit(state.copyWith(runningCount: _tokens.length, clearValue: true));
      }
    } else {
      stop(id);
    }
  }

  /// Set determinate progress 0.0–1.0 (uploads, batch sync with known totals).
  /// Call [clearValue] when finished.
  void setValue(double value) {
    emit(state.copyWith(value: value.clamp(0.0, 1.0)));
  }

  /// Clear determinate progress and fall back to idle (or any still-running
  /// indeterminate tasks).
  void clearValue() => emit(state.copyWith(clearValue: true));

  /// Wrap an async task so the bar shows for its full duration, even if it
  /// throws.
  Future<T> run<T>(Future<T> Function() task, {Object? id}) async {
    final token = start(id);
    try {
      return await task();
    } finally {
      stop(token);
    }
  }

  /// Force-clear everything (e.g. on logout / session reset).
  void reset() {
    _tokens.clear();
    emit(const AppProgressState());
  }
}