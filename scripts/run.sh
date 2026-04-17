#!/bin/bash
set -euo pipefail

echo "Building SnapMark (debug)..."
swift build

echo "Running SnapMark..."
.build/debug/SnapMark
