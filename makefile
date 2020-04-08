bin/main: lib/main.dart
	dart2native $< -o $@

run: bin/main
	$<

.PHONY: analyze
analyze:
	dartanalyzer lib/main.dart

.PHONY: vm
vm:
	dart --enable-asserts lib/main.dart

.PHONY: clean
clean:
	rm -f bin/main
