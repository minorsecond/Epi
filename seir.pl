#SIR based disease spread model in perl.
# Robert Ross Wardrup

#!/usr/bin/perl

use 5.14.2;
use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);
STDOUT->autoflush;

my $in = 0;
	
print "Enter number of individuals: ";
chomp(my $NUM_IND = <STDIN>);
exit 0 if ($NUM_IND eq "");

print "Enter initial number of infections: ";
chomp(my $INIT = <STDIN>);
exit 0 if ($INIT eq "");

print "Enter number contacts per individual: ";
chomp(my $CONTACT_RATE = <STDIN>);
exit 0 if ($CONTACT_RATE eq "");

print "Enter disease infectious period: ";
chomp(my $INFECTIOUS_PERIOD = <STDIN>);
exit 0 if ($INFECTIOUS_PERIOD eq "");

print "Enter disease virulence: ";
chomp(my $INFECTIVITY = <STDIN>);
exit 0 if ($INFECTIVITY eq "");

print "Enter disease incubation period: ";
chomp(my $INCUB = <STDIN>);
exit 0 if ($INCUB eq "");

print "Enter number of vaccinations per day: ";
chomp(my $VAC = <STDIN>);

print "Enter vaccine efficacy: ";
chomp(my $EF = <STDIN>);

print "Enter duration of model: ";
chomp(my $DURATION = <STDIN>);
exit 0 if ($DURATION eq "");

my $R0 = $CONTACT_RATE * $INFECTIVITY * $INFECTIOUS_PERIOD;
my $V0 = (1 - 1 / $R0) * $NUM_IND;
print "\n***Basic Reproductive Rate (R0): $R0.***\n";
print "***Number to vaccinate to prevent sustained spread: $V0.***\n";

print "Use this number in vaccination calculation? (Y/n)\n";
$_ = <>;
$VAC = $V0 / $DURATION if /^Y/i;
print "\n ";

{
	local( $| ) = ( 1 );
	print "Press <enter> to continue. ";
	my $resp = <STDIN>;
}

my %population = ();

#generate population by adding elements to population structure
for(my $i = 0; $i< $NUM_IND; $i++) 
{
	$population{$i}{'infState'} = 0;
	$population{$i}{'age'} = int(rand(80)); #unused at the moment.
	$population{$i}{'dayOfInf'} = 0;
	$population{$i}{'dayofExp'} = 0;
	$population{$i}{'vacState'} = 0;
}

#Expose a few individuals to start off the epidemic
for my $i (0 .. $INIT-1)
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
print "SUS: ".$sus."\tEXP: ".$exp."\tINF: ".$inf."\tREM: ".$rec."\n";

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
			for my $i (0 .. $CONTACT_RATE-1)
			{
				#Making sure that a person doesnt contact himself
				my $r = $person;
				while($r == $person) 
				{
					$r = int(rand($NUM_IND));
				}
				#Expose person
				if(rand() < $INFECTIVITY)
				{
					if($population_copy{$r}{'infState'} == 0)
					{
						if($population_copy{$r}{'vacState'} == 0)
						{
						$population_copy{$r}{'infState'} = 1;
						}
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
			for my $i (0 .. $CONTACT_RATE-1)
			{
				#Making sure that a person doesnt contact himself
				my $r = $person;
				while($r == $person) 
				{
					$r = int(rand($NUM_IND));
				}
				#Infect contacted person based on infectivity
				if(rand() < $INFECTIVITY) 
				{
					if($population_copy{$r}{'infState'} == 0)
					{
						if($population_copy{$r}{'vacState'} == 0)
						{
							$population_copy{$r}{'infState'} = 1;
						}
					}	
				}	
			}			
		
		}
	}

	# Vaccinate individuals
	foreach my $person (keys %population)
	{
		if($population{$person}{'infState'} == 0)
		{
			if($population{$person}{'vacState'} == 0)
			{
				for my $i (0 .. $VAC-1)
				{
					my $r = $person;
					while($r == $person)
					{
						$r = int(rand($NUM_IND));
					}
					if(rand() < $EF)
					{
						if($population_copy{$r}{'vacState'} == 0)
						{
						$population_copy{$r}{'vacState'} = 1;
						}
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
	print "SUS: ".$sus."\tEXP: ".$exp."\tINF: ".$inf."\tREM: ".$rec."\n";

	#print Dumper(\%population);
	#print "\n-------------\n";
	#print Dumper(\%population_copy);
	#print "\n-------------\n";

}
