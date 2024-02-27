library pusharound;

import 'push_provider.dart';
import 'push_notification.dart';

const _pusharoundPrefix = 'pusharound_';

class Pusharound {
  final List<PushProvider> _providers;

  Pusharound(List<PushProvider> providers) : _providers = providers;

  void setListener(Function(PushNotification) onNotification) {
    newListener(data) {
      var isPusharound = data['title'].toString().startsWith(_pusharoundPrefix);
      if (isPusharound) {
        (data['title'] as String).replaceFirst(_pusharoundPrefix, '');
      }
      onNotification(PushNotification(isPusharound, data));
    }

    for (var provider in _providers) {
      provider.setListener(newListener);
    }
  }
}
