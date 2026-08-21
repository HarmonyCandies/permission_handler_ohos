/// How a Flutter `MethodResult` should be completed.
///
/// Native `Promise` catch paths that only `console.error` leave [none],
/// which never replies on the method channel and hangs the Dart `Future`.
enum MethodResultKind {
  /// MethodResult was never completed (Dart Future hangs).
  none,

  /// `result.success(...)`.
  success,

  /// `result.error(...)`.
  error,
}

/// A completed (or still-pending) method-channel reply.
class MethodResultOutcome {
  const MethodResultOutcome({
    required this.kind,
    this.value,
    this.code,
    this.message,
    this.details,
  });

  const MethodResultOutcome.success(this.value)
      : kind = MethodResultKind.success,
        code = null,
        message = null,
        details = null;

  const MethodResultOutcome.error(this.code, this.message, [this.details])
      : kind = MethodResultKind.error,
        value = null;

  const MethodResultOutcome.none()
      : kind = MethodResultKind.none,
        value = null,
        code = null,
        message = null,
        details = null;

  final MethodResultKind kind;
  final Object? value;
  final String? code;
  final String? message;
  final Object? details;

  /// Every native then/catch path must produce a completed outcome.
  bool get isCompleted => kind != MethodResultKind.none;
}

/// Maps native Promise then/catch into a completed [MethodResultOutcome].
///
/// Host-testable stand-in for the catch-path policy in
/// `PermissionHandlerOhosPlugin.ets`.
class MethodResultCompletion {
  const MethodResultCompletion();

  /// `openAppSettings` matches permission_handler (plus): `true` if settings
  /// opened, `false` if `startAbility` failed. Never [MethodResultKind.none].
  MethodResultOutcome openAppSettings({required bool succeeded}) {
    return MethodResultOutcome.success(succeeded);
  }

  /// `requestPermissions` replies with the grant map on success, or
  /// `result.error` on `requestPermissionsFromUser` failure so the Dart
  /// Future completes instead of hanging.
  MethodResultOutcome requestPermissions({
    required bool succeeded,
    Object? results,
    Object? errorCode,
    String? errorMessage,
  }) {
    if (succeeded) {
      return MethodResultOutcome.success(results);
    }
    return MethodResultOutcome.error(
      errorCode == null ? '103' : errorCode.toString(),
      errorMessage ?? 'requestPermissionsFromUser failed',
    );
  }
}
