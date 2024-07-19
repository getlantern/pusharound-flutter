import 'package:test/test.dart';

import 'package:pusharound/pusharound.dart';

// These constants are copied from ../lib/src/pusharound.dart
const _streamIDKey = 'pusharound-stream-id';
const _nullStreamID = '00000000';
const _streamCounterKey = 'pusharound-stream-counter';
const _streamCompleteKey = "pusharound-stream-ok";
const _streamDataKey = "pusharound-stream-data";

// Rather than re-implement the stream logic from the back-end library, we just
// have a handful of hard-coded test streams. The keys in this map are the full
// collated data and the values are a list of messages comprising the stream.
var testStreams = <String, List<Map<String, dynamic>>>{
  // Simple stream
  "abcdefghijklmnopqrstuvwxyz": [
    {
      _streamIDKey: "beefface",
      _streamCounterKey: "000",
      _streamDataKey: "abcde",
    },
    {
      _streamIDKey: "beefface",
      _streamCounterKey: "001",
      _streamDataKey: "fghij",
    },
    {
      _streamIDKey: "beefface",
      _streamCounterKey: "002",
      _streamDataKey: "klmno",
    },
    {
      _streamIDKey: "beefface",
      _streamCounterKey: "003",
      _streamDataKey: "pqrst",
    },
    {
      _streamIDKey: "beefface",
      _streamCounterKey: "004",
      _streamDataKey: "uvwxy",
    },
    {
      _streamIDKey: "beefface",
      _streamCounterKey: "005",
      _streamDataKey: "z",
      _streamCompleteKey: "",
    },
  ],
  // No data in final message.
  "123456789": [
    {
      _streamIDKey: "0123dead",
      _streamCounterKey: "000",
      _streamDataKey: "123",
    },
    {
      _streamIDKey: "0123dead",
      _streamCounterKey: "001",
      _streamDataKey: "456",
    },
    {
      _streamIDKey: "0123dead",
      _streamCounterKey: "002",
      _streamDataKey: "789",
    },
    {
      _streamIDKey: "0123dead",
      _streamCounterKey: "003",
      _streamCompleteKey: ""
    },
  ],
  // Message from another stream.
  "987654321": [
    {
      _streamIDKey: "0123dead",
      _streamCounterKey: "000",
      _streamDataKey: "987",
    },
    {
      _streamIDKey: "0123dead",
      _streamCounterKey: "001",
      _streamDataKey: "654",
    },
    {
      _streamIDKey: "99999999",
      _streamCounterKey: "002",
      _streamDataKey: "foo",
    },
    {
      _streamIDKey: "0123dead",
      _streamCounterKey: "002",
      _streamDataKey: "321",
      _streamCompleteKey: "",
    },
  ],
};

void main() {
  test('non-pusharound notification', () {
    var pt = PusharoundTester();

    pt.sendNotification({
      "some message key": "some message data",
    }, false);

    pt.check([
      PushNotification(false, {
        "some message key": "some message data",
      })
    ], [], []);
  });

  test('pusharound notification', () {
    var pt = PusharoundTester();

    pt.sendNotification({
      "some message key": "some message data",
    }, true);

    pt.check([
      PushNotification(true, {
        "some message key": "some message data",
      })
    ], [], []);
  });

  test('streams', () {
    testStreams.forEach((stream, messages) {
      var pt = PusharoundTester();

      for (final data in messages) {
        pt.sendNotification(data, true);
      }

      pt.check([], [stream], []);
    });
  });
}

class PusharoundTester {
  final MockPushProvider mockProvider;
  final Pusharound p;

  List<PushNotification> notifications = [];
  List<String> streams = [];
  List<Exception> exceptions = [];

  PusharoundTester._(this.mockProvider, this.p);

  factory PusharoundTester() {
    var mockProvider = MockPushProvider();
    var p = Pusharound([mockProvider]);
    var pt = PusharoundTester._(mockProvider, p);

    p.setListeners(
        (notification) => pt.notifications.add(notification),
        (stream) => pt.streams.add(stream),
        (exception) => pt.exceptions.add(exception));

    return pt;
  }

  sendNotification(Map<String, dynamic> data, bool isPusharound) {
    mockProvider.sendNotification(data, isPusharound);
  }

  check(List<PushNotification> notifications, List<String> streams,
      List<Exception> exceptions) {
    expect(this.notifications.length, notifications.length);
    expect(this.streams.length, streams.length);
    expect(this.exceptions.length, exceptions.length);

    for (int i = 0; i < this.notifications.length; i++) {
      expect(this.notifications[i].data, notifications[i].data,
          reason: "notification $i should be equal");
      expect(
          this.notifications[i].fromPusharound, notifications[i].fromPusharound,
          reason: "notification $i should be equal");
    }

    for (int i = 0; i < this.streams.length; i++) {
      expect(this.streams[i], streams[i], reason: "stream $i should be equal");
    }

    for (int i = 0; i < this.exceptions.length; i++) {
      expect(this.exceptions[i], exceptions[i],
          reason: "exception $i should be equal");
    }
  }
}

class MockPushProvider implements PushProvider {
  Function(Map<String, dynamic>) listener = (_) => {};

  // Sets the current listener.
  @override
  void setListener(Function(Map<String, dynamic> data) onNotification) {
    listener = onNotification;
  }

  // Sends a notification to the current listener.
  void sendNotification(Map<String, dynamic> data, bool isPusharound) {
    if (isPusharound && !data.containsKey(_streamIDKey)) {
      data[_streamIDKey] = _nullStreamID;
    }
    listener(data);
  }
}
