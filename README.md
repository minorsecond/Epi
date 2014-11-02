Epi
===
SEIR model for various diseases. Paramaters are set by user input to allow quick adjustment of disease characteristics. This program writes results to a CSV file for further analysis. 
The script also creates file entitled parameters.log which contains the parameters you have chosen.

You must have the Text::CSV module installed for this code to run. In terminal, run the following to install:

$cpan -i Text::CSV

The progrma includes an option to reintroduce a percentage of the recovered population back into the susceptible compartment, based on the disease mortality rate. This model decides outcome based on probability and random number generators, using a gaussian distribution.
