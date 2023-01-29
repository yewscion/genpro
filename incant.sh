#!/usr/bin/env sh

### Follow Best Practices
set -o errexit nounset pipefail
if [ "${TRACE-0}" = "1" ]; then set -o xtrace; fi
cd "$(dirname "$0")"
### End Follow Best Practices

echo "Beginning Incantation…"

if [ ! -x "./bootstrap" ]; then
    echo "./bootstrap script not found! Are You in the project directory?";
    exit;
fi
if [ -f "build" ]; then
    echo "File 'build' needs renamed, so we can have a build/ directory.";
    exit;
fi
rm -rfv build/
mkdir -pv build/
./bootstrap
cd build/
../configure
make
DESTDIR=test/ make install
tree test
make dist
mv -vt .. ./*.bz2
echo "Incantation Complete."
