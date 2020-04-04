// Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
// [Coding With Joe](codingwithjost.com).

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:intl/intl.dart';

// These Globals are separate instances in each isolate.
SendPort responsePort = null;
int msgCounter = 0;
Client client = null;

// Start an isolate and return it
Future<Isolate> start() async {
  // Create a port used to communite with the isolate
  ReceivePort receivePort = ReceivePort();

  client = Client(receivePort.sendPort, 1234);
  stdout.writeln('main: start client.integer=${client.integer}');

  // Spawn client in an isolate passing the sendPort so
  // it can send us messages
  Isolate isolate = await Isolate.spawn(Client.entryPoint, client);

  // Listen on the receive port passing a routine that accepts
  // the data and prints it.
  receivePort.listen((dynamic data) {
    if (data is SendPort) {
      stdout.writeln('RECEIVE: responsePort');
      responsePort = data;
    } else {
      assert(responsePort != null);
      msgCounter += 1;
      responsePort.send(data); //'RESPONSE: ' + data);
      //stdout.writeln('RECEIVE: ' + data);
    }
  });

  // Return the isolate that was created
  return isolate;
}

class Client {
  SendPort partnerPort;
  int integer;

  Client(SendPort partnerPort, int i) {
    this.partnerPort = partnerPort;
    this.integer = i;
  }

  /// Client receives a Send port from our partner
  /// so that messages maybe sent to it.
  static void entryPoint(Client client) {
    stdout.writeln('client: 1 integer=${client.integer}');
    client.integer = 456;
    stdout.writeln('client: 2 integer=${client.integer}');

    // Create a port that will receive messages from our partner
    ReceivePort receivePort = ReceivePort();

    // Using the partnerPort send our sendPort so they
    // can send us messages.
    client.partnerPort.send(receivePort.sendPort);

    // Since we're the client we send the first data message
    int counter = 1;
    client.partnerPort.send(counter);

    // Wait for response and send more messages as fast as we can
    receivePort.listen((data) {
      //stdout.writeln('RESP: ' + data);
      counter++;
      //stdout.writeln('SEND: ' + counter);
      client.partnerPort.send(counter);
    });

    stdout.writeln('client: done');
  }
}

/// Stop the isolate immediately and return null
Isolate stop(Isolate isolate) {
  // Handle isolate being null
  isolate?.kill(priority: Isolate.immediate);
  return null;
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
  Isolate isolate = await start();

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
  stop(null);
  isolate = stop(isolate); // return null
  stdout.writeln('stopped');

  // The main has a different instance of client then the
  // one in the Isolate.
  stdout.writeln('main: exiting client.integer=${client.integer}');
  assert(client.integer == 1234);

  // Because main is async use exit
  exit(0);
}
