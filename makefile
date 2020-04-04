bin/main: lib/main.dart
	dart2native $< -o $@

run: bin/main
	$<

.PHONY: vm
vm:
	dart lib/main.dart

.PHONY: clean
clean:
	rm -f bin/main
