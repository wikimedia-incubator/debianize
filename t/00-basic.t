#!/usr/bin/env perl
package GitTestSandbox::Custom;
use strict;
use warnings;
BEGIN {
  our @ISA = "GitTestSandbox";

  push @INC,"./t";
  require GitTestSandbox;
}


sub populate_with_commits {
  my ($self) = @_;
  $self->gen_repo_new_commit("$_ commit") for 2..5;
  $self->gen_repo_new_tag("0.1"  );
  $self->gen_repo_new_commit("$_ commit") for 6..10;
  $self->gen_repo_new_tag("0.2"  );
  $self->gen_repo_new_commit("$_ commit") for 10..14;
  $self->gen_repo_new_tag("0.3"  );
  $self->gen_repo_new_commit("$_ commit") for 15..18;
  $self->gen_repo_new_tag("0.4"  );
  $self->gen_repo_new_commit("$_ commit") for 19..22;
  $self->gen_repo_new_tag("0.4.4");
};

sub total_tags_found_in_changelog {
  my ($self) = @_;
  my $mock_repo_path = $self->{mock_repo_path};
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
  my ($self) = @_;
  my $mock_repo_path = $self->{mock_repo_path};
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



package main;
use strict;
use warnings;
use Test::More 'no_plan';
use Carp;

my $o = GitTestSandbox::Custom->new();
#my $o = {};

$o->gen_repo();
$o->populate_with_commits();
$o->run_git2deblogs();



my @commit_counts = $o->total_commits_found_in_changelog();
ok($o->total_tags_found_in_changelog == 5,"all tags present in debian/changelog");

# Checking commit counts
ok($commit_counts[$_] == 1,"commit $_ is supposed to be present 1 time")
  for 1..9;
ok($commit_counts[10] == 2,"commit 10 is supposed to be present 2 times");

ok($commit_counts[$_] == 1,"commit $_ is supposed to be present 1 time")
  for 11..22;

# Cleanup
$o->destroy_repo();
