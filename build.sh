#!/bin/bash
#  
# This script builds the following packages
#  
# * libanon
# * libcidr
# * udp-filters
# * webstatscollector
# 
# It is only to be run from build1 and build2. Do not run simoultaenously.
# It will make directories  lucid/  and precis/ in your $HOME directory
# with all the packages files.
#
# The script assumes you're only going to run this on build1 or build2 or garage(local development machine)
#
# SOURCE_DIR is the folder where it assumes you have your source code in
#
DISTRO=$(lsb_release -c | perl -ne "s/Codename:\s+//; print")
MACHINE=$(cat /etc/wmflabs-instancename 2>/dev/null || cat /etc/hostname)
SOURCE_DIR=wikistats/

if [ $MACHINE != "build1" -a $MACHINE != "build2" -a $MACHINE != "garage" ]; then
  echo "Not running on the right machine (please check the machine you're running this on).";
  echo "Please switch either and run from there.";
  exit 0;
fi

if [ -z $DISTRO -o $DISTRO == "" ]; then
  echo "Distro was not found, no point to go further. You got a distro that doesn't have lsb_release";
  exit 0;
fi

if [ -z $MACHINE -o $MACHINE == "" ]; then
  echo "Machine identifier not found.";
  exit 0;
fi

function run_git2deblogs {
  ./git2deblogs.pl --generate --distribution="$DISTRO-wikimedia" --force-maintainer-name="Diederik van Liere" --force-maintainer-email=dvanliere@wikimedia.org
}

echo "Building on machine [$MACHINE] with distro [$DISTRO]..."

rm -rf   $HOME/$DISTRO
mkdir -p $HOME/$DISTRO
echo "[Start]";
cd $HOME;
cd $SOURCE_DIR;
pushd .

#### libanon           #####
cd libanon;
dpkg-buildpackage;

#### libcidr           #####
cd ../libcidr;
dpkg-buildpackage;

#### webstatscollector #####
cd ../webstatscollector;
run_git2deblogs;
./debianize.sh;

#### udp-filters       #####
cd ../udp-filters;
run_git2deblogs;
./debianize.sh;

popd;
echo "[Moving files to $HOME/$DISTRO/]";
mv *.dsc     $HOME/$DISTRO;
mv *.changes $HOME/$DISTRO;
mv *.deb     $HOME/$DISTRO;
mv *.tar.gz  $HOME/$DISTRO;

echo "[Done]";
