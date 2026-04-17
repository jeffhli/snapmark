#!/bin/bash
set -euo pipefail

echo "Building SnapMark app bundle (debug)..."
"$(dirname "$0")/build.sh" debug

echo "Opening SnapMark..."
open build/SnapMark.app
