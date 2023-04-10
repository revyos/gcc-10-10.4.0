#!/bin/sh

# Helper for debian/rules2.

# A modification of libgnat sources invalidates the .ali checksums in
# reverse dependencies as described in the Debian Policy for Ada.  GCC
# cannot afford the recommended passage through NEW, but this check at
# least reports the issue before causing random FTBFS.

set -Cefu
[ $# = 2 ]
# Argument 1: old ALI dir
# Argument 2: new ALI dir

# A missing $1 means that we build a new GCC Base Version, and that
# libgnatBV-dev package will be renamed anyway.
[ -d "$1" ] || exit 0

vanished=
changed=
ignored=

for ali1 in `find "$1" -name "*.ali"`; do
    unit=`basename "$ali1" .ali`
    ali2="$2/$unit.ali"

    if [ ! -r "$ali2" ]; then
	vanished="$vanished $unit.ali"
    fi

    pattern="^D $unit\.ad"
    lines1=`grep "$pattern" "$ali1"`
    lines2=`grep "$pattern" "$ali2"`
    if [ "$lines1" != "$lines2" ]; then
	case $unit in
	    s-oscons)
		# no impact on ABI?
		ignored="$ignored $unit.ali";;
	    s-osinte)
		# still changed after reverting PR ada/99264
		ignored="$ignored $unit.ali";;
	    *)
		changed="$changed $unit.ali"
        esac
    fi
done

if [ -n "$vanished" ] || [ -n "$changed" ] || [ -n "$ignored" ]; then
    echo 'error: changes in Ada Library Information files.'
    echo 'You are seeing this because'
    echo ' * DEB_CHECK_ALI_UPDATE=1 in the environment.'
    echo ' * build_type=build-native and with_libgnat=yes in debian/rules.defs.'
    echo ""
    if [ -n "$vanished" ]; then
	echo " * vanished files : $vanished"
    fi
    if [ -n "$changed" ]; then
	echo " * differing files: $changed"
    fi
    if [ -n "$ignored" ]; then
	echo " * ignored differing files: $ignored"
    fi
    echo ""
    echo 'This may break Ada packages, see https://people.debian.org/~lbrenta/debian-ada-policy.html.'
    echo 'If you are uploading to Debian, please contact debian-ada@lists.debian.org.'
    if [ -n "$vanished" ] || [ -n "$changed" ]; then
	exit 1
    fi
fi

exit 0
