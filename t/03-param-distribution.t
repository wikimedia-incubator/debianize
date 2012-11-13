#!/usr/bin/env perl
package GitTestSandbox::Custom;
use strict;
use warnings;
BEGIN {
  our @ISA = "GitTestSandbox";
  push @INC,"./t";
  require GitTestSandbox;
};

sub populate_with_commits {
  my ($self) = @_;
  $self->gen_repo_new_commit("$_ commit") for 2..5;
  $self->gen_repo_new_tag("0.1"  );
  $self->gen_repo_new_commit("$_ commit") for 6..7;
  $self->gen_repo_new_tag("0.2"  );

  # generate commits which are not in any tag, intentionally
  # (this actually means you'll get a warning from the consistency
  # checker)
};

sub run_git2deblogs {
  my ($self) = @_;
  my $mock_repo_path = $self->{mock_repo_path};

  `
  cd $mock_repo_path
  ln -s ../git2deblogs.pl git2deblogs
  ./git2deblogs --generate --distribution "test-distrib"
  `;
};

sub count_line_with_pattern {
  my ($self,$pattern) = @_;
  my $mock_repo_path = $self->{mock_repo_path};
  my $cmd = "grep \"$pattern\" $mock_repo_path/debian/changelog | wc -l";
  warn $cmd;
  my $count = `$cmd`;
  chomp $count;
  return $count;
}

use strict;
use warnings;
use Test::More 'no_plan';
use Data::Dumper;
use Carp;
use lib "./lib";


my $sandbox = GitTestSandbox::Custom->new("./test-param-distribution-");
$sandbox->gen_repo;
$sandbox->populate_with_commits;
$sandbox->run_git2deblogs;

ok( $sandbox->count_line_with_pattern("(0.2) test-distrib") == 1, "test-ditrib distribution name found in version 0.2");


$sandbox->destroy_repo();
