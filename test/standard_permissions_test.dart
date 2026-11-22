import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_ohos/permission_handler_ohos.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.harmonycandies.permission_handler_ohos');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(PermissionHandlerOhos.registerWith);
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('standard camera request reaches OHOS and refresh reads the grant',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'requestPermissions');
      expect(call.arguments, ['ohos.permission.CAMERA']);
      return {'ohos.permission.CAMERA': 0};
    });
    expect(
        await PermissionHandlerPlatform.instance
            .requestPermissions([Permission.camera]),
        {Permission.camera: PermissionStatus.granted});
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'checkPermissionStatus');
      expect(call.arguments, 'ohos.permission.CAMERA');
      return 0;
    });
    expect(
        await PermissionHandlerPlatform.instance
            .checkPermissionStatus(Permission.camera),
        PermissionStatus.granted);
  });

  test('microphone refusal remains denied through standard API', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'requestPermissions');
      expect(call.arguments, ['ohos.permission.MICROPHONE']);
      return {'ohos.permission.MICROPHONE': -1};
    });
    expect(
        await PermissionHandlerPlatform.instance
            .requestPermissions([Permission.microphone]),
        {Permission.microphone: PermissionStatus.denied});
  });

  test('native errors complete the request with an error', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
          code: '12100001', message: 'Undeclared permission');
    });
    await expectLater(
      PermissionHandlerPlatform.instance
          .requestPermissions([Permission.camera]),
      throwsA(isA<PlatformException>()),
    );
  });

  test('notification refusal is not reported as granted', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'requestNotificationPermission');
      return false;
    });
    expect(
        await PermissionHandlerPlatform.instance
            .requestPermissions([Permission.notification]),
        {Permission.notification: PermissionStatus.denied});
  });

  test('system granted reminder permission is checked without a runtime prompt',
      () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'checkPermissionStatus');
      expect(call.arguments, 'ohos.permission.PUBLISH_AGENT_REMINDER');
      return 0;
    });
    expect(
        await PermissionHandlerPlatform.instance
            .requestPermissions([Permission.scheduleExactAlarm]),
        {Permission.scheduleExactAlarm: PermissionStatus.granted});
  });

  test('Android battery exemption has no OHOS runtime equivalent', () async {
    expect(
        await PermissionHandlerPlatform.instance
            .requestPermissions([Permission.ignoreBatteryOptimizations]),
        {Permission.ignoreBatteryOptimizations: PermissionStatus.restricted});
  });
}
