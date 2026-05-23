#!/bin/sh
set -eu

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LOCAL_CONFIG="$ROOT_DIR/Config/LocalSigning.xcconfig"
SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 8)

if [ -f "$LOCAL_CONFIG" ]; then
  echo "Local signing config already exists: $LOCAL_CONFIG"
  exit 0
fi

cat > "$LOCAL_CONFIG" <<EOF
// Local-only signing settings. Ignored by git.

DEVELOPMENT_TEAM =
BUNDLE_ID_SUFFIX = .$SUFFIX
PRODUCT_BUNDLE_IDENTIFIER = local.coruna.ios\$(BUNDLE_ID_SUFFIX)
EOF

echo "Created $LOCAL_CONFIG"
