#!/usr/bin/env perl
use strict;
use warnings;
use lib "./lib";
use Test::More;
use Git::Util;


is(Git::Util->compare_versions("0.1"   , "0.2")   , -1 , "0.1   <  0.2"  );
is(Git::Util->compare_versions("0.2"   , "0.1")   , +1 , "0.2   >  0.1"  );
is(Git::Util->compare_versions("0.1.1" , "0.1.1") , 0  , "0.1.1 == 0.1.1");
is(Git::Util->compare_versions("0.1"   , "0.1.1") , -1 , "0.1   <  0.1.1");
is(Git::Util->compare_versions("0.1.1" , "0.1")   , +1 , "0.1.1 >  0.1  ");
is(Git::Util->compare_versions("0.1.2" , "0.1.1") , +1 , "0.1.2 >  0.1.1");

done_testing;
