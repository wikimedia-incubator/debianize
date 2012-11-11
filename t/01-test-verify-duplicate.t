#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Dumper;
use Carp;
use lib "./lib";
use Git::ConsistencyCheck;

my $timestamp = `date +"%s"`; chomp $timestamp;

my $raw_data = join("",<DATA>);
my (undef,$content_good_changelog,$content_bad_changelog ) = 
  split(/====(?:GOOD|BAD)_PACKAGE_DEBIAN_LOG====/,$raw_data);


my $fake_dir       = "/tmp/test-repo-$timestamp";
my $fake_changelog = "$fake_dir/changelog";
my $fake_control   = "$fake_dir/control";


`
mkdir -p $fake_dir;
echo "" > $fake_changelog;
echo "Package: a-package-name" > $fake_control;
`;



my $o = Git::ConsistencyCheck->new({changelog_path => $fake_changelog});


# Test 1 , good changelog
$o->{changelog_content} = $content_good_changelog;
ok(0 == $o->verify_changelog_duplicate_versions(),"good changelog");
# Test 2 , bad changelog
$o->{changelog_content} = $content_bad_changelog;
ok(1 == $o->verify_changelog_duplicate_versions(),"bad  changelog");





__DATA__
====GOOD_PACKAGE_DEBIAN_LOG====
a-package-name (0.3.19) maverick; urgency=low

  [ Author1  ]
  * Commit message 6

  [ Author2  ]
  * Commit message 5 multi-line line 1
  * Commit message 4 multi-line line 2

 -- The Maintainer <the_maintainer@maintainer-website.com>  Fri, 2 Nov 2012 18:52:28 +0200

a-package-name (0.3) maverick; urgency=low

  [ Author3  ]
  * Commit message 2

  [ Author4  ]
  * Commit message 1
 
 -- The Maintainer <the_maintainer@maintainer-website.com>  Fri, 5 Oct 2012 16:27:30 +0300

a-package-name (0.2.0) UNRELEASED; urgency=low




====BAD_PACKAGE_DEBIAN_LOG====

a-package-name (0.3.19) maverick; urgency=low

  [ Author1  ]
  * Commit message 6

  [ Author2  ]
  * Commit message 5 multi-line line 1
  * Commit message 4 multi-line line 2

 -- The Maintainer <the_maintainer@maintainer-website.com>  Fri, 2 Nov 2012 18:52:28 +0200

a-package-name (0.3) maverick; urgency=low

  [ Author3  ]
  * Commit message 2
 
 -- The Other Maintainer <the_other_maintainer@maintainer-website.com>  Fri, 5 Oct 2012 16:27:30 +0300

a-package-name (0.3) maverick; urgency=low

  [ Author3  ]
  * Commit message 2

  [ Author4  ]
  * Commit message 1
 
 -- The Maintainer <the_maintainer@maintainer-website.com>  Fri, 5 Oct 2012 16:27:30 +0300

a-package-name (0.2.0) UNRELEASED; urgency=low
