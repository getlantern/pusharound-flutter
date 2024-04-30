library push_notification;

/// Represents a single push notification.
class PushNotification {
  /// True iff this notification was sent by a pusharound back-end. Use this
  /// value to separate pusharound messages from "normal" notifications.
  final bool fromPusharound;
  final Map<String, dynamic> data;

  PushNotification(this.fromPusharound, this.data);
}
