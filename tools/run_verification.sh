#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BAZEL="${BAZEL:-bazelisk}"

echo "==> Bazel unit + integration tests"
"$BAZEL" test //...

echo "==> AddressSanitizer + LeakSanitizer (C++ solvers)"
"$BAZEL" test --config=asan //cpp:solvers_test

CPP_TEST_BIN="$ROOT/bazel-bin/cpp/solvers_test"
if command -v valgrind >/dev/null 2>&1 && [[ -x "$CPP_TEST_BIN" ]]; then
  echo "==> Valgrind memcheck on $CPP_TEST_BIN"
  valgrind \
    --error-exitcode=42 \
    --leak-check=full \
    --show-leak-kinds=all \
    --track-origins=yes \
    "$CPP_TEST_BIN"
else
  echo "==> Skipping valgrind (install valgrind and ensure $CPP_TEST_BIN exists after build)"
fi

echo "Verification finished."
