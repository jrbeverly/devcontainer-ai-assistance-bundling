#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

mkdir -p ../.claude/corpus
cp source/*.md ../.claude/corpus/
