// Based on [this](https://github.com/winksaville/dart-isolate-example)

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:intl/intl.dart';

class ResultSCS {
  MyClient client;
  MyServer server;
  ResultSCS(this.client, this.server);
}

// Start a server and client
Future<ResultSCS> startServerAndClient({bool locally=false}) async {
  // Create a port used to communite with the isolate
  ReceivePort receivePort = ReceivePort();
  SendPort responsePort = null;

  // Create Server
  Server server = MyServer(receivePort);

  // Create client
  Client client = MyClient(receivePort.sendPort);

  // Start the client
  await client.start(locally: locally);

  // Start the server
  await server.start(locally: locally);

  // Return the client and server
  return ResultSCS(client, server);
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
      _isolate = await Isolate.spawn<Client>(Client._entryPoint, this);
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
  int counter = 0;

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

/// Server
abstract class Server {
  SendPort _partnerPort;
  ReceivePort _receivePort;
  Isolate _isolate;

  /// Contruct a server passing a ReceivePort which is used
  /// by the server to receive messages from clients.
  Server(ReceivePort receivePort) {
    _receivePort = receivePort;
  }

  /// Start the server.
  void start({bool locally=false}) async {
    if (locally) {
      _isolate = Isolate.current;
      _entryPoint(this);
    } else {
      _isolate = await Isolate.spawn<Server>(Server._entryPoint, this);
    }
  }

  /// Stop the server immediately if its not a local client.
  void stop() {
    // Handle isolate being null
    if ((_isolate != null) && (_isolate != Isolate.current)) {
      _isolate.kill(priority: Isolate.immediate);
    }
  }

  /// Invoked by when the server starts.
  static void _entryPoint(Server server) {
    server._begin();
    server._receivePort.listen(server.__process);
    stdout.writeln('server: running');
  }

  /// Invoked once when the server and before the first call to _process.
  void _begin() {}

  /// Closed by for every message and handles receiving the _partnerPort
  /// which is expected to be the first message.
  void __process(dynamic message) {
    if (message is SendPort) {
      stdout.writeln('MyServer: got partnerPort');
      _partnerPort = message;
    } else {
      assert(_partnerPort != null);
      _process(message);
    }
  }

  /// Invoked everytime a message arrives from the partner
  /// and must be overridden
  void _process(message);
}

class MyServer extends Server {
  int counter = 0;

  MyServer(ReceivePort receivePort) : super(receivePort);

  @override
  void _process(dynamic message) {
    counter += 1;
    _partnerPort.send(message);
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

  int beforeStart = stopwatch.elapsedMicroseconds;

  // Start client and server
  ResultSCS result = await startServerAndClient(locally: true);

  // Wait for any key
  int afterStart = stopwatch.elapsedMicroseconds;
  await stdin.first;
  int done = stopwatch.elapsedMicroseconds;

  // Stop the client
  stdout.writeln('stopping');
  result.client.stop();
  result.server.stop();
  stdout.writeln('stopped');

  // Print time
  int msgCounter = result.client.counter + result.server.counter;
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
