package Git::ConsistencyCheck;
use strict;
use warnings;
use Carp;
use File::Spec;
use Data::Dumper;
use List::Util qw(first);
use lib "./debianize/lib";
use lib "./lib";
use lib "../lib";
use Git::LogLineDate;

=begin new
  
  The constructor here is responsible for getting the changelog content
=cut


our $pat_version = '(\d+(?:(?:\.\d+)+))';

# Ex:
# -- Maintainer name  <name@website.com>  Fri, 2 Nov 2012 18:52:28 +0200
our $pat_maintainer_line = qr/^ -- (?<name>.*?) <(?<email>.*?)>\s\s(?<time>.*)/ ;

sub new {
  my ($class_name,$params) = @_;
  my $obj = {};

  croak "Error [". __PACKAGE__ ."] : was expecting a hashref as parameter"
    if ref($params) ne "HASH";

  $params->{changelog_path} ||= "debian/changelog";

  if($params->{changelog_path}) { 
    if( !-f $params->{changelog_path}) {
      use Cwd;
      print getcwd()."\n";
      croak "Error [". __PACKAGE__ ."] :  changelog path given but file doesn't exist";
    };

    $obj->{changelog_content} = `cat $params->{changelog_path}`;
  };

  $obj->{changelog_path} = File::Spec->rel2abs($params->{changelog_path});
  return bless $obj,$class_name;
};


=begin extract_debian_package_name

  Finds out the name of the debian package

=cut

sub extract_debian_package_name {
  my ($self) = @_;

  my ($volume,$directories,$file) =
      File::Spec->splitpath( $self->{changelog_path} );

  #warn "changelog_path:".$self->{changelog_path};
  #warn "volume:$volume";
  #warn "directories:$directories";
  #warn "file:$file";

  my $control_path = 
      File::Spec->catpath( $volume,$directories,"control");

  my $content_control = `cat $control_path`;

  my $package_name = $content_control =~ /^Package: (.*)$/;

  return $package_name;
};

=begin verify_changelog_duplicate_versions

  Verifies that the changelog does not have duplicates versions inside it
  (could be the result of a double --update)

 1) Check that there are no duplicate entries in the debian/changelog
 2) Don't update the debian/changelog there are problems with the changelog

=cut

sub verify_changelog_duplicate_versions {
  my ($self) = @_;
  my @changelog_lines = split(/\n/, $self->{changelog_content});
  my @versions = ();

  my $package_name = $self->extract_debian_package_name();
  for my $line (@changelog_lines) {
    if(my ($version) = $line =~ /.*\s\($pat_version\)\s.*; urgency=/) {
      if(first { $_ eq $version } @versions ) {
        return "Error  : Failed duplicate version verificiation\n";
      };
      push @versions, $version;
    };
  };

  return "";
}


sub verify_up_to_date_changelog {
  my ($self) = @_;

  my $retval = "";

  my @matches;
  my %h_matches;
  my $latest_version_maintainer_line = 
    first { 
      if(@matches = $_ =~ $pat_maintainer_line) {
        %h_matches = %+;
        return $_;
      } else {
      };
    }
    split(/\n/, $self->{changelog_content});



  if($latest_version_maintainer_line) {
    my ($volume,$directories,$file) =
      File::Spec->splitpath( $self->{changelog_path} );

    my $_cwd = "cd $directories";
    my $latest_tag                    = `$_cwd; git tag | tail -1`;
    chomp $latest_tag;
    warn "latest_tag: $latest_tag";
    my $latest_commit_from_latest_tag = `$_cwd; git rev-list $latest_tag | head -1`;
    chomp $latest_commit_from_latest_tag;
    my $latest_commit                 = `$_cwd; git rev-parse HEAD;`;
    chomp $latest_commit;


    my    $time_latest_commit                 = `$_cwd; git log $latest_commit | head -3 | tail -1`;
          $time_latest_commit                 =~ s/^Date:   //;
          chomp $time_latest_commit;
    my    $time_latest_commit_from_latest_tag = `$_cwd; git log $latest_commit_from_latest_tag | head -3 | tail -1`;
          $time_latest_commit_from_latest_tag =~ s/^Date:   (.*)\n/$1/;

    my $time_changelog_latest = Git::LogLineDate::changelog_to_git($h_matches{time});

    if($time_changelog_latest ne $time_latest_commit) {
      $retval .= "Warning: Time for last git commit different than last commit in changelog\n"
              .  "(Suggestion: Make a new tag and then ./git2deblogs --update)\n";
    };

    if($time_changelog_latest ne $time_latest_commit_from_latest_tag ) {
      $retval .= "Warning: Time for last commit in latest git tag is different than last version\n"
              .  "          in changelog (Suggestion: --generate)\n";
    };

  };

  return $retval;
}

sub consistency_check {
  my ($self) = @_;
  my $warnings = undef;
  $warnings .=  $self->verify_changelog_duplicate_versions();
  $warnings .=  $self->verify_up_to_date_changelog();

  # multiple checks go here ===> . <===

  if($warnings eq "") {
    $warnings = "OK";
  } else {
    $warnings = "Not OK\n\n$warnings";
  };
  return $warnings;
};


1;
