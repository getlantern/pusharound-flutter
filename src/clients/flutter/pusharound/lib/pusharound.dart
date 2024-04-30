/// A client-side package for the pusharound protocol. For use in Flutter
/// applications, in conjunction with the [pusharound back-end library](https://github.com/getlantern/pusharound).
/// Currently built around [pushy](pushy.me), though more providers may be added
/// in the future.
///
/// Pusharound implements a transport using push notification systems, as
/// described in [The Use of Push Notification in Censorship Circumvention](https://www.petsymposium.org/foci/2023/foci-2023-0009.pdf)
/// by Diwen Xue and Roya Ensafi.
library pusharound;

export 'src/pusharound.dart' show Pusharound;
export 'src/push_provider.dart' show PushProvider;
export 'src/push_notification.dart' show PushNotification;
export 'src/providers/pushy.dart' show PushyProvider;
