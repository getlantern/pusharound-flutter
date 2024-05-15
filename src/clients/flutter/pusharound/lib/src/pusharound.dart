library pusharound;

import 'push_notification.dart';
import 'push_provider.dart';

// typedef for the onNotification ,stream and exception
typedef void OnNotification(PushNotification);
typedef void OnStream(String);
typedef void OnNotificationError(Exception);

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

// Define global variables to hold the callback functions
OnNotification? _globalOnNotification;
OnStream? _globalOnStream;
OnNotificationError? _globalOnError;

/// The governing class for receiving pusharound messages.
class Pusharound {
  final List<PushProvider> _providers;

  // Stream ID -> { datum index -> datum }
 static final Map<String, Map<int, String>> _incompleteStreams = {};

  // Stream ID -> index of last message if received.
  static final Map<String, int> _lastIndex = {};

  /// Initializes a Pusharound instance with the given push notification
  /// providers.
  Pusharound(this._providers);

  /// Registers listeners for notifications, streams, and exceptions.
  void setListeners(OnNotification onNotification,
      OnNotification onStream, OnNotificationError onException) {
    //Save callback functions to global variables
    _globalOnNotification = onNotification;
    _globalOnStream = onStream;
    _globalOnError = onException;


    /// Now pass our notification handler to each of the configured providers.
    /// [OnNotification]
    /// callback need to be annotated with the `@pragma('vm:entry-point')`
    /// annotation to ensure they are not stripped out by the Dart compiler.
    /// This is required by Pushy SDK
    for (var provider in _providers) {
      provider.setListener(
        notificationHandler,
      );
    }
  }


  @pragma('vm:entry-point')
 static void notificationHandler(Map<String, dynamic> data) {
    // Make sure we have all callback functions
    if (_globalOnNotification == null || _globalOnStream == null ||
        _globalOnError == null) {
      throw Exception("Callback functions are not set");
    }
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
      _globalOnNotification!(PushNotification(false, data));
      return;
    }

    if (streamID is! String) {
      var rt = streamID.runtimeType;
      _globalOnError!(Exception("received $rt instead of String for streamID"));
      return;
    }

    if (streamID == _nullStreamID) {
      // One-off message.
      _globalOnNotification!(PushNotification(true, data));
      return;
    }

    // At this point, we are handling a stream.

    if (streamCounterRaw == null) {
      _globalOnNotification!(Exception("received stream without counter"));
      return;
    }

    // This may be an empty completion message. In this case, there is no data
    // included, but we must still update the data in _incompleteStreams.
    streamData ??= "";

    if (streamData is! String) {
      var rt = streamData.runtimeType;
      _globalOnError!(
          Exception("received $rt instead of String for stream data"));
      return;
    }

    int streamCounter;
    try {
      streamCounter = int.parse(streamCounterRaw);
    } on FormatException catch (e) {
      _globalOnError!(Exception("received malformed stream counter: $e"));
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
    for (var i = 0; i <= lastIndex; i++) {
      var data = stream[i];
      if (data == null) {
        // We're missing a message; wait for future notifications.
        return;
      }
      collated += data;
    }

    _globalOnStream!(collated);
  }
}
