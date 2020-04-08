bin/main: bin/main.dart
	dart2native $< -o $@

run: bin/main
	$<

.PHONY: analyze
analyze:
	dartanalyzer bin/main.dart

.PHONY: vm
vm:
	dart --enable-asserts bin/main.dart

.PHONY: clean
clean:
	rm -f bin/main
