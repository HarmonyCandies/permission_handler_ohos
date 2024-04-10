// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:dart_style/dart_style.dart';

const String docUrl =
    'https://gitee.com/openharmony/docs/blob/OpenHarmony-4.1-Release/zh-cn/application-dev/security/AccessToken/permissions-for-all.md';

Future<void> main(List<String> args) async {
  // var map = extractPermissionsAndComments(
  //     File(path.join('bin', 'permissions.ts')).readAsStringSync());
  //
  var permissions =
      extractPermissions(File(path.join('bin', 'doc.txt')).readAsStringSync());

  StringBuffer sb = StringBuffer();
  StringBuffer sb1 = StringBuffer();
  // RegExp regExp = RegExp(r'@since (\d+)');
  for (var p in permissions) {
    var name = p.name.split('.').last.toLowerCase();
    sb.writeln('''  ${p.document}
$name(
name: '${p.name}', 
permissionLevel: '${p.permissionLevel.contains('normal') ? 'normal' : p.permissionLevel}', 
grantType: '${p.grantType}',
aclEnabled: ${p.aclEnabled}, 
startVersion: ${p.startVersion},
),    
''');

    // 权限级别：normal
    // 权限级别：API version 9-10为system_basic；从API version 11开始为normal。
    //
    if (p.startVersion != -1 && p.permissionLevel.contains('normal')
        // && p.grantType == 'user_grant'
        ) {
      // print(p.toString() + '\n');
      if (p.grantType == 'user_grant') {
        sb1.writeln(userGrantPermissionTemplate.replaceAll('{0}', p.name));
      } else {
        sb1.writeln('{"name" :  "${p.name}"},');
      }
    }
  }

//   for (var key in map.keys) {
//     var name = key.split('.').last.toLowerCase();

//     var p = doc.firstWhere((element) => element.name == key,
//         orElse: () => Permission(
//               name: key,
//               aclEnabled: false,
//               description: map[key]!,
//               grantType: 'NotDoc',
//               permissionLevel: 'NotDoc',
//               startVersion: int.tryParse(
//                       regExp.firstMatch(map[key]!)?.group(1) ?? '-1') ??
//                   -1,
//             ));

//     sb.writeln('''  ${p.description}
// $name(
// name: '$key',
// permissionLevel: '${p.permissionLevel}',
// grantType: '${p.grantType}',
// aclEnabled: ${p.aclEnabled},
// startVersion: ${p.startVersion},
// ),
// ''');

//     // 权限级别：normal
//     // 权限级别：API version 9-10为system_basic；从API version 11开始为normal。
//     //
//     if (p.startVersion != -1 &&
//             p.permissionLevel.contains('normal')
//         // && p.grantType == 'user_grant'
//         ) {
//       // print(p.toString() + '\n');
//       sb1.writeln('{"name" :  "$key"},');
//     }
//   }

  File dartFile = File(path.join(
    'lib',
    'src',
    'permissions.dart',
  ));
  DartFormatter df = DartFormatter();

  String format(String x) {
    return df.format(x);
  }

  dartFile.writeAsStringSync(
      format(dartTemplate.replaceAll('{0}', sb.toString()).replaceAll(
            '{1}',
            permissions.length.toString(),
          )));

  //example/ohos/entry/src/main/module.json5
  File moduleJson5File = File(
      path.join('example', 'ohos', 'entry', 'src/', 'main', 'module.json5'));

  String moduleJson5Content =
      moduleJson5Template.replaceAll('{0}', sb1.toString());
  // moduleJson5Content = JSON5.stringify(moduleJson5Content, space: 2);
  // moduleJson5Content = const JsonEncoder.withIndent('  ')
  //     .convert(jsonDecode(moduleJson5Content));

  moduleJson5File.writeAsStringSync(moduleJson5Content);
}

Map<String, String> extractPermissionsAndComments(String input) {
  final regexPermissions = RegExp(r"'([^']*)'", multiLine: true);
  final regexComment = RegExp(r'/\*\*([^*]|[\n]|(\*+([^*/]|[\n])))*\*/');

  final matchesPermissions = regexPermissions.allMatches(input);
  final Map<String, String> permissionsWithComments = {};

  for (final matchPermissions in matchesPermissions) {
    final permission = matchPermissions.group(1);
    final permissionStart = matchPermissions.start;

    // Find the preceding comment block
    String commentBlock = '';
    for (final match
        in regexComment.allMatches(input.substring(0, permissionStart))) {
      commentBlock = match.group(0) ?? '';
    }

    if (permission != null) {
      permissionsWithComments[permission] = commentBlock;
    }
  }

  return permissionsWithComments;
}

List<Permission> extractPermissions(String content) {
  List<Permission> permissions = [];

  var lines = content.split('\n');
  var i = 0;
  for (; i < lines.length; i++) {
    var line = lines[i].trim();
    if (line.startsWith('ohos.permission.')) {
      final name = line;
      String permissionLevel = '';
      String grantType = '';
      bool aclEnabled = false;
      int startVersion = 0;
      String document = '/// $line\n///\n';
      for (i += 1; i < lines.length; i++) {
        var line = lines[i];
        document += '/// $line\n';
        if (line.startsWith('权限级别：')) {
          permissionLevel = line.substring('权限级别：'.length).trim();
        } else if (line.startsWith('授权方式：')) {
          grantType = line.substring('授权方式：'.length).trim();
        } else if (line.startsWith('ACL使能：')) {
          // TRUE，可通过应用市场（AGC）申请。
          aclEnabled = line
              .substring('ACL使能：'.length)
              .trim()
              .toLowerCase()
              .contains('true');
        } else if (line.startsWith('起始版本：')) {
          startVersion =
              int.tryParse(line.substring('起始版本：'.length).trim()) ?? 0;
          // 结束
          break;
        }
      }
      permissions.add(Permission(
        name: name,
        document: document,
        permissionLevel: permissionLevel,
        grantType: grantType,
        aclEnabled: aclEnabled,
        startVersion: startVersion,
      ));
    }
  }

  return permissions;
}

enum OhosPermission {
  xx(name: '', permissionLevel: '', aclEnabled: false);

  const OhosPermission({
    required this.name,
    required this.permissionLevel,
    required this.aclEnabled,
  });

  final String name;
  final String permissionLevel;
  final bool aclEnabled;
}

class Permission {
  Permission({
    required this.name,
    required this.permissionLevel,
    required this.grantType,
    required this.aclEnabled,
    required this.startVersion,
    required this.document,
  });
  final String name;
  final String permissionLevel;
  final String grantType;
  final bool aclEnabled;
  final int startVersion;
  final String document;
  @override
  String toString() {
    return '''
      Name: $name
      Permission Level: $permissionLevel
      Grant Type: $grantType
      ACL Enabled: $aclEnabled
      Start Version: $startVersion
      Document: $document
    ''';
  }
}

const String dartTemplate = '''
// GENERATED CODE - DO NOT MODIFY MANUALLY
// **************************************************************************
// Auto generated by https://github.com/HarmonyCandies/permission_handler_ohos/bin/main.dart 
// **************************************************************************
// $docUrl
// ignore_for_file: constant_identifier_names,slash_for_doc_comments

/// The Permissions of OpenHarmony
/// total: {1} 
enum PermissionOhos {
{0};

  const PermissionOhos({
    required this.name,
    required this.permissionLevel,
    required this.aclEnabled,
    required this.grantType,
    required this.startVersion,
  });

  final String name;
  final String permissionLevel;
  final bool aclEnabled;
  final String grantType;
  final int startVersion;
}

''';

const String etsTemplate = '''
export const permissionsMap: Map<number, string> = new Map<number, string>([
   {0}
]);
''';

const String moduleJson5Template = '''
/*
* Copyright (c) 2023 Hunan OpenValley Digital Industry Development Co., Ltd.
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "\$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "\$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "\$string:EntryAbility_desc",
        "icon": "\$media:icon",
        "label": "\$string:EntryAbility_label",
        "startWindowIcon": "\$media:icon",
        "startWindowBackground": "\$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    "requestPermissions": [
      {0}
    ]
  }
}
''';

String userGrantPermissionTemplate = '''
      {
        "name": "{0}",
        "reason": "\$string:EntryAbility_label",
        "usedScene": {
          "abilities": [
            "EntryAbility"
          ],
          "when": "inuse"
        }
      },
''';
