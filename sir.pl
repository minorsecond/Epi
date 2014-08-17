#SIR based disease spread model in perl.
# Robert Ross Wardrup

#!/usr/bin/perl

use 5.10.1;
#use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);

# Ebola infectious period is 2-21 days. 14 is used as a middle point.
# Don't yet know the infectivity or contact rate. Leaving at defaults.
my $NUM_IND = 5000;
my $CONTACT_RATE = 5;
my $INFECTIOUS_PERIOD = 14;
my $INFECTIVITY = 0.1;
my $INCUB = 5;
my $DURATION = 365;

my %population = ();

#generate population by adding elements to population structure
for(my $i = 0; $i< $NUM_IND; $i++) 
{
	$population{$i}{'infState'} = 0; #infection state: s=0, e=1, i=2, r=3
	$population{$i}{'age'} = int(rand(80));
	$population{$i}{'dayOfInf'} = 0;
	$population{$i}{'dayofExp'} = 0;
	#$population{$i}{'x'} =
	#$population{$i}{'y'} = 
}

#Expose a few individuals to start off the epidemic
for(my $i = 0; $i < 5; $i++) 
{
	$in = int(rand($NUM_IND));
	$population{$in}{'infState'} = 1;
}

#print S,I,R before start of simulation. s=0, e=1, i=2, r=3
my $sus = 0;
my $exp = 0;
my $inf = 0;
my $rec = 0;
foreach my $person (keys %population) 
{
	if($population{$person}{'infState'} == 0) {
		$sus++;
	}
	if($population{$person}{'infState'} == 1) {
		$exp++;
	}
	if($population{$person}{'infState'} == 2) {
		$inf++;
	}
	if($population{$person}{'infState'} == 3) {
		$rec++;
	}
}


print "Before initiation\n";
print "SUS: ".$sus."\tEXP: ".$exp."\tINF: ".$inf."\tREC: ".$rec."\n";

#generating contacts
#create a clone of %population
#for each of the individuals in the original structure, make contacts and update state in the clone
#after iterating through the hash, swap contents of clone to original 


#Run the simulation for each day
for(my $day = 0; $day < $DURATION; $day++) 
{
	#Creating a temporary copy of population to make updates to infection state
	my %population_copy = %{dclone(\%population)};

	#Generate contacts for each exposed person
	foreach my $person (keys %population) 
	{
		#for every exposed person make CR contacts in the clone
		#update stats of the contacted person 
		if($population{$person}{'infState'} == 1) 
		{
			for(my $i = 0; $i<$CONTACT_RATE; $i++) 
			{
				#Making sure that a person doesnt contact himself
				my $r = $person;
				while($r == $person ) 
				{
					$r = int(rand($NUM_IND));
				}
				#Infect contacted person based on infectivity
				if(rand() < $INFECTIVITY) 
				{
					if($population_copy{$r}{'infState'} == 0)
					{
						$population_copy{$r}{'infState'} = 1;
					}	
				}	
			}			
		
		}
	
	}

	#Generate contacts for each infected person
	foreach my $person (keys %population) 
	{
		#for every infected person make CR contacts in the clone
		#update stats of the contacted person 
		if($population{$person}{'infState'} == 2) 
		{
			for(my $i = 0; $i<$CONTACT_RATE; $i++) 
			{
				#Making sure that a person doesnt contact himself
				my $r = $person;
				while($r == $person ) 
				{
					$r = int(rand($NUM_IND));
				}
				#Infect contacted person based on infectivity
				if(rand() < $INFECTIVITY) {
					if($population_copy{$r}{'infState'} == 0)
					{
						$population_copy{$r}{'infState'} = 1;
					}	
				}	
			}			
		
		}
	
	}

	
	#copy contents of temporary copy to original one
	%population = %{dclone(\%population_copy)};

	#Update stats for each person at the end of a day.
	foreach my $person (keys %population) 
	{
		if($population{$person}{'infState'} == 1) 
		{
			$population{$person}{'dayOfExp'}++;
			if($population{$person}{'dayOfExp'} >= $INCUB) 
			{
				$population{$person}{'infState'} = 2;
			}
		}
		
		if($population{$person}{'infState'} == 2)
		{
			$population{$person}{'dayofInf'}++;
			if($population{$person}{'dayofInf'} >= $INFECTIOUS_PERIOD)
			{
				$population{$person}{'infState'} = 3;
			}
		}
	}


# Print population stats at the end of the day
	my $sus = 0;
	my $exp = 0;
	my $inf = 0;
	my $rec = 0;
	foreach my $person (keys %population) 
	{
		if($population{$person}{'infState'} == 0) 
		{
			$sus++;
		}
		if($population{$person}{'infState'} == 1) 
		{
			$exp++;
		}
		if($population{$person}{'infState'} == 2)
		{
			$inf++;
		}
		if($population{$person}{'infState'} == 3) 
		{
			$rec++;
		}
	}


	print "Day ".$day."\n";
	print "SUS: ".$sus."\tEXP: ".$exp."\tINF: ".$inf."\tREC: ".$rec."\n";
	#print Dumper(\%population);
	#print "\n-------------\n";
	#print Dumper(\%population_copy);
	#print "\n-------------\n";

} 	

