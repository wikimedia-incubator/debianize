#!/usr/bin/env perl
package GitTestSandbox::Custom;
use strict;
use warnings;
BEGIN {
  our @ISA = "GitTestSandbox";
  push @INC,"./t";
  require GitTestSandbox;
};

sub populate_for_generate {
  my ($self) = @_;
  $self->gen_repo_new_commit("$_ commit") for 2..5;
  $self->gen_repo_new_tag("0.1"  );
  $self->gen_repo_new_commit("$_ commit") for 6..7;
  $self->gen_repo_new_tag("0.2"  );

  # generate commits which are not in any tag, intentionally
  # (this actually means you'll get a warning from the consistency
  # checker)
};

sub populate_for_update {
  my ($self) = @_;
  $self->gen_repo_new_commit("$_ commit") for 8..10;
  $self->gen_repo_new_tag("0.2.1"  );
};

sub run_git2deblogs {
  my ($self) = @_;
  my $mock_repo_path = $self->{mock_repo_path};

  `
  cd $mock_repo_path
  ln -s ../git2deblogs.pl git2deblogs
  ./git2deblogs --generate --distribution "precise"
  `;
};

sub run_git2deblogs_update {
  my ($self) = @_;
  my $mock_repo_path = $self->{mock_repo_path};

  return `
  cd $mock_repo_path
  ./git2deblogs --update --distribution "precise" 2>&1
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

package main;
use strict;
use warnings;
use Test::More qw/no_plan/;
use Data::Dumper;
use Carp;
use lib "./lib";


my $sandbox = GitTestSandbox::Custom->new("./test-update-");

$sandbox->gen_repo;
$sandbox->populate_for_generate;
$sandbox->run_git2deblogs;
is($sandbox->count_line_with_pattern("(0.1) precise"),1,"precise 0.1");
is($sandbox->count_line_with_pattern("(0.2) precise"),1,"precise 0.2");

#=========================================

$sandbox->populate_for_update;
my $output_update = 
$sandbox->run_git2deblogs_update;
#warn "======";
#warn $output_update;
#is($sandbox->count_line_with_pattern("(0.1) precise")  ,1  ,"precise 0.1");
#is($sandbox->count_line_with_pattern("(0.2) precise")  ,1  ,"precise 0.2");
is($sandbox->count_line_with_pattern("(0.2.1) precise"),1  ,"precise 0.2.1");
is($sandbox->count_line_with_pattern("precise"),3,"there are 3 tags in the changelog");

$sandbox->destroy_repo();

#done_testing;
