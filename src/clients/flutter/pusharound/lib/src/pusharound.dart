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

// This key will be mapped to a counter indicating this message's position in
// the stream.
const _streamCounterKey = 'pusharound-stream-counter';

// This key is included only in the last message of a stream and is mapped to an
// empty string.
const _streamCompleteKey = "pusharound-stream-ok";

// This key is included only for notifications which are part of a stream of
// many messages. One-off messages use custom keys to specify user data.
const _streamDataKey = "pusharound-stream-data";

class Pusharound {
  final List<PushProvider> _providers;

  // Stream ID -> { datum index -> datum }
  final Map<String, Map<int, String>> _incompleteStreams = {};

  // Stream ID -> index of last message if received.
  final Map<String, int> _lastIndex = {};

  Pusharound(this._providers);

  void setListeners(Function(PushNotification) onNotification,
      Function(String) onStream, Function(Exception) onException) {
    // Define a function for handling raw notification data.
    notificationHandler(Map<String, dynamic> data) {
      var streamID = data[_streamIDKey];
      var streamCounterRaw = data[_streamCounterKey];
      var streamComplete = data[_streamCompleteKey];
      var streamData = data[_streamDataKey];

      // Clean up pusharound metadata. These keys won't all be included on every
      // message, but it doesn't hurt to try removing them all just in case.
      data.remove(_streamIDKey);
      data.remove(_streamCounterKey);
      data.remove(_streamCompleteKey);
      data.remove(_streamDataKey);

      if (streamID == null) {
        onNotification(PushNotification(false, data));
        return;
      }

      if (streamID is! String) {
        var rt = streamID.runtimeType;
        onException(Exception("received $rt instead of String for streamID"));
        return;
      }

      if (streamID == _nullStreamID) {
        // One-off message.
        onNotification(PushNotification(true, data));
        return;
      }

      // At this point, we are handling a stream.

      if (streamCounterRaw == null) {
        onException(Exception("received stream without counter"));
        return;
      }

      // This may be an empty completion message. In this case, there is no data
      // included, but we must still update the data in _incompleteStreams.
      streamData ??= "";

      if (streamData is! String) {
        var rt = streamData.runtimeType;
        onException(
            Exception("received $rt instead of String for stream data"));
        return;
      }

      int streamCounter;
      try {
        streamCounter = int.parse(streamCounterRaw);
      } on FormatException catch (e) {
        onException(Exception("received malformed stream counter: $e"));
        return;
      }

      if (streamComplete != null) {
        _lastIndex[streamID] = streamCounter;
      }

      var stream = _incompleteStreams.putIfAbsent(streamID, () => {});
      stream[streamCounter] = streamData;

      // If we have not received the entire stream, we must wait for future
      // notifications.
      var lastIndex = _lastIndex[streamID];
      if (lastIndex == null) {
        return;
      }

      var collated = '';
      for (var i = 0; i < lastIndex; i++) {
        var data = stream[i];
        if (data == null) {
          // We're missing a message; wait for future notifications.
          return;
        }
        collated += data;
      }

      onStream(collated);
    }

    // Now pass our notification handler to each of the configured providers.
    for (var provider in _providers) {
      provider.setListener(notificationHandler);
    }
  }
}
