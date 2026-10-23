#!/bin/bash
# Merge user defined pgBouncer parameters into a generated pgbouncer.ini.
#
# Usage: merge_parameters.sh <pgbouncer.ini>
#
# Reads the JSON object (key -> value) from $CONNECTION_POOLER_PARAMETERS and
# applies it to the [pgbouncer] section of the given file in place:
#   - an existing, uncommented setting with the same key is replaced
#   - all other keys are appended at the end of the [pgbouncer] section
# Does nothing if the variable is empty or unset.

set -euo pipefail

ini="${1:?usage: $0 <pgbouncer.ini>}"

if [ -z "${CONNECTION_POOLER_PARAMETERS:-}" ]; then
    exit 0
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# key<TAB>value per line; the key never contains a tab, the value may.
if ! printf '%s' "$CONNECTION_POOLER_PARAMETERS" \
    | jq -r 'to_entries[] | "\(.key)\t\(.value | tostring)"' > "$work/params"; then
    echo "ERROR: CONNECTION_POOLER_PARAMETERS is not a valid JSON object" >&2
    exit 1
fi

[ -s "$work/params" ] || exit 0

awk '
function flush(   k) {
    for (k in params) {
        if (!(k in used)) {
            print k " = " params[k]
            used[k] = 1
        }
    }
}
FNR == NR {
    i = index($0, "\t")
    params[substr($0, 1, i - 1)] = substr($0, i + 1)
    next
}
/^[[:space:]]*\[.*\][[:space:]]*$/ {
    if (in_section) { flush() }
    in_section = ($0 ~ /^[[:space:]]*\[pgbouncer\][[:space:]]*$/)
    seen = seen || in_section
    print
    next
}
in_section {
    line = $0
    if (line !~ /^[[:space:]]*[#;]/ && match(line, /^[[:space:]]*[A-Za-z0-9_]+[[:space:]]*=/)) {
        key = line
        sub(/^[[:space:]]*/, "", key)
        sub(/[[:space:]]*=.*$/, "", key)
        if (key in params) {
            if (!(key in used)) {
                print key " = " params[key]
                used[key] = 1
            }
            next
        }
    }
}
{ print }
END {
    if (in_section) { flush() }
    else if (!seen) {
        print ""
        print "[pgbouncer]"
        flush()
    }
}
' "$work/params" "$ini" > "$work/merged"

cat "$work/merged" > "$ini"
