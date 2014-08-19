Epi
===
SEIR model for various diseases. Paramaters are set by user input to allow quick adjustment of disease characteristics. This program writes results to a CSV file for further analysis. You must have the Text::CSV module installed ($cpan -i Text::CSV) for this code to run. 

The progrma includes an option to reintroduce a percentage of the recovered population back into the susceptible compartment, based on the disease mortality rate. This model decides outcome based on probability and random number generators, using a gaussian distribution.
