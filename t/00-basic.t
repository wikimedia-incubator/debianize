#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
my $timestamp = `date +"%s"`;
chomp $timestamp;
my $repo_temp_path = "test-repo-$timestamp";
`
unzip test-repo.zip
mv "test-repo" "$repo_temp_path/"
cd $repo_temp_path
ln -s ../git2deblogs
./git2deblogs
`;

sub total_tags_found_in_changelog {
  my $tag_0_1 = `grep "(0.1)" ./$repo_temp_path/debian/changelog | wc -l`;
  my $tag_0_2 = `grep "(0.2)" ./$repo_temp_path/debian/changelog | wc -l`;
  my $tag_0_3 = `grep "(0.3)" ./$repo_temp_path/debian/changelog | wc -l`;
  my $tag_0_4 = `grep "(0.4)" ./$repo_temp_path/debian/changelog | wc -l`;
  chomp $tag_0_1;
  chomp $tag_0_2;
  chomp $tag_0_3;
  chomp $tag_0_4;
  return $tag_0_1 + $tag_0_2 + $tag_0_3 + $tag_0_4;
}


ok(total_tags_found_in_changelog()==4,"all tags present in debian/changelog");
`rm -rf $repo_temp_path`;
#done_testing;
