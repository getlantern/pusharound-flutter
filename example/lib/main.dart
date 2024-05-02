import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pushy_flutter/pushy_flutter.dart';

import 'package:pusharound/pusharound.dart';

// This is only needed for Web Push.
// See https://pushy.me/docs/additional-platforms/flutter
const pushyAppID = "";

void main() {
  runApp(const _SimpleApp());
}

class _SimpleApp extends StatelessWidget {
  const _SimpleApp();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => _AppState(),
      child: MaterialApp(
        title: 'Pusharound Example',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        ),
        home: _HomePage(),
      ),
    );
  }
}

class _AppState extends ChangeNotifier {
  var pusharoundNotifications = List<String>.empty(growable: true);
  var nonPusharoundNotifications = List<String>.empty(growable: true);
  var deviceToken = "not yet obtained";

  Exception? currentException;

  var pusharound = Pusharound([
    PushyProvider(),
  ]);

  _AppState() {
    pusharound.setListeners((notification) {
      if (!notification.data.containsKey("message")) {
        currentException = Exception("received notification with no message");
      } else if (notification.fromPusharound) {
        pusharoundNotifications.add(notification.data['message']);
      } else {
        nonPusharoundNotifications.add(notification.data['message']);
      }
      notifyListeners();
    }, (stream) {
      var streamMD5 = md5.convert(utf8.encode(stream)).toString();
      pusharoundNotifications.add("stream: $streamMD5");
      notifyListeners();
    }, (exception) {
      currentException = exception;
      notifyListeners();
    });

    Pushy.listen();
    if (pushyAppID != "") {
      Pushy.setAppId(pushyAppID);
    }

    () async {
      var token = await Pushy.register();
      deviceToken = token;
      notifyListeners();
    }();
  }
}

class _HomePage extends StatefulWidget {
  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var appState = context.watch<_AppState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (appState.currentException != null) {
        showDialog(
            context: context,
            builder: (BuildContext buildContext) {
              return AlertDialog(
                title: const Text("Exception"),
                content: Text("${appState.currentException}"),
                actions: <Widget>[
                  TextButton(
                      child: const Text("OK"),
                      onPressed: () {
                        Navigator.of(buildContext).pop();
                        appState.currentException = null;
                      })
                ],
              );
            });
      }
    });

    return Scaffold(
      bottomNavigationBar:
          SelectableText("device token: ${appState.deviceToken}"),
      body: Row(
        children: [
          Expanded(
            child: _NotificationsColumn(
              'Pusharound Notifications',
              appState.pusharoundNotifications,
            ),
          ),
          VerticalDivider(
            color: theme.colorScheme.onBackground,
            thickness: 2.0,
            width: 0,
          ),
          Expanded(
            child: _NotificationsColumn(
              'Non-Pusharound Notifications',
              appState.nonPusharoundNotifications,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsColumn extends StatelessWidget {
  final String title;
  final List<String> notifications;

  const _NotificationsColumn(this.title, this.notifications);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.primary,
    );

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 2.0,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ),
          child: Text(
            title,
            style: style,
            textAlign: TextAlign.center,
          ),
        ),
        for (var notification in notifications)
          ListTile(
            title: Text(
              notification,
              style: style,
            ),
          ),
      ],
    );
  }
}
