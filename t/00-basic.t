#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Carp;
my $timestamp = `date +"%s"`; chomp $timestamp;
my $mock_repo_path = "test-repo-$timestamp";
my $mock_file_path = "A.txt";


#
# Generate new commit in test repo after modifying the file in it a bit
#

sub gen_repo_new_commit {
  my ($message) = @_;
  my $random1 = int(rand(99999999));
  my $random2 = int(rand(99999999));
  my $date    = `date +%N`;
  chomp $date;
  `
  cd $mock_repo_path;
  echo "$date-$random1-$random2" > $mock_file_path;
  git commit -am "$message";
  `;
};

#
# Generate new tag in test repo
#
sub gen_repo_new_tag {
  my ($name) = @_;
  `
  cd $mock_repo_path;
  git tag -a "$name" -m "New tag $name"
  `;
};

#
# Create a mock repo to test the git2deblogs script on
#
sub gen_repo {
  `
  mkdir $mock_repo_path;
  mkdir $mock_repo_path/debian;
  cd    $mock_repo_path;
  git init;
  echo "TestData" > $mock_file_path;
  git add $mock_file_path;
  git commit -am "1 commit";
  `;
  gen_repo_new_commit("$_ commit") for 2..5;
  gen_repo_new_tag("0.1"  );
  gen_repo_new_commit("$_ commit") for 6..10;
  gen_repo_new_tag("0.2"  );
  gen_repo_new_commit("$_ commit") for 10..14;
  gen_repo_new_tag("0.3"  );
  gen_repo_new_commit("$_ commit") for 15..18;
  gen_repo_new_tag("0.4"  );
  gen_repo_new_commit("$_ commit") for 19..22;
  gen_repo_new_tag("0.4.4");
};


sub total_tags_found_in_changelog {
  my $tag_0_1   = `grep "(0.1)"   ./$mock_repo_path/debian/changelog | wc -l`;
  my $tag_0_2   = `grep "(0.2)"   ./$mock_repo_path/debian/changelog | wc -l`;
  my $tag_0_3   = `grep "(0.3)"   ./$mock_repo_path/debian/changelog | wc -l`;
  my $tag_0_4   = `grep "(0.4)"   ./$mock_repo_path/debian/changelog | wc -l`;
  my $tag_0_4_4 = `grep "(0.4.4)" ./$mock_repo_path/debian/changelog | wc -l`;
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
    my $count = `grep "\ $_ commit" ./$mock_repo_path/debian/changelog | wc -l`;
    chomp $count;
    $count;
  } 1..22);

  return @commit_counts;
};


sub run_git2deblogs {
  `
  cd $mock_repo_path
  ln -s ../git2deblogs.pl
  ./git2deblogs.pl --generate
  `;
};

gen_repo();
run_git2deblogs();




ok(total_tags_found_in_changelog()==5,"all tags present in debian/changelog");
my @commit_counts = total_commits_found_in_changelog();

# Checking commit counts
ok($commit_counts[$_] == 1,"commit $_ is supposed to be present 1 time")
  for 1..9;
ok($commit_counts[10] == 2,"commit 10 is supposed to be present 2 times");

ok($commit_counts[$_] == 1,"commit $_ is supposed to be present 1 time")
  for 11..22;




# Cleanup
`rm -rf $mock_repo_path`;
