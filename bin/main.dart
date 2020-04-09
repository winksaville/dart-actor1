import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:async/async.dart';
import 'package:intl/intl.dart';
import 'package:args/args.dart';

import 'package:actor1/actor1.dart';


ArgResults parseArgs(List<String> args) {
  final ArgParser parser = ArgParser();
  final List<String> validValues = <String>['local', 'iosolate'];
  parser.addOption('actor1', abbr: '1', allowed: validValues,
    defaultsTo: 'isolate');
  parser.addOption('actor2', abbr: '2', allowed: validValues,
    defaultsTo: 'isolate');
  parser.addFlag('help', abbr: 'h', negatable: false);

  final ArgResults argResults = parser.parse(args);
  if (argResults['help'] == true) {
    print(parser.usage);
    exit(0);
  }
  return argResults;
}

Future<Duration> delay(Duration duration) async {
    return Future<Duration>.delayed(duration);
}

Future<void> main(List<String> args) async {
  final ArgResults argResults = parseArgs(args);

  final Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  // Create actor1 and a StreamQueue for reading
  // the responses from the actor.

  final StreamController<int> actor1Stream = StreamController<int>();
  final StreamQueue<int> actor1Queue = StreamQueue<int>(actor1Stream.stream);

  final ReceivePort actor1MasterReceivePort = ReceivePort();
  final MyActor actor1 = MyActor('actor1', actor1MasterReceivePort.sendPort);
  await actor1.start(local: argResults['actor1'] == 'local');
  SendPort actor1ToActorSendPort;
  actor1MasterReceivePort.listen((dynamic msg) {
    switch (msg[ActorCmd.op] as ActorCmd) {
      case ActorCmd.sendPort:
        print('actor1MasterReceivePort: got ActorCmd.sendPort');
        assert(msg[ActorCmd.data] is SendPort);
        actor1ToActorSendPort = msg[ActorCmd.data] as SendPort;
        break;
      case ActorCmd.connected:
        print('actor1MasterReceivePort: connected msg=$msg');
        actor1Stream.add(1);
        break;
      case ActorCmd.stopEchoResult:
        print('actor1MasterReceivePort: stopEchoResult msg=$msg');
        actor1Stream.add(msg[ActorCmd.data] as int);
        break;
      default:
        print('actor1MasterReceivePort: unsupported msg=$msg');
    }
  });

  // We need to wait because actor2 assumes actor1 has already started.
  // There should probably be a central actor manager which would allow
  // one actor to wait for a specific set of actors to be running.
  print('actor1Queue.next');
  final int a1 = await actor1Queue.next;
  print('actor1Queue.next a1=$a1');
  assert(a1 == 1);

  // Create actor2 and a StreamQueue for reading
  // the responses from the actor.

  final StreamController<int> actor2Stream = StreamController<int>();
  final StreamQueue<int> actor2Queue = StreamQueue<int>(actor2Stream.stream);

  final ReceivePort actor2MasterReceivePort = ReceivePort();
  final MyActor actor2 = MyActor('actor2', actor2MasterReceivePort.sendPort);
  await actor2.start(local: argResults['actor2'] == 'local');
  SendPort actor2ToActorSendPort;
  actor2MasterReceivePort.listen((dynamic msg) {
    switch (msg[ActorCmd.op] as ActorCmd) {
      case ActorCmd.sendPort:
        print('actor2MasterReceivePort: got ActorCmd.sendPort');
        assert(msg[ActorCmd.data] is SendPort);
        actor2ToActorSendPort = msg[ActorCmd.data] as SendPort;

        // Ask actor2 to connect to actor1
        actor2ToActorSendPort.send(<ActorCmd, dynamic>{
          ActorCmd.op: ActorCmd.connectToPeer,
          ActorCmd.data: actor1ToActorSendPort,
        });
        break;
      case ActorCmd.connected:
        print('actor1MasterReceivePort: connected msg=$msg');
        actor2Stream.add(1);
        break;
      case ActorCmd.connectedToPeer:
        print('actor2MasterReceivePort: connectedToPeer msg=$msg');
        actor2Stream.add(2);
        break;
      case ActorCmd.stopEchoResult:
        print('actor2MasterReceivePort: stopEchoResult msg=$msg');
        actor2Stream.add(msg[ActorCmd.data] as int);
        break;
      default:
        print('actor2MasterReceivePort: unsupported msg=$msg');
    }
  });

  print('actor2 wait for connected');
  final int a2_1 = await actor2Queue.next;
  assert(a2_1 == 1);

  print('actor2 wait for connectedToPeer');
  final int a2_2 = await actor2Queue.next;
  assert(a2_2 == 2);

  final int beforeStart = stopwatch.elapsedMicroseconds;

  // Start the echo test
  print('Starting echo test');
  actor1ToActorSendPort.send(<ActorCmd, dynamic>{ActorCmd.op: ActorCmd.startEcho, ActorCmd.data: 1});
  actor2ToActorSendPort.send(<ActorCmd, dynamic>{ActorCmd.op: ActorCmd.startEcho, ActorCmd.data: 2});

  // Tell the user what to do to stop
  try {
    stdin.echoMode = false;
    stdin.lineMode = false;
    print('Press any key to stop:');
  } catch (e) {
    print('Prese RETURN TWICE to stop:');
  }
  await stdin.first;
  final int done = stopwatch.elapsedMicroseconds;

  // Stop the echo test
  print('Stop echo test');
  actor1ToActorSendPort.send(<ActorCmd, dynamic>{ActorCmd.op: ActorCmd.stopEcho});
  actor2ToActorSendPort.send(<ActorCmd, dynamic>{ActorCmd.op: ActorCmd.stopEcho});

  print('actor1 reading echoCounter');
  actor1.echoCounter = await actor1Queue.next;
  print('actor1.echoCounter=${actor1.echoCounter}');

  print('actor2 reading echoCounter');
  actor2.echoCounter = await actor2Queue.next;
  print('actor2.echoCounter=${actor2.echoCounter}');

  await delay(const Duration(microseconds: 1000));

  // Stop the client
  print('stopping');
  actor1.stop();
  actor2.stop();
  print('stopped ${actor1.echoCounter} ${actor2.echoCounter}');

  // Print time
  final int msgCounter = actor1.echoCounter + actor2.echoCounter;
  final double totalSecs = (done.toDouble() - beforeStart.toDouble()) / 1000000.0;
  final double rate = msgCounter.toDouble() / totalSecs;
  final NumberFormat f3digits = NumberFormat('###,###.00#');
  final NumberFormat f0digit = NumberFormat('###,###');
  print(
    'Total time=${f3digits.format(totalSecs)} secs '
    'msgs=${f0digit.format(msgCounter)} '
    'rate=${f0digit.format(rate)} msgs/sec');

  exit(0);
}
