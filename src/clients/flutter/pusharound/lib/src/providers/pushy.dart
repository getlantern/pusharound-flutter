library pushy;

import '../push_provider.dart';

import 'package:pushy_flutter/pushy_flutter.dart' as pushy;

class PushyProvider implements PushProvider {
  @override
  void setListener(Function(Map<String, dynamic>) onNotification) {
    pushy.Pushy.setNotificationListener(onNotification);
  }

  void subscribe(String topic) async {
    if (await pushy.Pushy.isRegistered()) {
      await pushy.Pushy.subscribe(topic);
    }
  }
}
