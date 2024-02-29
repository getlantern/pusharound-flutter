library pusharound;

import 'push_provider.dart';
import 'push_notification.dart';

const _pusharoundKey = 'pusharound';

class Pusharound {
  final List<PushProvider> _providers;

  Pusharound(List<PushProvider> providers) : _providers = providers;

  void setListener(Function(PushNotification) onNotification) {
    newListener(Map<String, dynamic> data) {
      print("data: $data");
      var isPusharound = data.containsKey(_pusharoundKey);
      if (isPusharound) {
        data.remove(_pusharoundKey);
      }
      onNotification(PushNotification(isPusharound, data));
    }

    for (var provider in _providers) {
      provider.setListener(newListener);
    }
  }
}
