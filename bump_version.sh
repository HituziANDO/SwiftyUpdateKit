#!/bin/sh
#
# Updates the framework version in every place it is hard-coded.
#
#   ./bump_version.sh 1.6.0
#
set -eu

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "usage: $0 <version>   e.g. $0 1.6.0" >&2
  exit 1
fi

if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$'; then
  echo "error: invalid version: $VERSION" >&2
  exit 1
fi

cd "$(dirname "$0")"

PODSPEC=SwiftyUpdateKit.podspec
SOURCE=Framework/Sources/SUK.swift
PBXPROJ=Framework/SwiftyUpdateKit.xcodeproj/project.pbxproj

CURRENT=$(sed -n -E 's/^[[:space:]]*s\.version = "(.*)"/\1/p' "$PODSPEC")
echo "$CURRENT -> $VERSION"

# BSD sed (macOS). -i '' edits in place without a backup file.
sed -i '' -E "s/^([[:space:]]*s\.version = )\".*\"/\1\"$VERSION\"/" "$PODSPEC"
sed -i '' -E "s/^([[:space:]]*public static let version = )\".*\"/\1\"$VERSION\"/" "$SOURCE"
sed -i '' -E "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION;/" "$PBXPROJ"

# sed exits 0 even when nothing matched, so verify each file actually holds the
# new version. Expected: podspec 1, SUK.swift 1, project.pbxproj 4.
verify() {
  count=$(grep -c "$2" "$1" || true)
  if [ "$count" -ne "$3" ]; then
    echo "error: $1 has $count occurrences of $VERSION, expected $3" >&2
    exit 1
  fi
}
verify "$PODSPEC" "s\.version = \"$VERSION\"" 1
verify "$SOURCE" "public static let version = \"$VERSION\"" 1
verify "$PBXPROJ" "MARKETING_VERSION = $VERSION;" 4

git diff --stat -- "$PODSPEC" "$SOURCE" "$PBXPROJ"
echo
echo "Next: ./build.sh to regenerate the XCFramework, then commit and tag $VERSION."
