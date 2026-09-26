#!/bin/sh
# Build one small audiobible-shmueloff-source-<book>-<chapter> deb per
# per-chapter raw take (the bulk of this repo's size, not read by the app
# at runtime -- kept as archival source material), plus the
# audiobible-shmueloff-source meta package that carries the small,
# actually-used whole-book mp3s and Depends on every chapter package
# pinned to its exact built version.
# Usage: packaging/deb/build.sh
set -eu

cd "$(dirname "$0")/../.."
REPO_ROOT="$(pwd)"
PKG_DIR="$REPO_ROOT/debian-pkg"
rm -rf "$PKG_DIR"

DEPENDS=""
for book in $(find . -mindepth 1 -maxdepth 1 -type d ! -name '.git' ! -name packaging -printf '%f\n' | sort); do
	for chfile in "$book"/*.mp3; do
		chapter=$(basename "$chfile" .mp3)
		pkg="audiobible-shmueloff-source-${book}-${chapter}"
		ver="0.$(git rev-list --count HEAD -- "$chfile")"

		CH_DIR="$PKG_DIR/${pkg}"
		mkdir -p "$CH_DIR/DEBIAN" "$CH_DIR/usr/share/audiobible/source/${book}"
		cp "$chfile" "$CH_DIR/usr/share/audiobible/source/${book}/"
		sed -e "s/%PKG%/${pkg}/g" -e "s/%VERSION%/${ver}/g" \
		    -e "s/%BOOK%/${book}/g" -e "s/%CHAPTER%/${chapter}/g" \
		    packaging/deb/control-chapter > "$CH_DIR/DEBIAN/control"
		dpkg-deb --build --root-owner-group "$CH_DIR" "${pkg}_${ver}_all.deb"
		echo "Built ${pkg}_${ver}_all.deb"

		DEPENDS="${DEPENDS}${DEPENDS:+, }${pkg} (= ${ver})"
	done
done

META_VERSION="0.$(git rev-list --count HEAD)"
META_DIR="$PKG_DIR/audiobible-shmueloff-source"
mkdir -p "$META_DIR/DEBIAN" "$META_DIR/usr/share/audiobible/source"
cp ./*.mp3 "$META_DIR/usr/share/audiobible/source/"
sed -e "s/^Version: .*/Version: ${META_VERSION}/" packaging/deb/control \
    | sed "/^Architecture:/a Depends: ${DEPENDS}" > "$META_DIR/DEBIAN/control"
dpkg-deb --build --root-owner-group "$META_DIR" "audiobible-shmueloff-source_${META_VERSION}_all.deb"

rm -rf "$PKG_DIR"
echo "Built audiobible-shmueloff-source_${META_VERSION}_all.deb (meta package)"
