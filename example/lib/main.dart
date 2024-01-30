import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler_ohos/permission_handler_ohos.dart';
import 'package:grouped_list/grouped_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'permission_handler_ohos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'permission_handler_ohos'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<PermissionOhos> _elements = PermissionOhos.values.where((element) =>
      // 默认应用等级为normal，只能使用normal等级的权限，如果使用了system_basic或system_core等级的权限，将导致报错。
      element.permissionLevel.contains('normal')).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              PermissionHandlerOhos.openAppSettings();
            },
            icon: const Icon(
              Icons.settings,
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GroupedListView<PermissionOhos, String>(
          elements: _elements,
          groupBy: (element) => element.grantType,
          itemComparator: (element1, element2) => element1.name.compareTo(
            element2.name,
          ),
          itemBuilder: (context, element) => PermissionWidget(element),
          useStickyGroupSeparators: true,
          groupSeparatorBuilder: (String value) => Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              '授权方式(grantType): $value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          order: GroupedListOrder.DESC,
        ),
      ),
    );
  }
}

/// Permission widget containing information about the passed [PermissionOhos]
class PermissionWidget extends StatefulWidget {
  /// Constructs a [PermissionWidget] for the supplied [PermissionOhos]
  const PermissionWidget(this.permission, {super.key});

  final PermissionOhos permission;

  @override
  State createState() => _PermissionState();
}

class _PermissionState extends State<PermissionWidget> {
  PermissionOhos get _permission => widget.permission;
  PermissionStatusOhos _permissionStatus = PermissionStatusOhos.invalid;
  @override
  void initState() {
    super.initState();

    _listenForPermissionStatus();
  }

  void _listenForPermissionStatus() async {
    final status =
        await PermissionHandlerOhos.checkPermissionStatus(_permission.name);
    setState(() => _permissionStatus = status);
  }

  Color getPermissionColor() {
    switch (_permissionStatus) {
      case PermissionStatusOhos.denied:
        return Colors.red;
      case PermissionStatusOhos.granted:
        return Colors.green;
      case PermissionStatusOhos.invalid:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_permission.grantType.contains('user_grant')) {
          requestPermission(_permission);
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _permission.name,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 5),
              Text(
                '权限级别(Level): ${_permission.permissionLevel}',
              ),
              const SizedBox(height: 5),
              Text(
                '起始版本(Version): ${_permission.startVersion}',
              ),
              const SizedBox(height: 5),
              Text.rich(TextSpan(children: <InlineSpan>[
                const TextSpan(text: '权限状态(Status): '),
                TextSpan(
                  text: _permissionStatus.name,
                  style: TextStyle(color: getPermissionColor()),
                )
              ]))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> requestPermission(PermissionOhos permission) async {
    final PermissionStatusOhos status =
        await PermissionHandlerOhos.requestPermission(permission.name);

    setState(() {
      if (kDebugMode) {
        print(status);
      }
      _permissionStatus = status;
      if (kDebugMode) {
        print(_permissionStatus);
      }
    });
  }
}
