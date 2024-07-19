library push_provider;

/// A push notification provider.
abstract class PushProvider {
  /// Sets a listener for receiving raw notifications from the provider. A
  /// Pusharound instance will call this function to register its own listeners.
  /// May be called multiple times in an application lifecycle.
  void setListener(Function(Map<String, dynamic> data) onNotification);
}
