# My first attempt at an Actor for dart

Based on [my initial isolate exploration](https://github.com/winksaville/dart-isolate-example.git).

At the moment it just creates two instances of MyActor
and connects them together. An Actor can be started in
the current isolate using 'local' or or in a new isolate
using 'isolate' which is the default. This can be selected
from the command line using the option --actorX or -X options.

Here is the usage help:
```
$ ./bin/main -h
-1, --actor1    [local, isolate (default)]
-2, --actor2    [local, isolate (default)]
-h, --help     
```

## Build main
Install newer dart with dart2native compiler
```
$ make
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/actor1/bin/main
```

## Run

Build main if not already built then run it
```
$ make run
bin/main
actor1: isolate
actor1Queue.next
actor1: sending ActorCmd.connected
actor1MasterReceivePort: got ActorCmd.sendPort
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor1Queue.next a1=1
actor2: isolate
actor2 wait for connected
actor2: sending ActorCmd.connected
actor2MasterReceivePort: got ActorCmd.sendPort
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor2._process:+ connectToPeer data=SendPort
actor2._process:+ connectToPeer _peerSendPort == null
actor2 a2_1=1
actor2 wait for connectedToPeer
actor2._process:- connectToPeer _peerSendPort == null
actor2._process:- connectToPeer data=SendPort
actor1._process:+ connectFromPeer data=SendPort
actor1._process:+ connectFromPeer _peerSendPort == null
actor1._process:- connectFromPeer _peerSendPort == null
actor1._process:- connectFromPeer data=SendPort
actor2._process:+ peerIsConnected msg={ActorCmd: ActorCmd.peerIsConnected, ActorCmd.data: SendPort}
actor2._process: 1 peerIsConnected
actor2._process:- peerIsConnected msg={ActorCmd: ActorCmd.peerIsConnected, ActorCmd.data: SendPort}
actor2MasterReceivePort: connectedToPeer msg={ActorCmd: ActorCmd.connectedToPeer}
actor2 a2_2=2
Starting echo test
Press any key to stop:
actor2._process: startEcho {ActorCmd: ActorCmd.startEcho, ActorCmd.data: 2}
actor1._process: startEcho {ActorCmd: ActorCmd.startEcho, ActorCmd.data: 1}
Stop echo test
actor1 reading echoCounter
actor1._process: stopEcho {ActorCmd: ActorCmd.stopEcho}
actor2._process: stopEcho {ActorCmd: ActorCmd.stopEcho}
actor1MasterReceivePort: stopEchoResult msg={ActorCmd: ActorCmd.stopEchoResult, ActorCmd.data: 235962}
actor1.echoCounter=235962
actor2 reading echoCounter
actor2MasterReceivePort: stopEchoResult msg={ActorCmd: ActorCmd.stopEchoResult, ActorCmd.data: 235963}
actor2.echoCounter=235963
stopping
stopped 235962 235963
Total time=2.989 secs msgs=471,925 rate=157,904 msgs/sec
```
Run using the dart virtual machine with asserts enabled:
```
$ make vm
dart --enable-asserts lib/main.dart
lib/main.dart: Warning: Interpreting this as package URI, 'package:actor1/main.dart'.
actor1: isolate
actor1Queue.next
actor1: sending ActorCmd.connected
actor1MasterReceivePort: got ActorCmd.sendPort
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor1Queue.next a1=1
actor2: isolate
actor2 wait for connected
actor2MasterReceivePort: got ActorCmd.sendPort
actor2: sending ActorCmd.connected
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor2 a2_1=1
actor2 wait for connectedToPeer
actor2._process:+ connectToPeer data=SendPort
actor2._process:+ connectToPeer _peerSendPort == null
actor2._process:- connectToPeer _peerSendPort == null
actor2._process:- connectToPeer data=SendPort
actor1._process:+ connectFromPeer data=SendPort
actor1._process:+ connectFromPeer _peerSendPort == null
actor1._process:- connectFromPeer _peerSendPort == null
actor1._process:- connectFromPeer data=SendPort
actor2._process:+ peerIsConnected msg={ActorCmd: ActorCmd.peerIsConnected, ActorCmd.data: SendPort}
actor2._process: 1 peerIsConnected
actor2._process:- peerIsConnected msg={ActorCmd: ActorCmd.peerIsConnected, ActorCmd.data: SendPort}
actor2MasterReceivePort: connectedToPeer msg={ActorCmd: ActorCmd.connectedToPeer}
actor2 a2_2=2
Starting echo test
Press any key to stop:
actor2._process: startEcho {ActorCmd: ActorCmd.startEcho, ActorCmd.data: 2}
actor1._process: startEcho {ActorCmd: ActorCmd.startEcho, ActorCmd.data: 1}
Stop echo test
actor1 reading echoCounter
actor1._process: stopEcho {ActorCmd: ActorCmd.stopEcho}
actor2._process: stopEcho {ActorCmd: ActorCmd.stopEcho}
actor1MasterReceivePort: stopEchoResult msg={ActorCmd: ActorCmd.stopEchoResult, ActorCmd.data: 207652}
actor1.echoCounter=207652
actor2 reading echoCounter
actor2MasterReceivePort: stopEchoResult msg={ActorCmd: ActorCmd.stopEchoResult, ActorCmd.data: 207653}
actor2.echoCounter=207653
stopping
stopped 207652 207653
Total time=2.64 secs msgs=415,305 rate=157,341 msgs/sec
```

After building you can run directly and pass parameter.
Here I have both actors run "local", i.e. in the same
isolate as main. NOTE: With 
```
$ ./bin/main -1 local -2 local
actor1: local
actor1: sending ActorCmd.connected
actor1Queue.next
actor1MasterReceivePort: got ActorCmd.sendPort
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor1Queue.next a1=1
actor2: local
actor2: sending ActorCmd.connected
actor2 wait for connected
actor2MasterReceivePort: got ActorCmd.sendPort
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor2 a2_1=1
actor2 wait for connectedToPeer
actor2._process:+ connectToPeer data=SendPort
actor2._process:+ connectToPeer _peerSendPort == null
actor2._process:- connectToPeer _peerSendPort == null
actor2._process:- connectToPeer data=SendPort
actor1._process:+ connectFromPeer data=SendPort
actor1._process:+ connectFromPeer _peerSendPort == null
actor1._process:- connectFromPeer _peerSendPort == null
actor1._process:- connectFromPeer data=SendPort
actor2._process:+ peerIsConnected msg={ActorCmd: ActorCmd.peerIsConnected, ActorCmd.data: SendPort}
actor2._process: 1 peerIsConnected
actor2._process:- peerIsConnected msg={ActorCmd: ActorCmd.peerIsConnected, ActorCmd.data: SendPort}
actor2MasterReceivePort: connectedToPeer msg={ActorCmd: ActorCmd.connectedToPeer}
actor2 a2_2=2
Starting echo test
Press any key to stop:
actor1._process: startEcho {ActorCmd: ActorCmd.startEcho, ActorCmd.data: 1}
actor2._process: startEcho {ActorCmd: ActorCmd.startEcho, ActorCmd.data: 2}
Stop echo test
actor1 reading echoCounter
actor1._process: stopEcho {ActorCmd: ActorCmd.stopEcho}
actor2._process: stopEcho {ActorCmd: ActorCmd.stopEcho}
actor1MasterReceivePort: stopEchoResult msg={ActorCmd: ActorCmd.stopEchoResult, ActorCmd.data: 443551}
actor1.echoCounter=443551
actor2 reading echoCounter
actor2MasterReceivePort: stopEchoResult msg={ActorCmd: ActorCmd.stopEchoResult, ActorCmd.data: 443552}
actor2.echoCounter=443552
stopping
stopped 443551 443552
Total time=5.593 secs msgs=887,103 rate=158,612 msgs/sec```
```

## Clean
```
$ make clean
rm -f bin/main
```

You can compbine them too
```
$ make clean run
rm -f bin/main
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/actor1/bin/main
bin/main
actor1: isolate
actor1Queue.next
actor1: sending ActorCmd.connected
actor1MasterReceivePort: got ActorCmd.sendPort
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor1Queue.next a1=1
actor2: isolate
actor2 wait for connected
actor2: sending ActorCmd.connected
actor2MasterReceivePort: got ActorCmd.sendPort
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor2._process:+ connectToPeer data=SendPort
actor2._process:+ connectToPeer _peerSendPort == null
actor2 a2_1=1
actor2 wait for connectedToPeer
actor2._process:- connectToPeer _peerSendPort == null
actor2._process:- connectToPeer data=SendPort
actor1._process:+ connectFromPeer data=SendPort
actor1._process:+ connectFromPeer _peerSendPort == null
actor1._process:- connectFromPeer _peerSendPort == null
actor1._process:- connectFromPeer data=SendPort
actor2._process:+ peerIsConnected msg={ActorCmd: ActorCmd.peerIsConnected, ActorCmd.data: SendPort}
actor2._process: 1 peerIsConnected
actor2._process:- peerIsConnected msg={ActorCmd: ActorCmd.peerIsConnected, ActorCmd.data: SendPort}
actor2MasterReceivePort: connectedToPeer msg={ActorCmd: ActorCmd.connectedToPeer}
actor2 a2_2=2
Starting echo test
Press any key to stop:
actor2._process: startEcho {ActorCmd: ActorCmd.startEcho, ActorCmd.data: 2}
actor1._process: startEcho {ActorCmd: ActorCmd.startEcho, ActorCmd.data: 1}
Stop echo test
actor1 reading echoCounter
actor1._process: stopEcho {ActorCmd: ActorCmd.stopEcho}
actor2._process: stopEcho {ActorCmd: ActorCmd.stopEcho}
actor1MasterReceivePort: stopEchoResult msg={ActorCmd: ActorCmd.stopEchoResult, ActorCmd.data: 715784}
actor1.echoCounter=715784
actor2 reading echoCounter
actor2MasterReceivePort: stopEchoResult msg={ActorCmd: ActorCmd.stopEchoResult, ActorCmd.data: 715785}
actor2.echoCounter=715785
stopping
stopped 715784 715785
Total time=9.162 secs msgs=1,431,569 rate=156,259 msgs/sec
```
