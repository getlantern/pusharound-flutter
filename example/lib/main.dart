import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pushy_flutter/pushy_flutter.dart';

import 'package:pusharound/pusharound.dart';

void main() {
  // TODO: not set up for Android or iOS (see https://pushy.me/docs/additional-platforms/flutter)
  runApp(_SimpleApp());
}

class _SimpleApp extends StatelessWidget {
  const _SimpleApp({super.key});

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

  var pusharound = Pusharound([
    PushyProvider(),
  ]);

  _AppState() {
    pusharound.setListener((notification) {
      if (notification.fromPusharound) {
        pusharoundNotifications.add(notification.data['message']);
      } else {
        nonPusharoundNotifications.add(notification.data['message']);
      }
      notifyListeners();
    });
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

    Pushy.listen();
    Pushy.setAppId('657e7007d13f88ac44aa9bc1'); // only required for WebPush

    () async {
      var token = await Pushy.register();
      print("Pushy token: $token");
    }();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var appState = context.watch<_AppState>();

    return Scaffold(
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
