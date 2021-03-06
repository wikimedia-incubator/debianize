use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
# test1
WriteMakefile(
    NAME              => 'Git::ToChangelog',
    VERSION_FROM      => 'lib/Git/ToChangelog.pm', # finds $VERSION
    PREREQ_PM         => {
      #"JSON::XS" => 2.32,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Git/ToChangelog.pm', # retrieve abstract from module
       AUTHOR         => 's <user@>') : ()),
);
