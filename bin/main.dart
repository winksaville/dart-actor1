import 'package:actor1/actor1.dart';

import 'dart:collection';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'package:async/async.dart';
import 'package:intl/intl.dart';
import 'package:args/args.dart';

ArgResults parseArgs(List<String> args) {
  ArgParser parser = ArgParser();
  parser.addOption('actor1', abbr: '1', allowed: ['local', 'isolate'],
    defaultsTo: 'isolate');
  parser.addOption('actor2', abbr: '2', allowed: ['local', 'isolate'],
    defaultsTo: 'isolate');
  parser.addFlag('help', abbr: 'h', negatable: false);

  ArgResults argResults = parser.parse(args);
  if (argResults['help']) {
    print(parser.usage);
    exit(0);
  }
  return argResults;
}

void delay(Duration duration) async {
  print('delaying...');
  await Future.delayed(duration);
  print('continuing...');
}

void main(List<String> args) async {
  ArgResults argResults = parseArgs(args);

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  // Create actor1 and a StreamQueue for reading
  // the responses from the actor.

  StreamController<int> actor1Stream = StreamController<int>();
  StreamQueue<int> actor1Queue = StreamQueue<int>(actor1Stream.stream);

  ReceivePort actor1MasterReceivePort = ReceivePort();
  MyActor actor1 = MyActor('actor1', actor1MasterReceivePort.sendPort);
  await actor1.start(local: argResults['actor1'] == 'local');
  SendPort actor1ToActorSendPort = null;
  actor1MasterReceivePort.listen((msg) {
    switch (msg[ActorCmd]) {
      case ActorCmd.sendPort:
        print('actor1MasterReceivePort: got ActorCmd.sendPort');
        assert(msg[ActorCmd.data] is SendPort);
        actor1ToActorSendPort = msg[ActorCmd.data];
        break;
      case ActorCmd.connected:
        print('actor1MasterReceivePort: connected msg=${msg}');
        actor1Stream.add(1);
        break;
      case ActorCmd.stopEchoResult:
        print('actor1MasterReceivePort: stopEchoResult msg=${msg}');
        actor1Stream.add(msg[ActorCmd.data]);
        break;
      default:
        print('actor1MasterReceivePort: unsupported msg=${msg}');
    }
  });

  // We need to wait because actor2 assumes actor1 has already started.
  // There should probably be a central actor manager which would allow
  // one actor to wait for a specific set of actors to be running.
  print('actor1Queue.next');
  int a1 = await actor1Queue.next;
  print('actor1Queue.next a1=${a1}');
  assert(a1 == 1);

  // Create actor2 and a StreamQueue for reading
  // the responses from the actor.

  StreamController<int> actor2Stream = StreamController<int>();
  StreamQueue<int> actor2Queue = StreamQueue<int>(actor2Stream.stream);

  ReceivePort actor2MasterReceivePort = ReceivePort();
  MyActor actor2 = MyActor('actor2', actor2MasterReceivePort.sendPort);
  await actor2.start(local: argResults['actor2'] == 'local');
  SendPort actor2ToActorSendPort = null;
  actor2MasterReceivePort.listen((msg) {
    switch (msg[ActorCmd]) {
      case ActorCmd.sendPort:
        print('actor2MasterReceivePort: got ActorCmd.sendPort');
        assert(msg[ActorCmd.data] is SendPort);
        actor2ToActorSendPort = msg[ActorCmd.data];

        // Ask actor2 to connect to actor1
        actor2ToActorSendPort.send({
          ActorCmd: ActorCmd.connectToPeer,
          ActorCmd.data: actor1ToActorSendPort,
        });
        break;
      case ActorCmd.connected:
        print('actor1MasterReceivePort: connected msg=${msg}');
        actor2Stream.add(1);
        break;
      case ActorCmd.connectedToPeer:
        print('actor2MasterReceivePort: connectedToPeer msg=${msg}');
        actor2Stream.add(2);
        break;
      case ActorCmd.stopEchoResult:
        print('actor2MasterReceivePort: stopEchoResult msg=${msg}');
        actor2Stream.add(msg[ActorCmd.data]);
        break;
      default:
        print('actor2MasterReceivePort: unsupported msg=${msg}');
    }
  });

  print('actor2 wait for connected');
  int a2_1 = await actor2Queue.next;
  print('actor2 a2_1=${a2_1}');
  assert(a2_1 == 1);

  print('actor2 wait for connectedToPeer');
  int a2_2 = await actor2Queue.next;
  print('actor2 a2_2=${a2_2}');
  assert(a2_2 == 2);

  int beforeStart = stopwatch.elapsedMicroseconds;

  // Start the echo test
  print('Starting echo test');
  var msg = {ActorCmd: ActorCmd.startEcho, ActorCmd.data: 1};
  print('msg = ${msg.runtimeType}');
  dynamic msgIs = msg is LinkedHashMap;
  print('msgIs=${msgIs}');
  actor1ToActorSendPort.send(msg); //{ActorCmd: ActorCmd.startEcho, ActorCmd.data: 1});
  actor2ToActorSendPort.send({ActorCmd: ActorCmd.startEcho, ActorCmd.data: 2});

  // Tell the user what to do to stop
  stdin.echoMode = false;
  stdin.lineMode = false;
  print('Press any key to stop:');
  await stdin.first;
  int done = stopwatch.elapsedMicroseconds;

  // Stop the echo test
  print('Stop echo test');
  actor1ToActorSendPort.send({ActorCmd: ActorCmd.stopEcho});
  actor2ToActorSendPort.send({ActorCmd: ActorCmd.stopEcho});

  print('actor1 reading echoCounter');
  actor1.echoCounter = await actor1Queue.next;
  print('actor1.echoCounter=${actor1.echoCounter}');

  print('actor2 reading echoCounter');
  actor2.echoCounter = await actor2Queue.next;
  print('actor2.echoCounter=${actor2.echoCounter}');

  //await delay(Duration(microseconds: 1000));

  // Stop the client
  print('stopping');
  actor1.stop();
  actor2.stop();
  print('stopped ${actor1.echoCounter} ${actor2.echoCounter}');

  // Print time
  int msgCounter = actor1.echoCounter + actor2.echoCounter;
  double totalSecs = (done.toDouble() - beforeStart.toDouble()) / 1000000.0;
  double rate = msgCounter.toDouble() / totalSecs;
  NumberFormat f3digits = NumberFormat('###,###.00#');
  NumberFormat f0digit = NumberFormat('###,###');
  print(
    'Total time=${f3digits.format(totalSecs)} secs '
    'msgs=${f0digit.format(msgCounter)} '
    'rate=${f0digit.format(rate)} msgs/sec');

  exit(0);
}
