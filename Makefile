.PHONY: gen-mocks
gen-mocks:
	./scripts/gen-mocks.sh

.PHONY: format
format:
	./scripts/swiftformat.sh

.PHONY: lint
lint:
	./scripts/swiftlint.sh
