# SIR based disease spread model in perl.
# Robert Ross Wardrup
# 20/08/2014

#!/usr/bin/perl

use lib "/home/rwardrup/perl5/lib/perl5";
use 5.14.2;
use strict;
use warnings;
use Data::Dumper;
use Storable qw(dclone);
use Text::CSV;
	use Math::Random qw(random_exponential
						random_set_seed_from_phrase
	);
STDOUT->autoflush;

my $in = 0;
my $recsus = 0;
my $RECOVERY_PERIOD;
my $RESISTANCE;
my $resstatus = 0;
my $person = ();
my %population = ();
my $sum = 1;
my $EF;
my $params = "parameters.log";
my $results = "seir.csv";
my $delete = 0;

sub prompt {
  my ($query) = @_; # take a prompt string as argument
  local $| = 1; # activate autoflush to immediately show the prompt
  print $query;
  chomp(my $answer = <STDIN>);
  return $answer;
}

sub prompt_yn {
  my ($query) = @_;
  my $answer = prompt("$query (Y/N): ");
  return lc($answer) eq 'y';  
}

if (-e $params) {
	if (prompt_yn("Previous results exist. Overwrite?")){
		unlink ($params);
		unlink ($results);
	}
	else{
		print "Halting. Save previous results and run again. \n";
		die;
	}
}

elsif (-e $results) {
	if (prompt_yn("Previous results exist. Overwrite?")){
		unlink ($params);
		unlink ($results);
		}
}

my $csv = Text::CSV->new({binary => 1, auto_diag => 1, eol => "\n"})
	or die "Cannot use CSV: " . Text::CSV->error_diag();
open my $fh, ">>", "seir.csv" or die "Failed to open file: $!";

my $filename = 'parameters.log';
open(my $txt, ">", $filename) or die "Could not open file '$filename' $!";
print $txt "SEIR Model Parameters\n";
print $txt "--------------------\n";

print "Enter phrase for random seed generator: ";
chomp(my $phrase = <STDIN>);
print $txt "Seed phrase: $phrase\n";
random_set_seed_from_phrase($phrase);

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

print "Enter mean disease infectious period: ";
chomp(my $INFECTIOUS_PERIOD = <STDIN>);
exit 0 if ($INFECTIOUS_PERIOD eq "");
print $txt "Infectious Period: $INFECTIOUS_PERIOD\n";

print "Enter disease virulence (0.x): ";
chomp(my $INFECTIVITY = <STDIN>);
exit 0 if ($INFECTIVITY eq "");
print $txt "Infectivity: $INFECTIVITY\n";

print "Enter disease mortality rate (0.x): ";
chomp(my $MORTALITY = <STDIN>);
exit 0 if ($MORTALITY eq "");
print $txt "Mortality rate: $MORTALITY\n";

print "Enter mean disease incubation period: ";
chomp(my $INCUB = <STDIN>);
exit 0 if ($INCUB eq "");
print $txt "Incubation period: $INCUB\n";

print "Enter duration of model: ";
chomp(my $DURATION = <STDIN>);
exit 0 if ($DURATION eq "");
print $txt "Max duration: $DURATION\n";

if (prompt_yn("Do individuals regain susceptibility after recovering from disease?")){
	$recsus = 1;
	print $txt "Gain susceptibility - Y \n";
	print "Enter recovery period: ";
	chomp($RECOVERY_PERIOD = <STDIN>);
	print $txt "Recovery period - $RECOVERY_PERIOD\n";

	if (prompt_yn("Do individuals develop resistance to re-infection?")){
		$resstatus = 1;
		print $txt "Gain resistance - Y";
		
	}
	if ($resstatus == 1){
	print "Enter probability or re-infection (developed resistance) (0.x): ";
	chomp($RESISTANCE = <>);
	print $txt "Resistance: $RESISTANCE\n";
	}
}
	
my $R0 = $CONTACT_RATE * $INFECTIVITY * $INFECTIOUS_PERIOD;
my $V0 = int((1 - 1 / $R0) * $NUM_IND);
print "\n***Basic Reproductive Rate (R0): $R0.***\n";
print "***Number to vaccinate to prevent sustained spread: $V0.***\n";
print $txt "R0: $R0\n";
print $txt "Vaccination needed: $V0\n";

close $txt;

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
	$population{$i}{'dayOfInf'} = 0;
	$population{$i}{'dayofExp'} = 0;
	$population{$i}{'dayofRec'} = 0;
	$population{$i}{'recState'} = 0;
	$population{$i}{'resistant'} = 0;
	$population{$i}{'incubationp'} = random_exponential($INCUB);
	$population{$i}{'infectiousp'} = random_exponential($INFECTIOUS_PERIOD);
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
}


print "Before initiation\n";
print "SUS: ".$sus."\tEXP: ".$exp."\tINF: ".$inf."\tREM: ".$rec."\tDEC: ".$dec."\n";
$csv->print($fh, [ "Day", "Susceptible", "Exposed", "Infected", "Removed", "Deceased"]);
close $fh;

for(my $day = 0; $day < $DURATION; $day++) {
	if($sum > 0){
		open my $fh, ">>", "seir.csv" or die "Failed to open file: $!";
		
		#Creating a temporary copy of population to make updates to infection state. This prevents errors.
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
								$population_copy{$r}{'infState'} = 1;
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

		%population = %{dclone(\%population_copy)};

		#Update stats for each person at the end of a day
		foreach my $person (keys %population){
			if($population{$person}{'infState'} == 1){
				$population{$person}{'dayOfExp'}++;
				if($population{$person}{'dayOfExp'} >= $population{$person}{'incubationp'}) 
				{
					$population{$person}{'infState'} = 2;
				}
			}
			
			if($population{$person}{'infState'} == 2){
				$population{$person}{'dayofInf'}++;
				if($population{$person}{'dayofInf'} >= $population{$person}{'infectiousp'}){
					$population{$person}{'infState'} = 3;
				}
			}
			
			if ($recsus == 1){
				if($population{$person}{'recState'} == 0){
					if(rand() > $MORTALITY){
						if($population{$person}{'infState'} == 3){
							$population{$person}{'recState'} = 1;
						}
				
				elsif($population{$person}{'infState'} == 3){
						$population{$person}{'infState'} = 4;
					}
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
		foreach my $person (keys %population){
			if($population{$person}{'infState'} == 0){
				$sus++;
			}
			if($population{$person}{'infState'} == 1){
				$exp++;
			}
			if($population{$person}{'infState'} == 2){
				$inf++;
			}
			if($population{$person}{'infState'} == 3){
				$rec++;
			}
			if($population{$person}{'infState'} == 4){
				$dec++;
			}
			
		}


		print "Day ".$day."\n";
		print "SUS: ".$sus."\tEXP: ".$exp."\tINF: ".$inf."\tREM: ".$rec."\tDEC: ".$dec."\n";
		$csv->print($fh, [ $day, $sus, $exp, $inf, $rec, $dec]);
		$sum = ($exp + $inf + $rec);
		}
		close $fh;
}
