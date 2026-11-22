import { FlutterPlugin, FlutterPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';
import MethodChannel, { MethodCallHandler, MethodResult } from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import AbilityAware from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityAware';
import { AbilityPluginBinding } from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/ability/AbilityPluginBinding';
import { common, Want } from '@kit.AbilityKit';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@kit.BasicServicesKit';
import { notificationManager } from '@kit.NotificationKit';

export default class PermissionHandlerOhosPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private context: Context | null = null;
  private uiContext: common.UIAbilityContext | null = null;

  getUniqueClassName(): string { return 'PermissionHandlerPlugin'; }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.uiContext = binding.getAbility().context;
  }

  onDetachedFromAbility(): void { this.uiContext = null; }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), 'com.harmonycandies.permission_handler_ohos');
    this.channel.setMethodCallHandler(this);
    this.context = binding.getApplicationContext();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.channel?.setMethodCallHandler(null);
    this.channel = null;
    this.context = null;
    this.uiContext = null;
  }

  async onMethodCall(call: MethodCall, result: MethodResult): Promise<void> {
    try {
      if (call.method === 'areNotificationsEnabled') {
        result.success(await notificationManager.isNotificationEnabled());
        return;
      }
      if (call.method === 'checkPermissionStatus') {
        if (this.context == null) {
          result.error('no_context', 'The plugin must be attached to an engine.', null);
          return;
        }
        const status = await abilityAccessCtrl.createAtManager().checkAccessToken(
          this.context.applicationInfo.accessTokenId, call.args as Permissions);
        result.success(status);
        return;
      }
      if (call.method !== 'openAppSettings' && call.method !== 'requestPermissions' &&
        call.method !== 'requestNotificationPermission') {
        result.notImplemented();
        return;
      }
      const context = this.uiContext;
      if (context == null) {
        result.error('no_activity', 'A foreground UIAbility is required.', null);
        return;
      }
      if (call.method === 'requestNotificationPermission') {
        if (!await notificationManager.isNotificationEnabled()) {
          await notificationManager.requestEnableNotification(context);
        }
        result.success(await notificationManager.isNotificationEnabled());
      } else if (call.method === 'openAppSettings') {
        const want: Want = {
          bundleName: 'com.huawei.hmos.settings',
          abilityName: 'com.huawei.hmos.settings.MainAbility',
          uri: 'application_info_entry',
          parameters: { pushParams: context.applicationInfo.name }
        };
        await context.startAbility(want);
        result.success(true);
      } else {
        const args: ESObject = call.args;
        if (!Array.isArray(args) || args.length === 0) {
          result.error('invalid_permissions', 'Pass a non-empty list of OHOS permission names.', null);
          return;
        }
        const permissions = args as Permissions[];
        const response = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, permissions);
        const statuses = new Map<string, number>();
        for (let i = 0; i < permissions.length; i++) {
          statuses.set(permissions[i], response.authResults[i]);
        }
        result.success(statuses);
      }
    } catch (error) {
      const failure = error as BusinessError;
      if (call.method === 'requestNotificationPermission' && failure.code === 1600004) {
        result.success(false);
      } else {
        result.error(String(failure.code), failure.message, null);
      }
    }
  }
}
