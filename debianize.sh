#/bin/bash

# "set -e" will cause bash to exit with an error on any simple command.
# "set -o pipefail" will cause bash to exit with an error on any command in a pipeline as well.
set -e
set -o pipefail

# Set env variables
if [ -z "$DEBFULLNAME" ]
	then export DEBFULLNAME="Diederik van Liere"
fi


# Determine package
if [ $(git rev-parse --is-bare-repository) = true ]
then
    REPOSITORY_BASENAME=$(basename "$PWD")
else
    REPOSITORY_BASENAME=$(basename $(readlink -nf "$PWD"/..))
fi

cd ..
PACKAGE=${PWD##*/}
echo REPOSITORY_BASENAME is $REPOSITORY_BASENAME
echo PACKAGE is $PACKAGE
if [ $REPOSITORY_BASENAME != $PACKAGE ]
then
	echo 'Start debianize.sh either in the debianize folder or in the root of your git repository.';
	exit 1;
fi

git status | grep "Changed but not updated"
if [ $? == 0 ]
then
	echo 'Please be aware that you have uncommited changes in your git repo.'
	echo 'Continuening with the building the Debian package means that your'
	echo 'your package will not be entirely up-to-date.'
fi

echo 'Building package for '$PACKAGE


VERSION=`     git describe | awk -F'-g[0-9a-fA-F]+' '{print $1}' | sed -e 's/\-/./g' `
MAIN_VERSION=`git describe --abbrev=0`


tar -cvf $PACKAGE.tar --exclude-from=exclude .
mv $PACKAGE.tar ../
cd ..

# this file is not always present and so the absence of this file should not kill this script.

rm -rf $PACKAGE-${VERSION} 2> /dev/null || true

# Create a tar file of the package
mkdir $PACKAGE-${VERSION}
tar -C $PACKAGE-${VERSION} -xvf $PACKAGE.tar

rm ${PACKAGE}_${VERSION}.orig.tar.gz  2> /dev/null || true

cd $PACKAGE-${VERSION}

# Replace version place holder with current version number
echo `pwd`
echo 'Replacing version placeholders';

VERSION=$VERSION perl -pi -e 's/VERSION=".*";/VERSION="$ENV{VERSION}";/' src/collector.c

echo 'Launching package builder';
mkdir m4
dh_make -c gpl2 -e dvanliere@wikimedia.org -s --createorig -p $PACKAGE\_${VERSION}
cd debian
rm *ex *EX
rm README.Debian dirs
#cp ../$PACKAGE/debian/control debian/.
#cp ../$PACKAGE/debian/rules debian/.
#cp ../$PACKAGE/debian/copyright debian/.
#cp ../$PACKAGE/debian/changelog debian/.
#cp ../$PACKAGE/Makefile debian/.
#cd ../$PACKAGE_${VERSION} &&
cd ..
dpkg-buildpackage -v${VERSION}
cd ..


ARCHITECTURE=`uname -m`
ARCH_i686="i386"
ARCH_x86_64="amd64"
ARCH_SYS=""

if [ $ARCHITECTURE == "i686" ]; then
  ARCH_SYS=$ARCH_i686
elif [ $ARCHITECTURE == "x86_64" ]; then
  ARCH_SYS="amd64"
else
  echo -e  "Sorry, only i686 and x86_64 architectures are supported.\n"
  exit 1
fi


PACKAGE_NAME_VERSION=$PACKAGE\_${VERSION}\_$ARCH_SYS.deb
PACKAGE_NAME_MAIN_VERSION=$PACKAGE\_${MAIN_VERSION}\_${ARCH_SYS}.deb


dpkg-deb --contents ${PACKAGE_NAME_VERSION}
echo "Currently in =>"`pwd`
echo -e "Linting package ${PACKAGE_NAME_VERSION} ...\n"
lintian ${PACKAGE_NAME_VERSION}
#mv ${PACKAGE_NAME_MAIN_VERSION} ${PACKAGE_NAME_VERSION}




