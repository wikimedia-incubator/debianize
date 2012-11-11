package Git::LogLineDate;
use strict;
use warnings;
use Data::Dumper;

our $pat_weekday = "(?<weekday>Mon|Tue|Wed|Thu|Fri|Sat|Sun)";
our $pat_month   = "(?<month>Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)";
our $pat_time    = '(?<time>\d+:\d+:\d+)';
our $pat_day     = '(?<day>\d+)';
our $pat_year    = '(?<year>\d+)';

#format that you get from git => Tue Oct 9 16:35:46 2012 +0300
#debian/changelog format      => Tue, 16 Oct 2012 09:41:14 +0300
sub git_to_changelog {
  my ($logline) = @_;
  #warn Dumper \@_;
  #warn "\n\n";
  $logline =~ s/^$pat_weekday\s+$pat_month\s+$pat_day\s+$pat_time\s+$pat_year/$+{weekday}, $+{day} $+{month} $+{year} $+{time}/;
  return $logline;
};

sub changelog_to_git {
  my ($logline) = @_;
  $logline =~ s/^$pat_weekday\s+$pat_day\s+$pat_month\s+$pat_year\s+$pat_time/$+{weekday} $+{day} $+{month} $+{year} $+{time}/;
  return $logline;
};

1;
