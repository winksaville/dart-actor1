bin/main: bin/main.dart lib/actor1.dart
	dart2native bin/main.dart -o $@

run: bin/main
	$<

.PHONY: analyze
analyze:
	dartanalyzer bin/main.dart lib/actor1.dart

.PHONY: vm
vm:
	dart --enable-asserts bin/main.dart

.PHONY: clean
clean:
	rm -f bin/main
