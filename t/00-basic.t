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
  my $tag_0_1   = `grep "(0.1)"   ./$repo_temp_path/debian/changelog | wc -l`;
  my $tag_0_2   = `grep "(0.2)"   ./$repo_temp_path/debian/changelog | wc -l`;
  my $tag_0_3   = `grep "(0.3)"   ./$repo_temp_path/debian/changelog | wc -l`;
  my $tag_0_4   = `grep "(0.4)"   ./$repo_temp_path/debian/changelog | wc -l`;
  my $tag_0_4_4 = `grep "(0.4.4)" ./$repo_temp_path/debian/changelog | wc -l`;
  chomp $tag_0_1;
  chomp $tag_0_2;
  chomp $tag_0_3;
  chomp $tag_0_4;
  chomp $tag_0_4_4;
  return $tag_0_1 + $tag_0_2 + $tag_0_3 + $tag_0_4 + $tag_0_4_4;
}

sub total_commits_found_in_changelog {
  # commit messages in the test-repo git repository are like
  # "1 commit"
  # "2 commit"
  # ...
  # 
  # but "10 commit" is two times (under 2 different commits)
  # 
  my @commit_counts = (0,map {
    my $count = `grep "\ $_ commit" ./$repo_temp_path/debian/changelog | wc -l`;
    chomp $count;
    $count;
  } 1..22);

  return @commit_counts;
}

ok(total_tags_found_in_changelog()==5,"all tags present in debian/changelog");
my @commit_counts = total_commits_found_in_changelog();

# Checking commit counts
ok($commit_counts[$_] == 1,"commit $_ is supposed to be present 1 time")
  for 1..9;
ok($commit_counts[10] == 2,"commit 10 is supposed to be present 2 times");

ok($commit_counts[$_] == 1,"commit $_ is supposed to be present 1 time")
  for 11..22;
 


# Cleanup
`rm -rf $repo_temp_path`;
