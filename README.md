Debianize
=========

Debianization tools:

*   debianize.sh --  Automate all steps of building a Debian package
*   git2deblogs  --  Synchronize git logs with debian changelogs
*   test-repo    --  Git repository zipped in order to perform tests on it (generating and checking debian/changelog)

Dependencies:

*   devscripts (debian package)
*   git-core   (debian package)



---

debianize.sh
------------

This is a bash script. It is primarily aimed at building deb packages for projects that use automake/autoconf toolchain for generating
the __configure__ and __Makefile__ files.

To use, just add debianize as a submodule to your project like this:

    git submodule add git://github.com/wmf-analytics/debianize.git debianize/

Then make symlinks for:

*   debianize.sh
*   prepare-release.sh
*   git2deblogs.pl

Make sure you have at least one tag (one tag means one package version).
Make sure to run __git2deblogs__ to update your __debian/changelog__ as this is the file which controls the version of
the package you will generate.

Now run
 
    ./debianize.sh

git2deblogs.pl
--------------



Continous integration available here:

http://www.garage-coding.com:8010/builders/git2deblogs-builder