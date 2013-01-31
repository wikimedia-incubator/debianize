#!/usr/bin/env perl
package Git::ToChangelog;
=begin 

 git2deblogs   --  An utility to keep your git logs in sync with your debian/changelog

=cut

BEGIN {
  use Carp;
  sub try_load {
    my $mod = shift;
    eval("use $mod");
    if ($@) {
      #print "\$@ = $@\n";
      return(0);
    } else {
      return(1);
    }
  };

  if(!try_load("JSON::XS")) {
    confess "
[ERROR] You don't have JSON::XS installed. 
  Solutions: 1) cpanm JSON::XS
             2) sudo aptitude install libjson-xs-perl
    \n";
  };

  if(`whereis dch | perl -ne 'chomp; s/^.*?://; print \$_ ? 0 : 1;'`) {
    confess "
[ERROR] You don't have dch installed. 
  Solutions: 1) sudo aptitude install devscripts
    \n";
  };
}

use strict;
use warnings;
use Data::Dumper;
use JSON::XS;
use Carp;
use lib "./debianize/lib";
use lib "./lib";
use lib "../lib";
use Git::LogLineDate;


=begin

 For possible contributions: Please stick as much as possible to using just modules from
 Perl CORE   http://perldoc.perl.org/index-modules-A.html
 so as to avoid adding dependencies.


 This script creates a debian changelog.

 There are some assumptions made and listed below.
 This script should only be used if you agree with these assumptions:

              1) all tags are made from commits on master.
              2) there is at least one commit per tag(will fix this later, but it's quite common)
              3) the first tag begins with the first commit
              4) you number your tags with common version numbers
              5) the maintainer of the package for a specific version is the person who made the tag
 

 
 
 TODO: read more docs about git commits and find out if they are specific to a branch. look into using   git log --branches= if that is the case
       (otherwise mention as an assumption that we assume we only process all tags made on master branch)
 TODO: add switches for verbosity that will show any external command run with all its parameters
 TODO: add switch to group commits by author  name
 TODO: add switch to just get the latest commits and not regenerate the whole thing from scratch
 TODO: drop dch altogether and write code that will do the same things as its doing(calling dch to update the changelog or create a new version
       is proving to cause some massive delays).

 
 BUG: seems to be missing the very first commit message(need to fix this)
 BUG: on webstatscollector one of the commits shows up just with the name on it


 For example, this will be the output of get_tag_info()
  {
    'name' => '0.1',
    'end' => '7e03f97de1d2d87a16eca5dc1240047f47251092',
    'start' => '823b3b7ad417a0e239dd78517b95d9518978abe4'
  },
  {
    'name' => '0.2',
    'end' => 'ce14a505b1fa81aafdd6b8dae835e94aa75fa800',
    'start' => 'f7a8da68a020b55bf0da33fe22b8fe05eaaef279'
  },
  {
    'name' => '0.3',
    'end' => 'be7ba49d5e97dca14263f3753e9540ac02effac4',
    'start' => '50596c9b6b7ae9d499ca280189914545680906aa'
  },
  {
    'name' => '0.4',
    'end' => 'e17f11f68f207949d2daf73e360b11d0dcf69e33',
    'start' => '92b0cb425113799d5812e92dd25c60246316a881'
  }
  

 For reference, this is the
 output of  git rev-list 0.4 | tac -
 (so commits, before and including 0.4)

 823b3b7ad417a0e239dd78517b95d9518978abe4  \
 3676cce39aa7f554f5c309186791e14a3e61c617  |
 80b18c9c9ff83aa484e6d391c4a8effaece811d0  |=> 0.1
 de1912460962b2aa099657e870cca8597ec14c75  |
 7e03f97de1d2d87a16eca5dc1240047f47251092  /
 f7a8da68a020b55bf0da33fe22b8fe05eaaef279  \
 bdd23196579bf19ab4faff8d240a67b53b5f25f6  |
 68d252a5f4a6f5203f1f6df16f215b4e2ed932fb  |=> 0.2
 44b59ec597ec5ab8798b039996357e9c636f2b84  |
 ce14a505b1fa81aafdd6b8dae835e94aa75fa800  /
 50596c9b6b7ae9d499ca280189914545680906aa  \
 3298cf12d901973d5bce0fefe84caf58d2154de8  |
 bfe848f66eb5f74bc65f741a82ee5ca4cb44f962  |=> 0.3
 9f743af1a849bfc44fb6c51584336463c51f4a95  |
 be7ba49d5e97dca14263f3753e9540ac02effac4  /
 92b0cb425113799d5812e92dd25c60246316a881  \
 af5c5a0d5146e118d2a8f28b062fa1466014ef67  |=> 0.4
 d6c4a2473a6cbf897cb61b70eb2edf8f9a18e14a  |
 e17f11f68f207949d2daf73e360b11d0dcf69e33  /


=cut



=begin new
 constructor
=cut

sub new {
  my ($class_name,$opts) = @_;
  my $obj = {};
  if($opts->{"force-maintainer-name"}) {
    $obj->{"force-maintainer-name"} = $opts->{"force-maintainer-name"};
  };
  if($opts->{"force-maintainer-email"}) {
    $obj->{"force-maintainer-email"} = $opts->{"force-maintainer-email"};
  };
  return bless $obj,$class_name;
};


=begin get_tag_info
 get tag information like name, start comming hash, end commit hash
=cut

sub get_tag_info {
# get all tag names in an array

  my @tags;
  # get only tags of the following form
  #     \d+  or
  #     \d+.\d+ or
  #     \d+.\d+.\d+
  #     etc

  my @tag_names    = 
    sort { 
            my @A = split(/\./,$a); 
            my @B = split(/\./,$b); 
            $A[0] <=> $B[0] ||
            $A[1] <=> $B[1] ||
            $A[2] <=> $B[2]   
         }
    grep { /^\d+(?:(?:\.\d+)+)$/ } 
    split /\n/,`git tag`;


  if(@tag_names == 0) {
    croak "Error: Please make some tags (e.g. \"0.1.3\") ." 
  };

  # all the commit hashes of the latest tag(containing all the commit hashes of all the tags)
  my $all_tag_cmd = "git rev-list ".$tag_names[-1];

  # commit hashes in chronological order, all the commits of the latest tag
  my @all_tag_commits = reverse split /\n/,`$all_tag_cmd`;

  # commit hashes also in chronological order <== only the tag end commits specifically
  my @tag_end_commits = map { `git rev-list $_ | head -1` =~ /^([^\n]+)/  } @tag_names;

  push @tags, {
    name  => $tag_names[0]      ,
    start => $all_tag_commits[0],
    end   => $tag_end_commits[0],
  };

  #iterate through $tag_names ( start at 1 because we already processed one tag just above )
  my $t = 1;
  #iterate through $all_tag_commits
  my $a = 0;

  warn Dumper \@tag_names;
  while($t < @tag_names) {
    # find next end commit in @all_tag_commits

    while($a+1 < @all_tag_commits && $all_tag_commits[$a++] ne $tag_end_commits[$t-1]){};

    push @tags, {
      name  => $tag_names[$t],
      start => $all_tag_commits[$a-1],
      end   => $tag_end_commits[$t],
    };


    # here we check if the previous tag end is equal to the current one's start.
    # actually when you run  git log commit_hash1..commit_hash2 , this will give you the results
    # of the first commit after commit_hash1 up to commit_hash2 , so that's why we need this.
    #
    croak "assert previous tag end equals current tag start failed [t=$t]" if
      $t !=0 &&
      $tags[$t]->{start} ne $tags[$t-1]->{end};
    $t++;
  };

  return @tags;
};



=begin git_log_to_array(..) will return an array with commits from git-log output

 input: two commit sha1 hashes
 output: data for each commit in the range provided 
         in the input
=cut


sub git_log_to_array {
  my $self = shift;
  my @params = @_;
  my $git_log_cmd =  qq{git  log --reverse --pretty=format:'{%n "commit": "%H", %n  "author": "%an <%ae>",%n  "date": "%ad",%n  "message": "%s"%n},'};


  if(@params == 2) {
    $git_log_cmd.=" $params[0]..$params[1]";
  } elsif( @params == 1) {
    $git_log_cmd.=" -1 $params[0]";
  } else {
    croak "Error: Wrong number of params to git_log_to_array";
  };

  print "$git_log_cmd\n";

  my $git_log_output =  `$git_log_cmd`;
  $git_log_output=~s/},\s*$/}/;
  #print $git_log_output;

  $git_log_output=~s/^/  /gmxs; # indent output
  $git_log_output = "{ \"commits\": [ $git_log_output ] }"; # wrap it up in some braces so it's valud json


  # commit messages containing quotes will have their quotes escaped by this
  $git_log_output =~ s["message": ..(.*?).$ ] {
    my $val = $1;
    $val =~ s/"/\\"/g;

    # some characters that cause problems(quickfix for now)
    $val =~ s/-/ /g;
    $val =~ s/\(/ /g;
    $val =~ s/\)/ /g;
    "\"message\": \"$val\"";
  }eisxgms;


  # take newlines out of author
  $git_log_output =~ s["author": (.*?)$ ] {
    my $val = $1;
    $val =~ s/\n/ /g;
    "\"author\": $val";
  }eisxgms;


  #print $git_log_output;
  #exit 0;
  #print "$git_log_output";
  #exit 0;
  my $json_log = decode_json($git_log_output);
  return $json_log->{commits};
};


=begin dch_append_commit
 add some commit messages to current version
=cut


sub dch_append_commit {
  my ($self,$commit) = @_;

  my ($author_name) = $commit->{author} =~ /^\s*(.*?)</;
  my $commit_message = $commit->{message};
  
  `NAME="$author_name" dch -a "$commit_message"`;
};


=begin get_tag_creation_commit_data 
 Get the data associated with the person who made the tag
=cut

sub get_tag_creation_commit_data {
  my ($self,$tag_name) = @_;

  my $git_show_output = `git show $tag_name | head -3 | tail -2`;
  #warn "git_show_output=[$git_show_output]";
  my $commit = {
    date        => "",
    email       => "",
    name        => "",
    tag_message => "",
  };

  ($commit->{date}   )  = $git_show_output =~              /Date:\s*(.*)$/;
  ($commit->{name}   )  = $git_show_output =~     /Tagger:\s+([^<]*)</gxms;
  ($commit->{email}  )  = $git_show_output =~  /Tagger:[^<]*?<(.*?)>$/gxms;
  $commit->{message}    =              "Tag created for version $tag_name";

  return $commit;
}



=begin create a new version ( for new tag )

 creating a new version for the package.
 upon the first version, the changelog is being created, the 
 changelog is being created.
=cut


sub dch_create_new_version {
  my ($self,$tag_name,$is_first_version,$package_name) = @_;

  my $maintainer = $self->get_tag_creation_commit_data($tag_name);

  $package_name = lc($package_name);

  if($self->{wikimedia}) {
    warn "[DBG] wikimedia !";
    $tag_name .= "~".$self->{_distroname};
  };

  if($is_first_version) {
    my $maintainer_name  = $maintainer->{name} ;
    my $maintainer_email = $maintainer->{email};
    my $env_params = qq{NAME="$maintainer_name" EMAIL="$maintainer_email"};
    my $cmd = qq{  dch --create -v $tag_name --package "$package_name" "Created new $tag_name version from tag $tag_name"};
    warn "[DBG] package name => [$package_name]";
    system($cmd);
  } else {
    my $param_distribution = "";
    if($self->{distribution}) {
      $param_distribution = "--force-distribution -D \"$self->{distribution}\"";
    };
    my $param_version = qq{--newversion "$tag_name"};
    my $param_message = qq{"Created new $tag_name version from tag $tag_name"};
    `NAME="$maintainer->{name}" dch $param_version $param_message $param_distribution;`
  };
};


=begin dch_add_maintainer_details

  Adding maintainer details after adding all the commit data in a particular tag(/version)

=cut



sub dch_add_maintainer_details {
  my ($self,$tag_name) = @_;
  # what this command does is, it ignores the "date -R" command inside dch
  # and it lets you decide the date you want to appear in the changelog
  # as well as the email and name of the maintainer(all of which are taken from the git repo)
  #
  # this function should be run after all the commits in that tag have been added.
  # this is because 




  my $cmd_template = q{TZ='\"\";echo \"[MAINTAINER_TAG_CREATION_DATE]\"; #' EMAIL="[MAINTAINER_EMAIL]"  NAME="[MAINTAINER_NAME]" dch -a "[MAINTAINER_TAG_MESSAGE]";};
  my $cmd_rendered = $cmd_template;

  my $maintainer = $self->get_tag_creation_commit_data($tag_name);


  if($self->{"force-maintainer-name"}) {
    $maintainer->{name} = $self->{"force-maintainer-name"} 
                          || $maintainer->{name};
  };

  if($self->{"force-maintainer-email"}) {
    $maintainer->{email} = $self->{"force-maintainer-email"} 
                          || $maintainer->{email};
  };


  #fix date(convert from "git show" format to debian/changelog format
  print "[!!] BEFORE: ".$maintainer->{date}."\n";
  $maintainer->{date} = Git::LogLineDate::git_to_changelog($maintainer->{date});
  print "[!!] AFTER:  ".$maintainer->{date}."\n";


  $cmd_rendered =~ s/\[MAINTAINER_TAG_CREATION_DATE\]/$maintainer->{date}/;
  $cmd_rendered =~ s/\[MAINTAINER_EMAIL\]/$maintainer->{email}/;
  $cmd_rendered =~ s/\[MAINTAINER_NAME\]/$maintainer->{name}/;
  $cmd_rendered =~ s/\[MAINTAINER_TAG_MESSAGE\]/$maintainer->{message}/;


  #print "$cmd_rendered";

  `$cmd_rendered`;
}

=begin dch_init_changelog will 

 1) backup current changelog
 2) create a brand new changelog
 3) go over all tags and add data from the git log and sync it with the debian/changelog

 Warning: only use this for the first time you want to make the changelog
=cut

sub dch_init_changelog {
  my ($self,$package_name) = @_;

  # get all the tags that conform to common versioning schemes
  my @tags = $self->get_tag_info();
  my $backup_timestamp = `date +%m-%d-%y_%H-%M-%S`;
  chomp $backup_timestamp; 


  # backup changelog if it already exists
  if(-f "debian/changelog") {
    `
    mkdir changelog_backup/;
    mv debian/changelog changelog_backup/debian_changelog_$backup_timestamp;
    `;
  };

  my $first_version = 1;

  # iterate over all tags
  for my $tag_idx (0..(-1+@tags)) {
    my $tag = $tags[$tag_idx];
    print "Sync-ing commits for $tag->{name} ... \n";
    #get the commits for that tag(only the ones made between the last tag and this one)

    my $tag_commits;

    if($tag->{start} ne $tag->{end}) {
      $tag_commits = $self->git_log_to_array($tag->{start},$tag->{end});
    } else {
      $tag_commits = $self->git_log_to_array($tag->{start});
    };

    # create a new version in the changelog
    $self->dch_create_new_version($tag->{name},$first_version,$package_name);

    # fixup because first commit is missed
    if($tag_idx == 0) {
      my @retval = $self->git_log_to_array($tag->{start});
      my $commit = @{$retval[0]}[0];
      my $changelog_message = "$commit->{message} [ $commit->{author} ]";
      print "changelog_msg=$changelog_message\n";
      $self->dch_append_commit($commit);
    };

    for my $commit(@$tag_commits) {
      # add each commit of the tag to the debian/changelog
      my $changelog_message = "$commit->{message} [ $commit->{author} ]";
      print "changelog_msg=$changelog_message\n";
      $self->dch_append_commit($commit);
    };

    $self->dch_add_maintainer_details($tag->{name});
    $first_version = 0;
  };
};



package main;
use Carp;
use Getopt::Long;
use lib "./lib";
use lib "./debianize/lib";
use lib "../lib";
use Git::ConsistencyCheck;

sub get_options {
  my $opt = {
    "generate"               => undef,
    "update"                 => undef,
    "force-maintainer-name"  => undef,
    "force-maintainer-email" => undef,
    "verbose"                => undef,
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
    "wikimedia"                => \$opt->{"wikimedia"}              ,
  );


  if(!$opt->{"generate"}            && 
     !$opt->{"update"}              &&
     !$opt->{"consistency-check"}   
   ) {
    die   "Error: One of the following options is mandatory\n".
          "                                                \n".
          "        --generate                              \n".
          "        --update                                \n".
          "        --consistency-check                     \n";
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


if($opt->{generate}) {
  my $opt_pkgname = `basename \`pwd\``;
  chomp $opt_pkgname;

  $opt_pkgname = "\"$opt_pkgname\"";
  print "$opt_pkgname\n";
  $o->dch_init_changelog($opt_pkgname);
};

