// Based on [this](https://github.com/winksaville/dart-isolate-example)

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:intl/intl.dart';

// Counter for message received by server
int msgCounter = 0;

// Start an isolate and return it
Future<Client> startClient({bool locally=false}) async {
  // Create a port used to communite with the isolate
  ReceivePort receivePort = ReceivePort();
  SendPort responsePort = null;

  // Create client
  Client client = MyClient(receivePort.sendPort);

  // Start the client
  await client.start(locally: locally);

  // Listen on the receive port passing a routine that
  // will process the data passed. The first message
  // should be the send port for the client so this code
  // can send message back.
  receivePort.listen((dynamic data) {
    if (data is SendPort) {
      stdout.writeln('RECEIVE: responsePort');
      responsePort = data;
    } else {
      assert(responsePort != null);
      msgCounter += 1;
      responsePort.send(data);
    }
  });

  // Return the client that was created
  return client;
}

/// Client that can process messages and communicates
/// via messages using a ReceivePort and SendPort.
abstract class Client {
  SendPort _partnerPort;
  ReceivePort _receivePort;
  Isolate _isolate;

  /// Contruct a client passing a SendPort which is used
  /// by the client to send messages to the ReceivePort.
  Client(SendPort partnerPort) {
    _partnerPort = partnerPort;
  }

  /// Start the client. When the client starts _enter will
  /// be invoked and by default it creates _receivePort
  /// and executes _partnerPort.send(_receivePort.sendPort)
  /// which sends the SendPort to the partner.
  void start({bool locally=false}) async {
    if (locally) {
      _isolate = Isolate.current;
      _entryPoint(this);
    } else {
      _isolate = await Isolate.spawn(Client._entryPoint, this);
    }
  }

  /// Stop the client immediately if its not a local client.
  void stop() {
    // Handle isolate being null
    if ((_isolate != null) && (_isolate != Isolate.current)) {
      _isolate.kill(priority: Isolate.immediate);
    }
  }

  /// Invoked by when the clients starts.
  static void _entryPoint(Client client) {
    client._enter();
    client._begin();
    client._receivePort.listen(client._process);
    stdout.writeln('client: running');
  }

  /// Called once when Client is first invoked and usually
  /// Sets up communication with the partner
  void _enter() {
    // Create a port that will receive messages from our partner
    _receivePort = ReceivePort();

    // Using the partnerPort send our sendPort so they
    // can send us messages.
    _partnerPort.send(_receivePort.sendPort);
  }

  /// Invoked once when the client is first started after
  /// _enter and before the first call to _process.
  void _begin() {}

  /// Invoked everytime a message arrives from the partner
  /// and must be overridden
  void _process(message);
}

class MyClient extends Client {
  int counter;

  MyClient(SendPort partnerPort) : super(partnerPort);

  @override
  void _begin() {
    counter = 1;
    _partnerPort.send(counter);
  }

  @override
  void _process(dynamic message) {
      //stdout.writeln('RESP: ' + data);
      counter++;
      //stdout.writeln('SEND: ' + counter);
      _partnerPort.send(counter);
  }
}

void main() async {
  // Change stdin so it doesn't echo input and doesn't wait for enter key
  stdin.echoMode = false;
  stdin.lineMode = false;

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  // Tell the user to press a key
  stdout.writeln('Press any key to stop:');

  // Start an isolate
  int beforeStart = stopwatch.elapsedMicroseconds;
  Client client = await startClient(locally: true);

  // Wait for any key
  int afterStart = stopwatch.elapsedMicroseconds;
  await stdin.first;
  int done = stopwatch.elapsedMicroseconds;

  // Stop the client
  stdout.writeln('stopping');
  client.stop();
  stdout.writeln('stopped');

  // Print time
  msgCounter *= 2;
  double totalSecs = (done.toDouble() - beforeStart.toDouble()) / 1000000.0;
  double rate = msgCounter.toDouble() / totalSecs;
  NumberFormat f3digits = NumberFormat('###,###.00#');
  NumberFormat f0digit = NumberFormat('###,###');
  stdout.writeln(
    'Total time=${f3digits.format(totalSecs)} secs '
    'msgs=${f0digit.format(msgCounter)} '
    'rate=${f0digit.format(rate)} msgs/sec');

  // Because main is async use exit
  exit(0);
}
