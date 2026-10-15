#!/usr/bin/env bash
# QuarkLangLibs-actions test entry point.
# Usage: QUARK=/path/to/quark ./tests/run.sh [filter ...]
# Requires: actions.qk at the repository root. Pure qk, no native code, no network access.
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
QUARK="${QUARK:-quark}"
if [ ! -x "$QUARK" ] && ! command -v "$QUARK" >/dev/null 2>&1; then
  echo "quark interpreter unavailable: QUARK=$QUARK" >&2
  exit 2
fi
# Plain `mktemp -d`: the template form with an explicit /tmp path is not portable to the
# Git Bash environment used on the Windows runner.
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT
cp "$ROOT/actions.qk" "$BUILD/actions.qk"

fail=0

# actions.qk is `program library`, so it cannot be executed: a successful compile that then
# reports "cannot run a library" is the pass signal for the library source itself. Without
# this the file would not be looked at by CI at all.
libout="$(cd "$BUILD" && "$QUARK" actions.qk 2>&1)"
if printf '%s' "$libout" | grep -q "cannot run a library"; then
  echo "PASS actions.qk (parse+typecheck; a library is not runnable, which is the pass signal)"
else
  fail=$((fail + 1))
  echo "FAIL actions.qk"
  printf '%s\n' "$libout" | head -4
fi

total=0
for t in "$ROOT"/tests/*.qk; do
  name="$(basename "$t" .qk)"
  if [ "$#" -gt 0 ]; then
    match=0
    for f in "$@"; do case "$name" in *"$f"*) match=1 ;; esac; done
    [ "$match" = 1 ] || continue
  fi
  total=$((total + 1))
  # The actions tests need the interpreter's own path so they can run a program that is
  # guaranteed to exist on every platform; substituting it here keeps the qk file plain.
  quark_escaped="$(printf '%s' "$QUARK" | sed 's/[&|\\]/\\&/g')"
  sed "s|__QUARK_BIN__|$quark_escaped|g" "$t" > "$BUILD/$name.qk"
  out="$(cd "$BUILD" && "$QUARK" "$name.qk" 2>&1)"
  rc=$?
  ok="$(printf '%s\n' "$out" | grep -c '^OK')"
  bad="$(printf '%s\n' "$out" | grep -c '^FAIL')"
  if [ "$rc" -ne 0 ] || [ "$bad" -ne 0 ]; then
    fail=$((fail + 1))
    echo "FAIL $name (rc=$rc ok=$ok bad=$bad)"
    printf '%s\n' "$out" | grep -E '^FAIL|error|Error' | head -4
  else
    echo "PASS $name ($ok assertions)"
  fi
done
echo "tests: $total files, failures=$fail"
[ "$fail" -eq 0 ]
