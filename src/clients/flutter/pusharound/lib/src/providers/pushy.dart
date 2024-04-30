library pushy;

import '../push_provider.dart';

import 'package:pushy_flutter/pushy_flutter.dart' as pushy;

/// Implements the PushProvider abstract class for pushy.
/// See https://pushy.me/
class PushyProvider implements PushProvider {
  /// Configures a listener for raw Pushy notifications. Pusharound clients will
  /// not need to and should not call this during normal operation. This is
  /// called by a Pusharound instance to register its own listeners.
  @override
  void setListener(Function(Map<String, dynamic>) onNotification) {
    pushy.Pushy.setNotificationListener(onNotification);
  }

  /// Subscribes this device to the specified Pusharound topic. Use this to
  /// subscribe to both Pusharound and non-Pusharound topics. Notifications from
  /// both will arrive through the listeners registered with a Pusharound
  /// instance.
  void subscribe(String topic) async {
    if (await pushy.Pushy.isRegistered()) {
      await pushy.Pushy.subscribe(topic);
    }
  }
}
