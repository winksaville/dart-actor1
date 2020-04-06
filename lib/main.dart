// Based on [this](https://github.com/winksaville/dart-isolate-example)

// Currentlly creates two actors and they can communicate with the "master".
// The next goal is to implement the "connect" command so the two actors
// can communicate directly with them selves.

import 'dart:io';
//import 'dart:async';
import 'dart:isolate';
//import 'package:intl/intl.dart';

/// Commands actors support
/// A message is a Map with a key of ActorCmd whose
/// name is one of the following enumerations
enum ActorCmd {
  sendPort,  /// ActorCmd.data is the SendPort
  data,      /// ActorCmd.data is some data
  connect,   /// ActorCmd.data is TBD
}

/// Actor that can process messages
abstract class ActorBase {
  String name;
  Isolate isolate;

  SendPort _toMasterSendPort;
  ReceivePort _fromMasterReceivePort;

  /// Contruct an actor passing a SendPort which is used
  /// by the client to send messages to the ReceivePort.
  ActorBase(String this.name, SendPort this._toMasterSendPort);

  /// Start the actor. When the actor starts _enter will
  /// it will create a ReceivePort and send the SendPort
  /// back to the master.
  void start({bool locally=false}) async {
    if (locally) {
      isolate = Isolate.current;
      _entryPoint(this);
    } else {
      isolate = await Isolate.spawn<ActorBase>(ActorBase._entryPoint, this);
    }
  }

  /// Stop the actor immediately if its not a local actor.
  void stop() {
    // Handle isolate being null
    if ((isolate != null) && (isolate != Isolate.current)) {
      isolate.kill(priority: Isolate.immediate);
    }
  }

  /// Invoked by when the actor starts.
  static void _entryPoint(ActorBase actor) {
    stdout.writeln('${actor.name}.entryPoint:+');
    actor._enter();
    actor._begin();
    actor._listen();
    stdout.writeln('${actor.name}.entryPoint:-');
  }

  /// Called once when Actor is first invoked and usually
  /// Sets up communication with the partner
  void _enter() {
    // Create a port that will receive messages
    _fromMasterReceivePort =  ReceivePort();
    _toMasterSendPort.send({
      ActorCmd: ActorCmd.sendPort,
      ActorCmd.data: _fromMasterReceivePort.sendPort
    });
  }

  /// Invoked once when the actor is first started after
  /// _enter and before the first call to _process.
  void _begin() {}

  void _listen() {
    assert(_fromMasterReceivePort != null);
    _fromMasterReceivePort.listen(_process);
  }

  /// Invoked everytime a message arrives from the partner
  /// and must be overridden
  void _process(message);
}

class MyActor extends ActorBase {
  int counter = 0;

  MyActor(String name, SendPort masterPort) : super(name, masterPort);

  @override
  void _begin() {
  }

  @override
  void _process(dynamic msg) {
    switch (msg[ActorCmd]) {
      case ActorCmd.sendPort:
        stdout.writeln('${name}._process: sendPort data=${msg[ActorCmd.data]}');
        break;
      case ActorCmd.connect:
        stdout.writeln('${name}._process: connect data=${msg[ActorCmd.data]}');
        break;
      case ActorCmd.data:
        stdout.writeln('${name}._process: data data=${msg[ActorCmd.data]}');
        break;
    }
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

  //int beforeStart = stopwatch.elapsedMicroseconds;

  // Create actor1
  ReceivePort actor1MasterReceivePort = ReceivePort();
  MyActor actor1 = MyActor('actor1', actor1MasterReceivePort.sendPort);
  await actor1.start(locally: false);
  SendPort actor1ToActorSendPort = null;
  actor1MasterReceivePort.listen((msg) {
    switch (msg[ActorCmd]) {
      case ActorCmd.sendPort:
        stdout.writeln('actor1MasterReceivePort: got ActorCmd.sendPort');
        assert(msg[ActorCmd.data] is SendPort);
        actor1ToActorSendPort = msg[ActorCmd.data];
        actor1ToActorSendPort.send({
          ActorCmd: ActorCmd.data,
          ActorCmd.data: "Yo Dude",
        });
        break;
      case ActorCmd.connect:
        stdout.writeln('actor1MasterReceivePort: connect msg=${msg}');
        break;
      case ActorCmd.data:
        stdout.writeln('actor1MasterReceivePort: data msg=${msg}');
        break;
      default:
        stdout.writeln('actor1MasterReceivePort: unknown msg=${msg}');
    }
  });

  // Create actor2
  ReceivePort actor2MasterReceivePort = ReceivePort();
  MyActor actor2 = MyActor('actor2', actor2MasterReceivePort.sendPort);
  await actor2.start(locally: false);
  SendPort actor2ToActorSendPort = null;
  actor2MasterReceivePort.listen((msg) {
    switch (msg[ActorCmd]) {
      case ActorCmd.sendPort:
        stdout.writeln('actor2MasterReceivePort: got ActorCmd.sendPort');
        assert(msg[ActorCmd.data] is SendPort);
        actor2ToActorSendPort = msg[ActorCmd.data];
        actor2ToActorSendPort.send({
          ActorCmd: ActorCmd.data,
          ActorCmd.data: "Yo Bro",
        });
        break;
      case ActorCmd.connect:
        stdout.writeln('actor2MasterReceivePort: connect msg=${msg}');
        break;
      case ActorCmd.data:
        stdout.writeln('actor2MasterReceivePort: data msg=${msg}');
        break;
      default:
        stdout.writeln('actor2MasterReceivePort: unknown msg=${msg}');
    }
  });

  //// Wait for any key
  //int afterStart = stopwatch.elapsedMicroseconds;
  await stdin.first;
  //int done = stopwatch.elapsedMicroseconds;

  //// Stop the client
  //stdout.writeln('stopping');
  //result.client.stop();
  //result.server.stop();
  //stdout.writeln('stopped');

  //// Print time
  //int msgCounter = result.client.counter + result.server.counter;
  //double totalSecs = (done.toDouble() - beforeStart.toDouble()) / 1000000.0;
  //double rate = msgCounter.toDouble() / totalSecs;
  //NumberFormat f3digits = NumberFormat('###,###.00#');
  //NumberFormat f0digit = NumberFormat('###,###');
  //stdout.writeln(
  //  'Total time=${f3digits.format(totalSecs)} secs '
  //  'msgs=${f0digit.format(msgCounter)} '
  //  'rate=${f0digit.format(rate)} msgs/sec');

  // Because main is async use exit
  exit(0);
}
