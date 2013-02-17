#!/usr/bin/env perl
use Carp;
use Getopt::Long;
use lib "./lib";
use lib "./debianize/lib";
use lib "../lib";
use Git::ConsistencyCheck;
use Git::ToChangelog;

sub get_options {
  my $opt = {
    "generate"               => undef,
    "update"                 => undef,
    "force-maintainer-name"  => undef,
    "force-maintainer-email" => undef,
    "verbose"                => undef,
    "package-name"           => undef,
    "wikimedia"              => undef,
  };

  GetOptions(
    "generate"                 => \$opt->{"generate"}               ,
    "update"                   => \$opt->{"update"}                 ,
    "force-maintainer-name=s"  => \$opt->{"force-maintainer-name"}  ,
    "force-maintainer-email=s" => \$opt->{"force-maintainer-email"} ,
    "verbose"                  => \$opt->{"verbose"}                ,
    "consistency-check"        => \$opt->{"consistency-check"}      ,
    "distribution=s"           => \$opt->{"distribution"}           ,
    "package-name=s"           => \$opt->{"package-name"}           ,
    "wikimedia"                => \$opt->{"wikimedia"}              ,
  );


  if(!$opt->{"generate"}            && 
     !$opt->{"update"}              &&
     !$opt->{"consistency-check"}   &&
     !$opt->{"update"}            
   ) {
    die   "Error: One of the following options is mandatory\n".
          "                                                \n".
          "        --generate                              \n".
          "        --update                                \n".
          "        --consistency-check                     \n".
          "        --update                                \n";
  };
# adding RFC822PAT later,
  # this will do for the moment
  if($opt->{"force-maintainer-email"} ) {
    if($opt->{"force-maintainer-email"} !~ /.*\@.*\..*/) {
      croak "Error: Email for maintainer specified but email is not valid";
    };
  };


  if($opt->{"consistency-check"}) {
    my $o = Git::ConsistencyCheck->new({});
    my $warnings = $o->consistency_check();
    print $warnings;
  };

  return $opt;
};


sub check_valid_options {
  my ($opt) = @_;

  my $any_options = 0;
  map {
    $any_options |= defined($opt->{$_});
  } keys %$opt;

  if(!$any_options) {
    croak "You're supposed to provide some cmdline switches";
  };
};


$Carp::Verbose = 1;

my $opt = get_options();
check_valid_options($opt);
my $o = Git::ToChangelog->new($opt);

#
# Usage examples:
#
# ./git2deblogs --generate --force-maintainer-name="<name>" --force-maintainer-email=<email>
#
# 

if(       $opt->{"distribution"} && 
   length $opt->{"distribution"} > 1) {
  $o->{distribution} = $opt->{distribution};
};

if( $opt->{wikimedia} ) {
  my $debian_distro = `lsb_release -s -c`;
  chomp $debian_distro;
  $o->{_distroname}  = $debian_distro;
  $o->{distribution} = "$debian_distro-wikimedia";
  $o->{wikimedia} = 1;
};

my $pkgname = $opt->{"package-name"} // `basename \`pwd\``;
chomp $pkgname;
$pkgname = "\"$pkgname\"";
print "$pkgname\n";

if($opt->{generate}) {
  $o->generate($pkgname);
};

if($opt->{update}) {
  $o->update($pkgname);
};


