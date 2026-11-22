import 'package:permission_handler_ohos/src/permission_status.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart'
    as standard;

import 'src/permission_handler_ohos_platform_interface.dart';

export 'src/permission_status.dart';
export 'src/permissions.dart';

class PermissionHandlerOhos {
  /// Registers the OpenHarmony implementation for the standard permission API.
  static void registerWith() {
    standard.PermissionHandlerPlatform.instance =
        _StandardPermissionHandlerOhos();
  }

  /// Checks the current status of the given [OhosPermission].
  static Future<PermissionStatusOhos> checkPermissionStatus(String permission) {
    return PermissionHandlerOhosPlatform.instance.checkPermissionStatus(
      permission,
    );
  }

  /// Opens the app settings page.
  ///
  /// Returns [true] if the app settings page could be opened, otherwise
  /// [false].
  static Future<bool> openAppSettings() {
    return PermissionHandlerOhosPlatform.instance.openAppSettings();
  }

  /// Requests the user for access to the supplied list of [OhosPermission]s, if
  /// they have not already been granted before.
  ///
  /// Returns a [Map] containing the status per requested [OhosPermission].
  static Future<Map<String, PermissionStatusOhos>> requestPermissions(
      List<String> permissions) {
    return PermissionHandlerOhosPlatform.instance
        .requestPermissions(permissions);
  }

  /// Request the user for access to the [OhosPermission], if
  /// it has not already been granted before.
  ///
  /// Returns a [PermissionStatusOhos] containing the status requested [OhosPermission].
  static Future<PermissionStatusOhos> requestPermission(
      String permission) async {
    final Map<String, PermissionStatusOhos> statusMap =
        await requestPermissions(<String>[permission]);
    return statusMap[permission] ?? PermissionStatusOhos.invalid;
  }
}

class _StandardPermissionHandlerOhos
    extends standard.PermissionHandlerPlatform {
  static const _channel =
      MethodChannel('com.harmonycandies.permission_handler_ohos');

  // Only permissions with an equivalent OpenHarmony contract are mapped.
  // Unsupported capabilities are restricted, never reported as authorized.
  static final _permissions = <standard.Permission, String>{
    standard.Permission.camera: 'ohos.permission.CAMERA',
    standard.Permission.microphone: 'ohos.permission.MICROPHONE',
    standard.Permission.location: 'ohos.permission.APPROXIMATELY_LOCATION',
    standard.Permission.locationWhenInUse:
        'ohos.permission.APPROXIMATELY_LOCATION',
    standard.Permission.locationAlways:
        'ohos.permission.LOCATION_IN_BACKGROUND',
    standard.Permission.bluetooth: 'ohos.permission.ACCESS_BLUETOOTH',
    standard.Permission.bluetoothScan: 'ohos.permission.ACCESS_BLUETOOTH',
    standard.Permission.bluetoothConnect: 'ohos.permission.ACCESS_BLUETOOTH',
    standard.Permission.bluetoothAdvertise: 'ohos.permission.ACCESS_BLUETOOTH',
    standard.Permission.activityRecognition: 'ohos.permission.ACTIVITY_MOTION',
    standard.Permission.calendarWriteOnly: 'ohos.permission.WRITE_CALENDAR',
    standard.Permission.scheduleExactAlarm:
        'ohos.permission.PUBLISH_AGENT_REMINDER',
    standard.Permission.sensors: 'ohos.permission.ACCELEROMETER',
  };

  @override
  Future<standard.PermissionStatus> checkPermissionStatus(
      standard.Permission permission) async {
    if (permission == standard.Permission.notification) {
      return await _channel.invokeMethod<bool>('areNotificationsEnabled') ==
              true
          ? standard.PermissionStatus.granted
          : standard.PermissionStatus.denied;
    }
    final name = _permissions[permission];
    if (name == null) return standard.PermissionStatus.restricted;
    return _map(await PermissionHandlerOhos.checkPermissionStatus(name));
  }

  @override
  Future<Map<standard.Permission, standard.PermissionStatus>>
      requestPermissions(
    List<standard.Permission> permissions,
  ) async {
    final results = <standard.Permission, standard.PermissionStatus>{};
    for (final permission in permissions) {
      if (permission == standard.Permission.notification) {
        final granted =
            await _channel.invokeMethod<bool>('requestNotificationPermission');
        results[permission] = granted == true
            ? standard.PermissionStatus.granted
            : standard.PermissionStatus.denied;
      } else {
        final name = _permissions[permission];
        if (name == null) {
          results[permission] = standard.PermissionStatus.restricted;
        } else if (permission == standard.Permission.scheduleExactAlarm ||
            permission == standard.Permission.sensors) {
          // These are system-granted at installation, not user-grant dialogs.
          results[permission] = await checkPermissionStatus(permission);
        } else {
          results[permission] =
              _map(await PermissionHandlerOhos.requestPermission(name));
        }
      }
    }
    return results;
  }

  static standard.PermissionStatus _map(PermissionStatusOhos status) =>
      switch (status) {
        PermissionStatusOhos.granted => standard.PermissionStatus.granted,
        PermissionStatusOhos.denied => standard.PermissionStatus.denied,
        _ => standard.PermissionStatus.restricted,
      };

  @override
  Future<bool> openAppSettings() => PermissionHandlerOhos.openAppSettings();

  @override
  Future<standard.ServiceStatus> checkServiceStatus(
          standard.Permission permission) async =>
      standard.ServiceStatus.notApplicable;

  @override
  Future<bool> shouldShowRequestPermissionRationale(
          standard.Permission permission) async =>
      false;
}
