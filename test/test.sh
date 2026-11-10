#!/bin/sh
# Smoke tests for the iipsrv image.
#
#   test/test.sh [IMAGE]          (default: iipsrv:test)
#
# Requires: docker or podman, curl, jq, vips (libvips-tools).
# Set CONTAINER_ENGINE=podman to force podman.
set -eu

IMAGE="${1:-iipsrv:test}"
ENGINE="${CONTAINER_ENGINE:-$(command -v docker >/dev/null && echo docker || echo podman)}"
PORT1=3000
PORT2=3001
WORK="$(mktemp -d)"
FAILED=0

cleanup() {
    for name in iipsrv-test-default iipsrv-test-env; do
        if [ "${KEEP_LOGS:-}" = 1 ] || [ "$FAILED" != 0 ]; then
            echo "--- logs: $name"; $ENGINE logs "$name" 2>&1 | tail -20 || true
        fi
        $ENGINE rm -f "$name" >/dev/null 2>&1 || true
    done
    rm -rf "$WORK"
}
trap cleanup EXIT

ok()   { echo "ok   $*"; }
fail() { echo "FAIL $*"; FAILED=1; }

# check <description> <expected> <actual>
check() {
    if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 (expected '$2', got '$3')"; fi
}

# Number of iipsrv processes in a container
procs() { $ENGINE exec "$1" sh -c 'cat /proc/[0-9]*/comm 2>/dev/null' | grep -c '^iipsrv'; }

status() { curl -s -o /dev/null -w '%{http_code} %{content_type}' "$@"; }

wait_for() {
    for _ in $(seq 1 30); do
        curl -sf -o /dev/null "$1" && return 0
        sleep 1
    done
    fail "server did not respond: $1"
    exit 1
}

# Test image: 1000x1000 tiled pyramid TIFF
mkdir -p "$WORK/images"
vips black "$WORK/base.v" 1000 1000 --bands 3
vips tiffsave "$WORK/base.v" "$WORK/images/example.tif" \
    --tile --pyramid --compression jpeg --tile-width 256 --tile-height 256
chmod -R a+rX "$WORK"

echo "== defaults"
$ENGINE run -d --name iipsrv-test-default -p "127.0.0.1:$PORT1:80" \
    -v "$WORK/images:/data/images:ro" "$IMAGE" >/dev/null
BASE="http://127.0.0.1:$PORT1"
wait_for "$BASE/?IIIF=example.tif/info.json"

info="$(curl -sf "$BASE/?IIIF=example.tif/info.json")"
check "info.json size (query URL)"    "1000x1000" "$(echo "$info" | jq -r '"\(.width)x\(.height)"')"
check "IIIF version 3"                "ImageService3" "$(echo "$info" | jq -r '.type')"
check "MAX_CVT default"               "3000" "$(echo "$info" | jq -r '.maxWidth')"
check "IIPSRV_PROCS default"          "1" "$(procs iipsrv-test-default)"

info="$(curl -sf "$BASE/iiif/example.tif/info.json")"
check "info.json size (/iiif/ URL)"   "1000x1000" "$(echo "$info" | jq -r '"\(.width)x\(.height)"')"
check "id of /iiif/ URL"              "$BASE/iiif/example.tif" "$(echo "$info" | jq -r '.id')"

for q in full/200,/0/default.jpg:image/jpeg \
         0,0,256,256/max/0/default.webp:image/webp \
         full/100,/0/default.png:image/png \
         full/200,/0/default.avif:image/avif; do
    path="${q%%:*}"; type="${q#*:}"
    check "GET /iiif/example.tif/$path" "200 $type" "$(status "$BASE/iiif/example.tif/$path")"
    check "GET /?IIIF=example.tif/$path" "200 $type" "$(status "$BASE/?IIIF=example.tif/$path")"
done

check "HEAD /iiif/ info.json"         "200" "$(curl -s -o /dev/null -I -w '%{http_code}' "$BASE/iiif/example.tif/info.json")"
check "CORS header" "*" "$(curl -s -D - -o /dev/null "$BASE/iiif/example.tif/info.json" | tr -d '\r' | sed -n 's/^[Aa]ccess-[Cc]ontrol-[Aa]llow-[Oo]rigin: //p')"
check "missing image"                 "404" "$(curl -s -o /dev/null -w '%{http_code}' "$BASE/iiif/missing.tif/info.json")"

echo "== settings from environment variables"
$ENGINE run -d --name iipsrv-test-env -p "127.0.0.1:$PORT2:80" \
    -v "$WORK/images:/srv/img:ro" \
    -e FILESYSTEM_PREFIX=/srv/img/ \
    -e BASE_URL=https://example.org/iiif/ \
    -e MAX_CVT=500 \
    -e IIPSRV_PROCS=3 \
    "$IMAGE" >/dev/null
BASE="http://127.0.0.1:$PORT2"
wait_for "$BASE/iiif/example.tif/info.json"

info="$(curl -sf "$BASE/iiif/example.tif/info.json")"
check "FILESYSTEM_PREFIX"             "1000x1000" "$(echo "$info" | jq -r '"\(.width)x\(.height)"')"
check "BASE_URL"                      "https://example.org/iiif/example.tif" "$(echo "$info" | jq -r '.id')"
check "MAX_CVT"                       "500" "$(echo "$info" | jq -r '.maxWidth')"
check "IIPSRV_PROCS"                  "3" "$(procs iipsrv-test-env)"

echo "== invalid settings"
check "IIPSRV_PROCS=abc is refused"   "refused" \
    "$(if $ENGINE run --rm -e IIPSRV_PROCS=abc "$IMAGE" true >/dev/null 2>&1; then echo started; else echo refused; fi)"

if [ "$FAILED" != 0 ]; then
    echo "Some tests failed."
    exit 1
fi
echo "All tests passed."
