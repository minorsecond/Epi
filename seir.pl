# SIR based disease spread model in perl.
# Robert Ross Wardrup
# 20/08/2014

#!/usr/bin/perl

use 5.14.2;
use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);
use Text::CSV;
STDOUT->autoflush;

my $in = 0;
my $vac = 0;
my $recsus = 0;
my $RECOVERY_PERIOD;
my $RESISTANCE;
my $resstatus;
my $person = ();
my %population = ();
my $sum = 1;

my $csv = Text::CSV->new({binary => 1, auto_diag => 1, eol => "\n"})
	or die "Cannot use CSV: " . Text::CSV->error_diag();
open my $fh, ">>", "seir.csv" or die "Failed to open file: $!";

my $filename = 'parameters.txt';
open(my $txt, ">", $filename) or die "Could not open file '$filename' $!";
print $txt "SEIR Model Parameters\n";
print $txt "--------------------\n";

print "Enter random number seed: ";
chomp(my $seed = <>);
exit 0 if ($seed eq "");
srand($seed);
print $txt "Seed: $seed\n";

print "Enter number of individuals: ";
chomp(my $NUM_IND = <STDIN>);
exit 0 if ($NUM_IND eq "");
print $txt "Number of Individuals: $NUM_IND\n";

print "Enter initial number of infections: ";
chomp(my $INIT = <STDIN>);
exit 0 if ($INIT eq "");
print $txt "Initial number of infections: $INIT\n";

print "Enter number contacts per individual: ";
chomp(my $CONTACT_RATE = <STDIN>);
exit 0 if ($CONTACT_RATE eq "");
print $txt "Contact rate: $CONTACT_RATE\n";

print "Enter disease infectious period: ";
chomp(my $INFECTIOUS_PERIOD = <STDIN>);
exit 0 if ($INFECTIOUS_PERIOD eq "");
print $txt "Infectious Period: $INFECTIOUS_PERIOD\n";

print "Enter disease virulence: ";
chomp(my $INFECTIVITY = <STDIN>);
exit 0 if ($INFECTIVITY eq "");
print $txt "Infectivity: $INFECTIVITY\n";

print "Enter disease mortality rate: ";
chomp(my $MORTALITY = <STDIN>);
exit 0 if ($MORTALITY eq "");
print $txt "Mortality rate: $MORTALITY\n";

print "Enter disease incubation period: ";
chomp(my $INCUB = <STDIN>);
exit 0 if ($INCUB eq "");
print $txt "Incubation period: $INCUB\n";

#print "Enter number of vaccinations per day: ";
#chomp(my $VAC = <STDIN>);

#print "Enter vaccine efficacy: ";
#chomp(my $EF = <STDIN>);

print "Enter duration of model: ";
chomp(my $DURATION = <STDIN>);
exit 0 if ($DURATION eq "");
print $txt "Max duration: $DURATION\n";

print "Do recovered individuals become susceptible again? ";
$_ = <>;
$recsus = 1 if /^Y/i;
print $txt "Gain susceptiblity? $_";

if ($recsus == 1){
	print "Enter recovery period: ";
	chomp($RECOVERY_PERIOD = <STDIN>);
	print $txt "Recovery period: $RECOVERY_PERIOD";
	
	print "Do the individuals who are replaced into susceptible compartment develop resistance to re-infection? ";
	$_ = <>;
	$resstatus = 1 if /^Y/i;
	print $txt "Gain resistance? $_";
	
	if ($resstatus == 1){
		for(my $i = 0; $i< $NUM_IND; $i++){
			$population{$i}{'resistant'} = 0;
		}
		print "Enter probability or re-infection (developed resistance): ";
		chomp($RESISTANCE = <>);
		print $txt "Resistance: $RESISTANCE";
	}
}

my $R0 = $CONTACT_RATE * $INFECTIVITY * $INFECTIOUS_PERIOD;
my $V0 = (1 - 1 / $R0) * $NUM_IND;
print "\n***Basic Reproductive Rate (R0): $R0.***\n";
print "***Number to vaccinate to prevent sustained spread: $V0.***\n";
print $txt "R0: $R0\n";
print $txt "Vaccination needed: $V0\n";

close $txt;

#print "Use this number in vaccination calculation? (Y/n)\n";
#$_ = <>;
#$VAC = $V0 / $DURATION if /^Y/i;
#print "\n ";

{
	local( $| ) = ( 1 );
	print "\n\n\n\n";
	print "****************************************";
	print "\nThis may take quite a bit of time.\n";
	print "Save open files and, if possible,\n";
	print "take a break.\n\n";
	print "*****PRESS ANY KEY TO CONTINUE*****\n";
	print "****************************************\n\n\n\n";
	my $resp = <STDIN>;
}

for(my $i = 0; $i< $NUM_IND; $i++) {
	$population{$i}{'infState'} = 0;
#	$population{$i}{'age'} = int(rand(80)); #unused at the moment.
	$population{$i}{'dayOfInf'} = 0;
	$population{$i}{'dayofExp'} = 0;
	$population{$i}{'vacState'} = 0;
	$population{$i}{'dayofRec'} = 0;
	$population{$i}{'recState'} = 0;
}

# Generates initial infections fir $init number of people.
for my $i (0 .. $INIT-1){
	$in = int(rand($NUM_IND));
	$population{$in}{'infState'} = 2;
}

my $sus = 0;
my $exp = 0;
my $inf = 0;
my $rec = 0;
my $dec = 0;
foreach my $person (keys %population) {
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
	if($population{$person}{'infState'} == 4){
		$dec++;
	}
	if($population{$person}{'vacState'} == 1) {
		$vac++;
	}
}


print "Before initiation\n";
print "SUS: ".$sus."\tEXP: ".$exp."\tINF: ".$inf."\tREM: ".$rec."\tDEC: ".$dec."\tVAC: ".$vac."\n";
$csv->print($fh, [ "Day", "Susceptible", "Exposed", "Infected", "Removed", "Deceased"]);
close $fh;

for(my $day = 0; $day < $DURATION; $day++) {
	if($sum > 0){
		open my $fh, ">>", "seir.csv" or die "Failed to open file: $!";
		#Creating a temporary copy of population to make updates to infection state
		my %population_copy = %{dclone(\%population)};

		foreach my $person (keys %population) {
			if($population{$person}{'infState'} == 2) {
				for my $i (0 .. $CONTACT_RATE-1){
					my $r = $person;
					while($r == $person) {
						$r = int(rand($NUM_IND));
					}
					if(rand() < $INFECTIVITY) {
						if($population_copy{$r}{'resistant'} == 0){
							if($population_copy{$r}{'infState'} == 0){
								if($population_copy{$r}{'vacState'} == 0){
									$population_copy{$r}{'infState'} = 1;
								}
							}
						}
						elsif($population_copy{$r}{'resistant'} == 1){
							if(rand() < $RESISTANCE){
								if($population_copy{$r}{'infState'} == 0){
									$population_copy{$r}{'infState'} = 1;
								}
							}
						}	
					}	
				}			
			
			}
		}

	# Vaccinate individuals
	#	for my $i (0 .. $VAC - 1)
	#	{
	#	keys %population;
	#			if($population{$person}{'vacState'} == 0)
	#				{
	#					my $r = $person;
	#					while($r == $person)
	#						$r = int(rand($NUM_IND));
	#				}
	#						if(rand() < $EF)
	#						{
	#							if($population_copy{$person}{'vacState'} == 0)
	#							{
	#								$population_copy{$person}{'vacState'} = 1;
	#							}
	#						}
	#				}
	#			}

		%population = %{dclone(\%population_copy)};

		#Update stats for each person at the end of a day.
		foreach my $person (keys %population) {
			if($population{$person}{'infState'} == 1) {
				$population{$person}{'dayOfExp'}++;
				if($population{$person}{'dayOfExp'} >= $INCUB) 
				{
					$population{$person}{'infState'} = 2;
				}
			}
			
			if($population{$person}{'infState'} == 2){
				$population{$person}{'dayofInf'}++;
				if($population{$person}{'dayofInf'} >= $INFECTIOUS_PERIOD){
					$population{$person}{'infState'} = 3;
				}
			}
			
			if ($recsus == 1){
				if($population{$person}{'recState'} == 0){
					if(rand() > $MORTALITY){
						if($population{$person}{'infState'} == 3){
							$population{$person}{'recState'} = 1;
						}
					}
				
					elsif($population{$person}{'infState'} == 3){
						$population{$person}{'infState'} = 4;
					}
				}
				
				elsif($population{$person}{'recState'} == 1){
					$population{$person}{'dayofRec'}++;
					if($population{$person}{'dayofRec'} >= $RECOVERY_PERIOD){
						$population{$person}{'infState'} = 0;
					}
				}
			}
		}
		
		my $sus = 0;
		my $exp = 0;
		my $inf = 0;
		my $rec = 0;
		my $dec = 0;
		my $vac = 0;
		foreach my $person (keys %population) {
			if($population{$person}{'infState'} == 0) {
				$sus++;
			}
			if($population{$person}{'infState'} == 1) {
				$exp++;
			}
			if($population{$person}{'infState'} == 2){
				$inf++;
			}
			if($population{$person}{'infState'} == 3) {
				$rec++;
			}
			if($population{$person}{'infState'} == 4){
				$dec++;
			}
			if($population{$person}{'vacState'} == 1){
				$vac++;
			}
			
		}


		print "Day ".$day."\n";
		print "SUS: ".$sus."\tEXP: ".$exp."\tINF: ".$inf."\tREM: ".$rec."\tDEC: ".$dec."\tVAC: ".$vac."\n";
		$csv->print($fh, [ $day, $sus, $exp, $inf, $rec, $dec]);
		$sum = ($exp + $inf + $rec);
		}
		close $fh;
}

