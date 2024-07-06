library pusharound;

import 'push_provider.dart';
import 'push_notification.dart';

// All pusharound messages contain this key. For streams (data split across
// multiple messages), this key will be mapped to an identifier indicating the
// stream to which the notification belongs. For one-off messages, this key will
// be mapped to the null stream ID.
const _streamIDKey = 'pusharound-stream-id';

// One-off messages use this stream ID.
const _nullStreamID = '00000000';

// This key will be mapped to an integer indicating this message's position in
// the stream.
const _streamIndexKey = 'pusharound-index';

// This key is included only in the last message of a stream and is mapped to an
// empty string.
const _streamCompleteKey = "pusharound-ok";

// This key is included only for notifications which are part of a stream of
// many messages. One-off messages use custom keys to specify user data.
const _streamDataKey = "pusharound-data";

/// The governing class for receiving pusharound messages.
class Pusharound {
  // Stream ID -> { datum index -> datum }
  static final Map<String, Map<int, String>> _incompleteStreams = {};

  // Stream ID -> index of last message if received.
  static final Map<String, int> _lastIndex = {};

  static List<PushProvider> _providers = [];

  static Function(PushNotification) _onNotification = (_) => {};
  static Function(String) _onStream = (_) => {};
  static Function(Exception) _onException = (_) => {};

  static void setProviders(List<PushProvider> providers) {
    _providers = providers;
  }

  /// Registers listeners for notifications, streams, and exceptions.
  static void setListeners(Function(PushNotification) onNotification,
      Function(String) onStream, Function(Exception) onException) {
    _onNotification = onNotification;
    _onStream = onStream;
    _onException = onException;

    for (var provider in _providers) {
      provider.setListener(_notificationHandler);
    }
  }

  // On some platforms (e.g. iOS), this function is invoked only by native code,
  // so the Dart compiler will be unable to tell that the function is ever
  // called. Thus it will be compiled out. To avoid this, we mark the function
  // as invoked by native (or VM) code. We also need to define the function on
  // the top level (as opposed to an instance method). This is why all of the
  // functions and fields of Pusharound are defined on the class level (as
  // static definitions).
  @pragma('vm:entry-point')
  static void _notificationHandler(Map<String, dynamic> data) {
    var streamID = data[_streamIDKey];
    var streamIndexRaw = data[_streamIndexKey];
    var streamComplete = data[_streamCompleteKey];
    var streamData = data[_streamDataKey];

    // Clean up pusharound metadata. These keys won't all be included on every
    // message, but it doesn't hurt to try removing them all just in case.
    data.remove(_streamIDKey);
    data.remove(_streamIndexKey);
    data.remove(_streamCompleteKey);
    data.remove(_streamDataKey);

    if (streamID == null) {
      _onNotification(PushNotification(false, data));
      return;
    }

    if (streamID is! String) {
      var rt = streamID.runtimeType;
      _onException(Exception("received $rt instead of String for streamID"));
      return;
    }

    if (streamID == _nullStreamID) {
      // One-off message.
      _onNotification(PushNotification(true, data));
      return;
    }

    // At this point, we are handling a stream.

    if (streamIndexRaw == null) {
      _onException(Exception("received stream without counter"));
      return;
    }

    // This may be an empty completion message. In this case, there is no data
    // included, but we must still update the data in _incompleteStreams.
    streamData ??= "";

    if (streamData is! String) {
      var rt = streamData.runtimeType;
      _onException(Exception("received $rt instead of String for stream data"));
      return;
    }

    int index;
    try {
      index = int.parse(streamIndexRaw);
    } on FormatException catch (e) {
      _onException(Exception("received malformed stream counter: $e"));
      return;
    }

    if (streamComplete != null) {
      _lastIndex[streamID] = index;
    }

    var stream = _incompleteStreams.putIfAbsent(streamID, () => {});
    stream[index] = streamData;

    // If we have not received the entire stream, we must wait for future
    // notifications.
    var lastIndex = _lastIndex[streamID];
    if (lastIndex == null) {
      return;
    }

    var collated = '';
    for (var i = 0; i <= lastIndex; i++) {
      var data = stream[i];
      if (data == null) {
        // We're missing a message; wait for future notifications.
        return;
      }
      collated += data;
    }

    _onStream(collated);
  }
}
