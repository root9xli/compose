# Copyright 2023 Compose Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

BINARY ?= docker-compose
GO ?= go
GOFLAGS ?= -mod=vendor
GOOS ?= $(shell go env GOOS)
GOARCH ?= $(shell go env GOARCH)

GIT_TAG ?= $(shell git describe --tags --match 'v[0-9]*' --dirty='.m' --always 2>/dev/null || echo "dev")
GIT_COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

LD_FLAGS := -s -w \
	-X github.com/docker/compose/v2/internal.Version=$(GIT_TAG) \
	-X github.com/docker/compose/v2/internal.GitCommit=$(GIT_COMMIT) \
	-X github.com/docker/compose/v2/internal.BuildDate=$(BUILD_DATE)

OUTPUT_DIR ?= ./bin

# Default test flags: run tests in parallel with a timeout
TEST_FLAGS ?= -v -count=1 -timeout 120s

.PHONY: all
all: build

## build: Build the binary
.PHONY: build
build:
	@echo "Building $(BINARY) ($(GIT_TAG))..."
	@mkdir -p $(OUTPUT_DIR)
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) \
		$(GO) build $(GOFLAGS) \
		-ldflags "$(LD_FLAGS)" \
		-o $(OUTPUT_DIR)/$(BINARY) \
		./cmd/compose

## test: Run unit tests
.PHONY: test
test:
	@echo "Running unit tests..."
	$(GO) test $(GOFLAGS) ./... $(TEST_FLAGS)

## test-coverage: Run tests with coverage report
.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	$(GO) test $(GOFLAGS) ./... -coverprofile=coverage.out -covermode=atomic
	$(GO) tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated at coverage.html"

## lint: Run linters
.PHONY: lint
lint:
	@echo "Running linters..."
	golangci-lint run ./...

## fmt: Format source code
.PHONY: fmt
fmt:
	$(GO) fmt ./...

## vet: Run go vet
.PHONY: vet
vet:
	$(GO) vet $(GOFLAGS) ./...

## vendor: Tidy and vendor dependencies
.PHONY: vendor
vendor:
	$(GO) mod tidy
	$(GO) mod vendor

## clean: Remove build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(OUTPUT_DIR)
	rm -f coverage.out coverage.html

## install: Install the binary to GOPATH/bin
.PHONY: install
install:
	@echo "Installing $(BINARY)..."
	CGO_ENABLED=0 $(GO) install $(GOFLAGS) \
		-ldflags "$(LD_FLAGS)" \
		./cmd/compose

## help: Display this help message
.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'
