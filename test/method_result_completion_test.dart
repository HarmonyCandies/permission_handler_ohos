// Host-runnable (no Harmony device):
//   dart test/method_result_completion_test.dart
//
// Verifies that success and catch map to a completed MethodResult outcome
// and never [MethodResultKind.none] (the hang).

import '../lib/src/method_result_completion.dart';

void main() {
  const MethodResultCompletion completion = MethodResultCompletion();
  int passed = 0;

  void check(bool condition, String name) {
    if (!condition) {
      throw StateError('FAIL: $name');
    }
    passed++;
  }

  // Legacy catch that only logs would stay pending:
  const MethodResultOutcome hang = MethodResultOutcome.none();
  check(!hang.isCompleted, 'none is the hang sentinel');
  check(hang.kind == MethodResultKind.none, 'none kind');

  final MethodResultOutcome settingsOk =
      completion.openAppSettings(succeeded: true);
  check(settingsOk.isCompleted, 'openAppSettings success completes');
  check(settingsOk.kind == MethodResultKind.success,
      'openAppSettings success kind');
  check(settingsOk.value == true, 'openAppSettings success is true');

  // Plus plugin contract: failure to open settings is false, not a hang.
  final MethodResultOutcome settingsCatch =
      completion.openAppSettings(succeeded: false);
  check(settingsCatch.isCompleted, 'openAppSettings catch completes');
  check(settingsCatch.kind != MethodResultKind.none,
      'openAppSettings catch is never none');
  check(settingsCatch.kind == MethodResultKind.success,
      'openAppSettings catch uses success(false)');
  check(settingsCatch.value == false, 'openAppSettings catch is false');

  final Map<String, int> grants = <String, int>{'ohos.permission.CAMERA': 0};
  final MethodResultOutcome requestOk = completion.requestPermissions(
    succeeded: true,
    results: grants,
  );
  check(requestOk.isCompleted, 'requestPermissions success completes');
  check(requestOk.kind == MethodResultKind.success,
      'requestPermissions success kind');
  check(requestOk.value == grants, 'requestPermissions success value');

  final MethodResultOutcome requestCatch = completion.requestPermissions(
    succeeded: false,
    errorCode: 201,
    errorMessage: 'denied',
  );
  check(requestCatch.isCompleted, 'requestPermissions catch completes');
  check(requestCatch.kind != MethodResultKind.none,
      'requestPermissions catch is never none');
  check(requestCatch.kind == MethodResultKind.error,
      'requestPermissions catch uses error');
  check(requestCatch.code == '201', 'requestPermissions catch code');
  check(requestCatch.message == 'denied', 'requestPermissions catch message');

  // Both methods: every success/catch pair is completed.
  final List<MethodResultOutcome> paths = <MethodResultOutcome>[
    completion.openAppSettings(succeeded: true),
    completion.openAppSettings(succeeded: false),
    completion.requestPermissions(succeeded: true, results: <String, int>{}),
    completion.requestPermissions(succeeded: false, errorCode: '103'),
  ];
  for (int i = 0; i < paths.length; i++) {
    check(paths[i].isCompleted, 'path $i must complete MethodResult');
    check(paths[i].kind != MethodResultKind.none, 'path $i is never none');
  }

  print('All $passed checks passed');
}
