#!/bin/sh
set -eu
generator=$1
verify=$2
compiler=$3
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
for mode in ml mli; do
  "$generator" "$mode" ../../protocol/protocol.yml > "$tmp/first.$mode"
  "$generator" "$mode" ../../protocol/protocol.yml > "$tmp/second.$mode"
  cmp "$tmp/first.$mode" "$tmp/second.$mode"
  cmp "$tmp/first.$mode" "../../lib/api.$mode"
done
echo 'PASS protocol fresh CLI generation is deterministic and matches built API'
cat ../../protocol/protocol.yml > "$tmp/protocol.yml"
printf '\n' >> "$tmp/protocol.yml"
if "$verify" check "$tmp/protocol.yml" ../../protocol/provenance.json > "$tmp/hash-error" 2>&1; then
  echo 'changed schema incorrectly accepted' >&2; exit 1
fi
grep -q 'SHA-256 mismatch' "$tmp/hash-error"
sed 's/"version": "1.59.1"/"version": "1.59.2"/' ../../protocol/provenance.json > "$tmp/provenance.json"
if "$verify" check ../../protocol/protocol.yml "$tmp/provenance.json" > "$tmp/version-error" 2>&1; then
  echo 'mismatching source/version incorrectly accepted' >&2; exit 1
fi
grep -q 'source URL does not match version' "$tmp/version-error"
echo 'PASS protocol offline provenance rejects modified schema and version'
# Check the *public compiled signature*, including negative cases. The positive
# control ensures a missing compiler/interface cannot masquerade as rejection.
printf '%s\n' 'let attached h = Playwright.ElementHandle.wait_for_selector ~selector:"x" ~state:`Attached h' \
  'let console c = Playwright.BrowserContext.update_subscription ~event:`Console ~enabled:true c' > "$tmp/positive.ml"
"$compiler" -I ../../lib/.playwright.objs/byte -c "$tmp/positive.ml"
printf '%s\n' 'let wrong h = Playwright.ElementHandle.wait_for_selector ~selector:"x" ~state:`Enabled h' > "$tmp/state.ml"
printf '%s\n' 'let wrong c = Playwright.BrowserContext.update_subscription ~event:`Action_added ~enabled:true c' > "$tmp/subscription.ml"
for source in state subscription; do
  if "$compiler" -I ../../lib/.playwright.objs/byte -c "$tmp/$source.ml" > "$tmp/$source.error" 2>&1; then
    echo "incompatible $source enum incorrectly compiled" >&2; exit 1
  fi
  grep -q 'does not allow tag' "$tmp/$source.error"
done
echo 'PASS protocol incompatible selector and subscription enums fail compilation'
