#!/bin/bash

function build_no_flags() {
  docker run --rm -v "$(pwd):/go/src" \
    -w /go/src go-build-environment \
    go clean -cache && \
  docker run --rm -v "$(pwd):/go/src" \
    -w /go/src \
    -e CGO_ENABLED=0 -e GOOS=linux -e GOARCH=amd64 \
    go-build-environment \
    go build -buildmode=plugin -o "$FILENAME".so "$FILENAME".go

  restore_permission
}

function build_with_flags() {
  docker run --rm -v "$(pwd):/go/src" \
    -w /go/src go-build-environment \
    go clean -cache && \
  docker run --rm -v "$(pwd):/go/src" \
    -w /go/src go-build-environment \
    go build -buildmode=plugin -gcflags="all=-N -l" -o "$FILENAME"_with_flags.so "$FILENAME".go

  restore_permission
}

function restore_permission() {
  sudo chown -R "$USER": "$HOME" "$FILENAME".so
}

function usage() {
  # Input both filename and flags/no flags
  echo "Usage: ./build_plugin.sh filename-no-extension [no_flags|with_flags]"
}

# Parse the name of the file to be built
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

FILENAME=$1

# Parse the flags
if [ $# -eq 2 ]; then
  if [ "$2" == "no_flags" ]; then
    build_no_flags
  elif [ "$2" == "with_flags" ]; then
    build_with_flags
  else
    usage
    exit 1
  fi
else
  build_no_flags
fi