# My first attempt at an Actor for dart

Based on [my initial isolate exploration](https://github.com/winksaville/dart-isolate-example.git).

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
client: running
server: running
MyServer: got partnerPort
stopping
stopped
Total time=13.376 secs msgs=19,882,440 rate=1,486,437 msgs/sec
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
Generated: /home/wink/prgs/dart/isolate-example2/bin/main
bin/main
Press any key to stop:
client: running
server: running
MyServer: got partnerPort
stopping
stopped
Total time=8.892 secs msgs=13,326,641 rate=1,498,738 msgs/sec
```
