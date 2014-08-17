#SIR based disease spread model in perl.
# Robert Ross Wardrup

#!/usr/bin/perl

use 5.14.2;
use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);
use Class::CSV;
STDOUT->autoflush;

print "Day ".$day."\n";
	print "SUS: ".$sus."\tEXP: ".$exp."\tINF: ".$inf."\tREM: ".$rec."\n";


my $in = 0;
my $csv = Class::CSV->new
	(
	fields	=> [qw/Day Sus Exp Inf Rem/]
	);
	
print "Enter number of individuals: ";
my $NUM_IND = <STDIN>;
exit 0 if ($NUM_IND eq "");

print "Enter initial number of infections: ";
my $INIT = <STDIN>;
exit 0 if ($INIT eq "");

print "Enter number contacts per individual: ";
my $CONTACT_RATE = <STDIN>;
exit 0 if ($CONTACT_RATE eq "");

print "Enter disease infectious period: ";
my $INFECTIOUS_PERIOD = <STDIN>;
exit 0 if ($INFECTIOUS_PERIOD eq "");

print "Enter disease virulence: ";
my $INFECTIVITY = <STDIN>;
exit 0 if ($INFECTIVITY eq "");

print "Enter disease incubation period: ";
my $INCUB = <STDIN>;
exit 0 if ($INCUB eq "");

print "Enter number of vaccinations per day: ";
my $VAC = <STDIN>;

print "Enter vaccine efficacy: ";
my $EF = <STDIN>;

print "Enter duration of model: ";
my $DURATION = <STDIN>;
exit 0 if ($DURATION eq "");

my %population = ();

#generate population by adding elements to population structure
for(my $i = 0; $i< $NUM_IND; $i++) 
{
	$population{$i}{'infState'} = 0;
	$population{$i}{'age'} = int(rand(80));
	$population{$i}{'dayOfInf'} = 0;
	$population{$i}{'dayofExp'} = 0;
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
			for(my $i = 0; $i<$CONTACT_RATE; $i++) 
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
				while($r == $person) 
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

	# Remove vaccinated individuals
	foreach my $person (keys %population)
	{
		if($population{$person}{'infState'} == 0)
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
					if($population_copy{$r}{'infState'} == 0)
					{
						$population_copy{$r}{'infState'} = 3;
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
	
	$csv->add_line(
	{
		Day	=>	$.day.,
		SUS	=>	$.sus.,
		EXP	=>	$.exp.,
		INF	=>	$.inf.,
		REM	=>	$.rec.,
	});
	$csv-vprint();

	#print Dumper(\%population);
	#print "\n-------------\n";
	#print Dumper(\%population_copy);
	#print "\n-------------\n";

}
