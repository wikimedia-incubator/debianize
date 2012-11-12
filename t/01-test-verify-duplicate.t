#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
use lib "./lib";
use Git::ConsistencyCheck;

# inject hardcoded changelog before each test
# (ignoring the $fake_changelog which was initially given, which is empty)

# Test 1 , good changelog
my $o1 = Git::ConsistencyCheck->new({changelog_path => "./t/data/verify-duplicate/good-example/debian/changelog"});
ok("" eq $o1->verify_changelog_duplicate_versions(),"good changelog");

# Test 2 , bad changelog
my $o2 = Git::ConsistencyCheck->new({changelog_path => "./t/data/verify-duplicate/bad-example/debian/changelog"});
ok("Error  : Failed duplicate version verificiation\n" eq $o2->verify_changelog_duplicate_versions(),"bad  changelog");


