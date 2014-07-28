#SIR based disease spread model in perl..

#!/usr/bin/perl

use 5.10.1;
#use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);

#Initialize variables and parameters
my $NUM_IND = 500;
my $CONTACT_RATE = 5;
my $INFECTIOUS_PERIOD = 4;
my $INFECTIVITY = 0.1;
my $DURATION = 50;

my %population = ();

#generate population by adding elements to population structure
for(my $i = 0; $i< $NUM_IND; $i++) {
	$population{$i}{'infState'} = 0; #infection state: s=0, i=1, r=2
	$population{$i}{'age'} = int(rand(80));
	$population{$i}{'dayOfInf'} = 0;
	#$population{$i}{'x'} =
	#$population{$i}{'y'} = 
}

#Infect a few individuals to start off the epidemic
for(my $i = 0; $i < 5; $i++) {
	$in = int(rand($NUM_IND));
	$population{$in}{'infState'} = 1;
}

#print S,I,R before start of simulation
my $sus = 0;
my $inf = 0;
my $rec = 0;
foreach my $person (keys %population) {
	if($population{$person}{'infState'} == 0) {
		$sus++;
	}
	if($population{$person}{'infState'} == 1) {
		$inf++;
	}
	if($population{$person}{'infState'} == 2) {
		$rec++;
	}
}


print "Before initiation\n";
print "SUS: ".$sus."\tINF: ".$inf."\tREC: ".$rec."\n";

#generating contacts
#create a clone of %population
#for each of the individuals in the original struct, make contacts and update state in the clone
#after itterating through the hash, swap contents of clone to original 


#Run the simulation for each day
for(my $day = 0; $day < $DURATION; $day++) {
	#Creating a temporary copy of population to make updates to infection state
	my %population_copy = %{dclone(\%population)};

	#Generate contacts for each person
	foreach my $person (keys %population) {
		#for every infected person make CR contacts in the clone
		#update stats of the contacted person 
		if($population{$person}{'infState'} == 1) {
			#my @contacts;
			for(my $i = 0; $i<$CONTACT_RATE; $i++) {
				#Making sure that a person doesnt contact himself
				my $r = $person;
				while($r == $person ) {
					$r = int(rand($NUM_IND));
				}
				#$contacts[$i] = $r;
				#Infect contated person based on infectivity
				if(rand() < $INFECTIVITY) {
					if($population_copy{$r}{'infState'} == 0){
						$population_copy{$r}{'infState'} = 1;
					}	
				}	
			}			
		
		}
	
	}
	
	#copy contents of temporary copy to original one
	%population = %{dclone(\%population_copy)};

	#Update stats for each person at the end of a day
	foreach my $person (keys %population) {
		if($population{$person}{'infState'} == 1) {
			$population{$person}{'dayOfInf'}++;
			if($population{$person}{'dayOfInf'} >= $INFECTIOUS_PERIOD) {
				$population{$person}{'infState'} = 2;
			}
		}
	}

	#Print population stats at the end of the day
	my $sus = 0;
	my $inf = 0;
	my $rec = 0;
	foreach my $person (keys %population) {
		if($population{$person}{'infState'} == 0) {
			$sus++;
		}
		if($population{$person}{'infState'} == 1) {
			$inf++;
		}
		if($population{$person}{'infState'} == 2) {
			$rec++;
		}
	}


	print "Day ".$day."\n";
	print "SUS: ".$sus."\tINF: ".$inf."\tREC: ".$rec."\n";
	#print Dumper(\%population);
	#print "\n-------------\n";
	#print Dumper(\%population_copy);
	#print "\n-------------\n";

} 	

