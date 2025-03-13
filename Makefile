.PHONY: run
run: build
	(source .env && iex -S mix)

.PHONY: watch
watch:
	cargo watch -C . -s "make test && mix dialyzer --format dialyxir && make format"

.PHONY: test
test: build
	mix test

.PHONY: format
format:
	mix format --check-formatted

.PHONY: build
build:
	mix deps.get
	mix compile --warnings-as-errors
