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
actor1MasterReceivePort: got ActorCmd.sendPort
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor1Running: value=true
actor1 is running
actor2: isolate
Press any key to stop:
actor2MasterReceivePort: got ActorCmd.sendPort
actor2MasterReceivePort: unsupported msg={ActorCmd: ActorCmd.connected}
actor2._process: connectToPeer data=SendPort
actor1._process: connectFromPeer data=SendPort
actor2._process: connected msg={ActorCmd: ActorCmd.connected, ActorCmd.data: SendPort}
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
actor1MasterReceivePort: got ActorCmd.sendPort
actor1MasterReceivePort: connected msg={ActorCmd: ActorCmd.connected}
actor1Running: value=true
actor1 is running
actor2: isolate
Press any key to stop:
actor2MasterReceivePort: got ActorCmd.sendPort
actor2MasterReceivePort: unsupported msg={ActorCmd: ActorCmd.connected}
actor2._process: connectToPeer data=SendPort
actor1._process: connectFromPeer data=SendPort
actor2._process: connected msg={ActorCmd: ActorCmd.connected, ActorCmd.data: SendPort}
```
