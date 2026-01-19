PROJECT_GIT_DIR := .

.PHONY: gen-mocks
gen-mocks:
	./scripts/gen-mocks.sh

.PHONY: format
format:
	./scripts/swiftformat.sh $(PROJECT_GIT_DIR)

.PHONY: lint
lint:
	./scripts/swiftlint.sh $(PROJECT_GIT_DIR)
