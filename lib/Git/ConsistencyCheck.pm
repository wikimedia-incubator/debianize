package Git::ConsistencyCheck;
use strict;
use warnings;
use Carp;
use File::Spec;
use List::Util qw(first);

=begin new
  
  The constructor here is responsible for getting the changelog content
=cut


our $pat_version = '(\d+(?:(?:\.\d+)+))';

sub new {
  my ($class_name,$params) = @_;
  my $obj = {};

  croak "Error [". __PACKAGE__ ."] : was expecting a hashref as parameter"
    if ref($params) ne "HASH";

  $params->{changelog_path} ||= "debian/changelog";

  if($params->{changelog_path}) { 
    if( !-f $params->{changelog_path}) {
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
  my $package_name = $self->extract_debian_package_name();

  my @changelog_lines = split(/\n/, $self->{changelog_content});

  #my ($weekday,$day,$month,$year,$time) = @_;
  
  return "";
}

sub consistency_check {
  my ($self) = @_;
  my $warnings = undef;
  $warnings .=  $self->verify_changelog_duplicate_versions();
  $warnings .=  $self->verify_up_to_date_changelog();

  # multiple checks go here ===> . <===

  if(!defined($warnings)) {
    $warnings = "OK";
  } else {
    $warnings = "Not OK\n\n$warnings";
  };
  return $warnings;
};


1;
