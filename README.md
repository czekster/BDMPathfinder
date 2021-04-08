# BDMPathfinder
A tool for analysing attack paths in BDMP (Boolean logic Driven Markov Processes) models.

## Toolchain
BDMPathfinder runs (and was extensively tested) on MS-Windows.

- To build a BDMP model: install Lloyd's Register [RiskSpectrum ModelBuilder (RSMB)](https://www.lr.org/en-gb/riskspectrum/technical-information/modelbuilder/) -- tested with version 2.0.0.11 (March/2021) -- this tool runs on MS-Windows only;
  - it is worth mentioning that this tool is **proprietary**;
- [Perl](https://www.perl.org/get.html) (tested in version 5.28);
- [Yet Another Monte Carlo Simulator (YAMS)](https://sourceforge.net/projects/visualfigaro/files/YAMS/) version 2.0.3.1 (for MS-Windows).
  - YAMS is **free**, but _not open source_
- [RStudio](https://www.rstudio.com/products/rstudio/download/) version 1.4.1106 (multi-platform tool).

You may use [Visual Figaro](https://sourceforge.net/projects/visualfigaro/) to open and work with FIGARO files using jEdit.

## Features
- Multiple scenario analysis of BDMP models;
- Advanced plotting using the R environment;
- Top Path analysis, where modellers select only the ones having highest probabilities;
- Iteration over multiple mission times set by the modeller (ie analysis over time as paths increase their likelihood);
- Customisation of plotting axis (X,Y);

## Basic instructions
1. Create a BDMP model in RiskSpectrum ModelBuilder (RSMB)
   - open the properties and set option: ``GLOBAL_TYPE>OPTIONS>enable_detection`` to ``FALSE`` (this option is used when modelling only the attacks on BDMP instead of the Attack-Defense capabilities and extra parameters required in these kinds of analysis)
2. For each leaf, assign a number that is unique to your analysis (e.g. 123.456)
   - the idea is that the script will substitute this string by a set of parameters
   - assign 'unique' values in the BDMP model in RSMB
   - for ISE leaves you will have to add values between 0 and 1, so I suggest adding 0.011010101, for instance
       - then generating the FIGARO0 file and replacing this string by something else more close to your original selected pattern (e.g. "123.456")
3. Convert the BDMP model to a FIGARO file: Open model, on tab 'Processing', click "Generate Figaro0"
   - change the directory to save the model to the same path as BDMPathfinder is located, click "save", click "instantiate"
4. Edit a properties file (we shipped one called ``bdmp-properties.txt``) -- see "Properties" below
   - change parameters and paths as you see fit
5. Edit the hash variable ``%parameters`` in the Perl script ``bdmp-scenario-builder.pl``
   - change the string you set in RSMB with all the variations you wish to run (e.g. '123.456' => "1;3;10;15" in hours, it will divide by 3600)
6. Run ``perl bdmp-scenario-builder.pl <MODEL>``
   - the model must be a FIGARO model (extension .fi)
   - this will create a folder (with the timestamp), copy this folder and paste on the next step
   - this script will also create a file called ``scenarios.txt`` with all scenarios it has created
7. Run ``perl bdmp-run-all.pl <FOLDER> <PROPERTY-FILE>``
   - in the end, it will create a file called ``script.R``, for plotting ALL scenarios
8. Open RStudio, and then go to <FOLDER> and open the ``script.R``, executing all commands

## Process overview
The tool executes a Perl script and calls YAMS as a Command Line Interface (CLI).
YAMS generates an XML file that is processed by the tool to compute the attack path probabilities.
BDMPathfinder then creates an RStudio script with all paths over the mission duration (see property `DURATION` below).

## Properties
Set up a few properties in a properties file (you can choose the name and use it as parameter for 'bdmp-scenario-builder.pl' (use '#' to commenting lines).
The file below 'looks odd' just to show modellers the use of properties, and how lenient the parser will behave to extract actual (useful) parameters from this file.
```# use this for commenting lines
WORKING-PATH    = C://temp//BDMPathfinder # **CHANGE HERE** - USE MS-Windows PATH style
#duration of the simulation (mission time)
DURATION        = 24            # scale is 'hours'
       
PROB-THRESHOLD  = 0.7           # probability threshold
  # options for new plots
PLOT-X-TICS     = 1             # xtics parameter in the plot
PLOT-Y-TICS     = 0.01          # ytics
TOP-PATHS       = 0             # discover top N paths ** if TOP-PATHS > 0, then only the TOP N paths are considered, otherwise, all are considered **
VERBOSE         = 0             # shows output as they are computed
```

## Case studies and examples
[Click here for case studies and examples](case-studies.md)

## Corresponding author
Ricardo M. Czekster -- rczekster at gmail com


