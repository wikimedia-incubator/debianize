#/bin/bash

# "set -e" will cause bash to exit with an error on any simple command.
# "set -o pipefail" will cause bash to exit with an error on any command in a pipeline as well.
set -e
set -o pipefail



DPKG_GNUPG_OPTION=""
DPKG_DEPS_OPTION=""


while getopts "d" optname
  do
    case "$optname" in
      "d")
        echo "[!] Debug mode ON"
        echo "[!] Package will not be signed. Dependency check turned off"
        DPKG_GNUPG_OPTION="-us"
        DPKG_DEPS_OPTION="-d"
        ;;
      "?")
        echo "Option not recognized $OPTARG"
        ;;
      ":")
        echo "Argument missing for option $OPTARG"
        ;;
      *)
      # Should not occur
        echo "Unknown error while option processing"
        ;;
    esac
  done





# Set env variables
if [ -z "$DEBFULLNAME" ]; then
  export DEBFULLNAME="Diederik van Liere"
fi


if [ ! -f "Makefile" ]; then
  rm -f Makefile configure ;
  aclocal         ;
  autoconf        ;
  autoreconf      ;
  automake        ;
  ./configure     ;
fi

# Determine package
# TODO: find a canonical way to get the repository name
REPOSITORY_BASENAME=$(basename "$PWD")


if [ -z "$DEBEMAIL" ]
	then export DEBEMAIL="dvanliere@wikimedia.org"
fi




PACKAGE=${PWD##*/}
echo REPOSITORY_BASENAME is $REPOSITORY_BASENAME
echo PACKAGE is $PACKAGE
if [ $REPOSITORY_BASENAME != $PACKAGE ]
then
	echo 'Start debianize.sh either in the debianize folder or in the root of your git repository.';
	exit 1;
fi

if [ `whoami` != 'root' ]; then
  echo "Executing debianize.sh script"
else
  echo "Error: Executing debianize.sh as root not recommended"
  exit 1
fi


if [ `git status | grep "Changed but not updated" |wc -l` == 0 ]
then
	echo 'Please be aware that you have uncommited changes in your git repo.'
	echo 'Continuening with the building the Debian package means that your'
	echo 'your package will not be entirely up-to-date.'
fi

echo 'Building package for '$PACKAGE


# TODO: check if the project uses automake/autoconf and if so then run the following commnds
# in order to clean stuff up

#./configure;
#make clean;

LICENSE=gpl2
FIRST_COMMIT_DATE=`git log --pretty=format:"%H %ad" | perl -ne '/(\d+) ([+-]?\d+)$/ && print "$1\n"' | sort | uniq | tail -1`
FINAL_COMMIT_DATE=`git log --pretty=format:"%H %ad" | perl -ne '/(\d+) ([+-]?\d+)$/ && print "$1\n"' | sort | uniq | head -1`
REMOTE_URL=`git config --get remote.origin.url  | perl -ne '@url=split /\@/,$_; print $url[1];'`

VERSION=`git describe | awk -F'-g[0-9a-fA-F]+' '{print $1}' | sed -e 's/\-/./g' `
MAIN_VERSION=`git describe --abbrev=0`

PACKAGE=${PWD##*/}
echo 'Building package for ' $PACKAGE

tar -cvf $PACKAGE.tar --exclude-from=exclude . >/dev/null
mv $PACKAGE.tar ../
cd ..
rm -rf $PACKAGE-${VERSION}
mkdir  $PACKAGE-${VERSION}
tar -C $PACKAGE-${VERSION} -xvf $PACKAGE.tar >/dev/null

rm ${PACKAGE}\_${VERSION}.orig.tar.gz  2> /dev/null || true

cd $PACKAGE-${VERSION}

# Replace version place holder with current version number
echo `pwd`
echo 'Replacing version placeholders';

#
# Replace version inside source files
#
VERSION=$VERSION perl -pi -e 's/VERSION=".*";/VERSION="$ENV{VERSION}";/' \
                 `find -name "*.c" -or -name "*.h" -or -name "*.cpp" -or -name "*.h"`;

# 
# Replace version and package name inside configure.ac
# 
VERSION=$VERSION perl -pi -e 's/^VERSION=[^"]*$/VERSION=$ENV{VERSION}\n/' configure.ac;
PACKAGE=$PACKAGE VERSION=$VERSION perl -pi -e 's/AC_INIT\(\[.*?\],\[.*?\]/AC_INIT([$ENV{PACKAGE}],[$ENV{VERSION}]/' configure.ac;

echo 'Launching package builder';
mkdir m4
DH_MAKE_PKG_NAME=$PACKAGE\_${VERSION}
echo "DH_MAKE_PKG_NAME=$DH_MAKE_PKG_NAME"
echo "PACKAGE=$PACKAGE"


#if [ ! -e "$DH_MAKE_PKG_NAME" ]; then
  #echo "Error: archive $DH_MAKE_PKG_NAME doesn't exist"
  #exit 2
#else
dh_make -c ${LICENSE} -e ${DEBEMAIL} -s --createorig -p $DH_MAKE_PKG_NAME
#fi



#wget "https://raw.github.com/wmf-analytics/debianize/master/git2deblogs" -O git2deblogs;
#mkdir debian;
#chmod +x git2deblogs;
#./git2deblogs;



cd debian
rm *ex *EX || true
rm -rf changelog_backup/ || true
rm README.Debian dirs || true
cd ..
_CURRDIR=$(basename `pwd`)

# Get debian/ from development directory
if [ "$_CURRDIR" != "$PACKAGE" ]; then
  rm -rf debian/
  cp -r ../$PACKAGE/debian .
fi

autoreconf;
dpkg-buildpackage -b $DPKG_DEPS_OPTION $DPKG_GNUPG_OPTION; #-v${VERSION}

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
lintian -Ivi${PACKAGE_NAME_VERSION}
#mv ${PACKAGE_NAME_MAIN_VERSION} ${PACKAGE_NAME_VERSION}




