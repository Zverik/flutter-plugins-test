#!/bin/sh
set -e -u
if [ $# -lt 1 ]; then
  echo Usage: $0 [c] plugin_path
  exit 1
fi

PROJ_DIR="$(cd "$(dirname "$0")/.." > /dev/null; pwd -P)"

if [ "$1" == "c" ]; then
  echo Compiling...
  cd "$PROJ_DIR/plugins"
  dart package_plugins.dart
  shift
fi

cd "$PROJ_DIR"
flutter test tool/test_plugin.dart --dart-define "PLUGIN=$1"
