# Ebola predictive model
# Robert Ross Wardrup

#!/usr/bin/perl

use 5.14.2;
use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);
STDOUT->autoflush;

print "As of 8/19/2014, deaths follow the following line: y=-0.0005x^4 + 0.0461x^3 - 0.4059x^2 + 5.9856x + 53.931 \n";
print "with an r2 value of: 0.996. \n";

my $day = 0;
my $deaths = 0;

print "\nDuration of model in days: \n";
chomp(my $duration = <>);

print "Before initiation\n";
print "Deaths: ".$deaths."\n";

for(my $day = 0; $day < $duration; $day++)
{
	my $deaths = int((-0.0005 *$day^4) + (0.0461 * $day^3) - (0.4059 * $day^2) + (5.9856 * $day) + 53.931);
	print "Day ".$day."\n";
	print "Deaths: ".$deaths."\n";
}
