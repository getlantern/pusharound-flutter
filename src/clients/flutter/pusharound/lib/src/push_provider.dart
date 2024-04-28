library push_provider;

abstract class PushProvider {
  void setListener(Function(Map<String, dynamic> data) onNotification);
}
