# SPDX-FileCopyrightText: 2020-present Open Networking Foundation <info@opennetworking.org>
#
# SPDX-License-Identifier: Apache-2.0
# Copyright 2024 Kyunghee University

export CGO_ENABLED=1
export GO111MODULE=on

.PHONY: build

TARGET := onos-lib-go
ONOS_PROTOC_VERSION := v0.6.9

build: # @HELP build the Go binaries (default)
build:
	go build github.com/onosproject/${TARGET}/pkg/...

build-tools:=$(shell if [ ! -d "./build/build-tools" ]; then cd build && git clone https://github.com/onosproject/build-tools.git; fi)
include ./build/build-tools/make/onf-common.mk

mod-update: # @HELP Download the dependencies to the vendor folder
	go mod tidy
	go mod vendor
mod-lint: mod-update # @HELP ensure that the required dependencies are in place
	# dependencies are vendored, but not committed, go.sum is the only thing we need to check
	bash -c "diff -u <(echo -n) <(git diff go.sum)"


test: # @HELP run the unit tests and source code validation  producing a golang style report
test: mod-lint build linters license
	go test -race github.com/onosproject/${TARGET}/pkg/...

#jenkins-test:  # @HELP run the unit tests and source code validation producing a junit style report for Jenkins
#jenkins-test: mod-lint build linters license
#	TEST_PACKAGES=github.com/onosproject/${TARGET}/pkg/... ./build/build-tools/build/jenkins/make-unit

protos: # @HELP compile the protobuf files (using protoc-go Docker)
	docker run -it -v `pwd`:/go/src/github.com/onosproject/${TARGET} \
		-w /go/src/github.com/onosproject/${TARGET} \
		--entrypoint build/bin/compile-protos.sh \
		onosproject/protoc-go:${ONOS_PROTOC_VERSION}

publish: # @HELP publish version on github and dockerhub
	./build/build-tools/publish-version ${VERSION}

#jenkins-publish: jenkins-tools # @HELP Jenkins calls this to publish artifacts
#	./build/build-tools/release-merge-commit
#	./build/build-tools/build/docs/push-docs

all: test

clean:: # @HELP remove all the build artifacts
	go clean -testcache github.com/onosproject/${TARGET}/...
