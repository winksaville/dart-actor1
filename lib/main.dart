// Based on [this](https://github.com/winksaville/dart-isolate-example)

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:intl/intl.dart';

// Counter for message received by server
int msgCounter = 0;

// Start an isolate and return it
Future<Client> startClient() async {
  // Create a port used to communite with the isolate
  ReceivePort receivePort = ReceivePort();
  SendPort responsePort = null;

  // Create client
  Client client = MyClient(receivePort.sendPort);

  // Start the client
  await client.start();

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

abstract class Client {
  SendPort partnerPort;
  ReceivePort receivePort;
  Isolate isolate;

  Client(SendPort partnerPort) {
    this.partnerPort = partnerPort;
  }

  void start() async {
    this.isolate = await Isolate.spawn(Client.entryPoint, this);
  }

  /// Stop the isolate immediately and return null
  void stop() {
    // Handle isolate being null
    this.isolate?.kill(priority: Isolate.immediate);
  }

  void enter() {
    // Create a port that will receive messages from our partner
    this.receivePort = ReceivePort();

    // Using the partnerPort send our sendPort so they
    // can send us messages.
    this.partnerPort.send(receivePort.sendPort);
  }

  // Client receives a Send port from our partner
  // so that messages maybe sent to it.
  static void entryPoint(Client client) {
    client.enter();
    client.begin();
    client.receivePort.listen(client.process);
    stdout.writeln('client: running');
  }

  // Invoked once when the client is first started
  void begin() {}

  // Invoked when a message arrives and must be overridden
  void process(message);
}

class MyClient extends Client {
  int counter;

  MyClient(SendPort partnerPort) : super(partnerPort);

  @override
  void begin() {
    this.counter = 1;
    this.partnerPort.send(counter);
  }

  @override
  void process(dynamic message) {
      //stdout.writeln('RESP: ' + data);
      this.counter++;
      //stdout.writeln('SEND: ' + counter);
      this.partnerPort.send(counter);
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
  Client client = await startClient();

  // Wait for any key
  int afterStart = stopwatch.elapsedMicroseconds;
  await stdin.first;
  int done = stopwatch.elapsedMicroseconds;

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

  // Stop the isolate, we also verify a null "works"
  stdout.writeln('stopping');
  client.stop();
  stdout.writeln('stopped');

  // Because main is async use exit
  exit(0);
}
