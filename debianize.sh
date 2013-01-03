#/bin/bash

# "set -e" will cause bash to exit with an error on any simple command.
# "set -o pipefail" will cause bash to exit with an error on any command in a pipeline as well.
set -e
set -o pipefail


#make sure that dh_make is installed
DH_MAKE_PATH=`which dh_make`;
echo "[DBG] DH_MAKE_PATH=$DH_MAKE_PATH";
if [ -z $DH_MAKE_PATH ]; then
    echo "[ERROR] Please make sure that dh_make is installed.";
    exit 1;
fi

# TODO add check to verify that autoconf and libtoolize are installed
#make sure that autoconf is installed
#AUTORECONF_PATH=`which autoreconf`;

#echo "[DBG] AUTORECONF_PATH=$AUTORECONF_PATH";
#if [ -z $AUTORECONF_PATH ]; then
#    echo "[ERROR] Please make sure that autoconf is installed.";
#    exit 1;
#fi

#make sure that a 'debian' folder is present
if [ -d "src/debian" ]; then
    echo "[ERROR] Could not find the debian folder.";
    exit 1;
fi

DPKG_GNUPG_OPTION=""
DPKG_DEPS_OPTION=""


while getopts "d" optname
  do
    case "$optname" in
      "d")
        echo "[!] Debug mode ON"
        echo "[!] Package will not be signed. Dependency check turned off"
        DPKG_GNUPG_OPTIONS="-us -uc"
        DPKG_DEPS_OPTIONS="-d"
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


#Determine absolute path to debianize folder
DEBIANIZE_PATH=$(perl -MCwd=abs_path -e '$p=abs_path("debianize.sh"); system("dirname \"$p\"");')
echo "[DBG] DEBIANIZE_PATH=$DEBIANIZE_PATH";

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

function upsearch () {
    test / == "$PWD" && return || test -e "$1" && echo "[DBG] found: " "$PWD" && return || cd .. && upsearch "$1"
}

upsearch '.git';
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

VERSION=`git describe | awk -F'-g[0-9a-fA-F]+' '{print $1}' | sed -e 's/\-/./g' ` || true
MAIN_VERSION=`git describe --abbrev=0` || true

# there are no tags containing version numbering, therefore we just hardcode it to 1.0
if [ -z "$VERSION" ]; then
    VERSION=1.0;
fi

if [ -z "$MAIN_VERSION" ]; then
    MAIN_VERSION=1.0;
fi

echo "[DBG] VERSION=$VERSION";
echo "[DBG] MAIN_VERSION=$MAIN_VERSION";

PACKAGE=${PWD##*/}
PACKAGE=$(echo $PACKAGE | perl -e 'print lc <>;');
echo '[DBG] Building package for '$PACKAGE


# We need to make sure that the exclude file at least exists
# if it does not exist symlink to the one provided by the
# debianize repo. That exclude file has only one entry and that
# says it should ignore the .git folder.
if [ ! -f "exclude" ];
then
    echo "[DBG] Creating symlink to file exclude provide by debianize.";
    EXCLUDE_PATH=$DEBIANIZE_PATH/exclude
else
    EXCLUDE_PATH=exclude
fi

tar -cvf $PACKAGE.tar --exclude-from=$EXCLUDE_PATH . >/dev/null
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
                 `find . -name "*.c" -or -name "*.h" -or -name "*.cpp"`;

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


# automate dh_make so it doesn't ask anymore questions
dh_make -s -c ${LICENSE} -e ${DEBEMAIL} --createorig -p $DH_MAKE_PKG_NAME


#generate Changelog file
#./git2deblogs --generate;

#disable some weird cleaning

#cd debian
#rm *ex *EX || true
#rm -rf changelog_backup/ || true
#rm README.Debian dirs || true
#cd ..
#_CURRDIR=$(basename `pwd`)

# Get debian/ from development directory
#if [ "$_CURRDIR" != "$PACKAGE" ]; then
#  rm -rf debian/
#  cp -r ../$PACKAGE/debian .
#fi

#autoreconf;
### end of temp disable

dpkg-buildpackage -b $DPKG_DEPS_OPTIONS $DPKG_GNUPG_OPTIONS; #-v${VERSION}

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


PACKAGE_NAME_VERSION=$PACKAGE\_${VERSION}-1\_$ARCH_SYS.deb
PACKAGE_NAME_MAIN_VERSION=$PACKAGE\_${MAIN_VERSION}-1\_${ARCH_SYS}.deb


echo "Currently in =>"`pwd`
echo -e "Linting package ${PACKAGE_NAME_VERSION} ...\n"
dpkg-deb --contents ${PACKAGE_NAME_VERSION}
lintian -Ivi ${PACKAGE_NAME_VERSION}
#mv ${PACKAGE_NAME_MAIN_VERSION} ${PACKAGE_NAME_VERSION}




