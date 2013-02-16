package Git::Util;
use strict;
use warnings;
use List::Util qw/max min reduce/;

sub compare_versions {
  my ($self,$_a,$_b) = @_;
  my @A = split(/\./,$_a);
  my @B = split(/\./,$_b);
  my $len_A = ~~@A;
  my $len_B = ~~@B;
  my $l = -1+min($len_A,$len_B);
  my $retval = (reduce { $a || $b }
               (map    { $A[$_] <=> $B[$_] }
               (0..$l)));

  if(!$retval) {
    if(     $len_A > $len_B) {
      $retval =  1;
    } elsif($len_A < $len_B) {
      $retval = -1;
    };
  };

  return $retval;
};

1;
