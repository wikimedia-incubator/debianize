#!/usr/bin/env perl
package GitTestSandbox::Custom;
use strict;
use warnings;
BEGIN {
  our @ISA = "GitTestSandbox";

  push @INC,"./t";
  require GitTestSandbox;
};

sub gen_repo_new_commit {
  my ($self,@params) = @_;
  sleep 1;
  $self->SUPER::gen_repo_new_commit(@params);
};


sub gen_repo_new_tag {
  my ($self,@params) = @_;
  sleep 1;
  $self->SUPER::gen_repo_new_tag(@params);
};

sub populate_with_commits {
  my ($self) = @_;
  $self->gen_repo_new_commit("$_ commit") for 2..5;
  $self->gen_repo_new_tag("0.1"  );
  $self->gen_repo_new_commit("$_ commit") for 6..7;

  # generate commits which are not in any tag, intentionally
  # (this actually means you'll get a warning from the consistency
  # checker)
};

use strict;
use warnings;
use Test::More 'no_plan';
use Data::Dumper;
use Carp;
use lib "./lib";
use Git::ConsistencyCheck;

my $sandbox = GitTestSandbox::Custom->new("./test-verify-up-to-date-");
$sandbox->gen_repo;
$sandbox->populate_with_commits;
$sandbox->run_git2deblogs;

# Test 1 , good changelog
my $o1 = Git::ConsistencyCheck->new({changelog_path => $sandbox->{mock_repo_path}."/debian/changelog" });
my $verify_output = $o1->verify_up_to_date_changelog();

ok($verify_output =~ /Time for last git commit different than last commit in changelog/,
   "verification 1 was good");
ok($verify_output =~ /Time for last commit in latest git tag is different than last version/,
   "verification 2 was good");


$sandbox->destroy_repo();
