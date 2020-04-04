# Simple isolate example in dart

Based on [this](https://codingwithjoe.com/dart-fundamentals-isolates/) from
[Coding With Joe](codingwithjost.com).

Right now on my desktop I'm seeing about 225,000 msgs/sec, the client is
sending the integer counter the two isolates.

## Build main
Install newer dart with dart2native compiler
```
$ make
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/isolate-example/bin/main
```

## Run

Build main if not already built then run it
```
$ make run
bin/main
Press any key to stop:
client: done
RECEIVE: responsePort
Total time=4.398 secs msgs=990,734 rate=225,275 msgs/sec
stopping
stopped
```

## Clean
```
$ make clean
rm -f main
```

You can compbine them too
```
$ make clean run
rm -f bin/main
dart2native lib/main.dart -o bin/main
Generated: /home/wink/prgs/dart/isolate-example/bin/main
bin/main
Press any key to stop:
client: done
RECEIVE: responsePort
Total time=2.693 secs msgs=585,980 rate=217,592 msgs/sec
stopping
stopped

```
