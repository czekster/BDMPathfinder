# BDMPathfinder
A tool for analysing attack paths in BDMP (Boolean logic Driven Markov Processes) models.

## Toolchain
BDMPathfinder runs (and was extensively tested) on MS-Windows.

- To build a BDMP model: install Lloyd's Register [RiskSpectrum ModelBuilder (RSMB)](https://www.lr.org/en-gb/riskspectrum/technical-information/modelbuilder/) -- tested with version 2.0.0.11 (March/2021) -- this tool runs on MS-Windows only;
- [Perl](https://www.perl.org/get.html) (tested in version 5.28);
- [Yet Another Monte Carlo Simulator (YAMS)](https://sourceforge.net/projects/visualfigaro/files/YAMS/) version 2.0.3.1 (for MS-Windows).
- [RStudio](https://www.rstudio.com/products/rstudio/download/) version 1.4.1106 (multi-platform tool).

You may use [Visual Figaro](https://sourceforge.net/projects/visualfigaro/) to open and work with FIGARO files using jEdit.

## Details and execution
In RSMB, after creating and testing (basic simulation within the tool) the BDMP model, analysts must instantiate the FIGARO file that is the INPUT of BDMPathfinder.
To do this, go to the "Processing" tab, then "Instantiate Figaro 0", then "Generate Figaro 0".
**Choose the same folder as BDMPathfinder script is located**.
Then, to execute the script, open a ``command.exe`` and:
1. Test whether Perl is working: ``perl -v``
2. Call ``perl bdmpathfinder.pl case-study1.fi
- It will create an R script called ``case-study1.R``
3. Open RStudio, then open the .R script (hit ``Ctrl-A`` then hit ``Alt+Enter`` to execute all the script).
- It will generate a plot with all the path probabilities or the TOP N if the property `TOP-PATHS` is different than 0.

## Process overview
The tool executes a Perl script and calls YAMS as a Command Line Interface (CLI).
YAMS generates an XML file that is processed by the tool to compute the attack path probabilities.
BDMPathfinder then creates an RStudio script with all paths over the mission duration (see property `DURATION` below).

## Properties
Set up a few properties directly in the script:
```# Properties for the script, this is self-explanatory
my %properties = (
   "WORKING-PATH"    => "C:\\\\Users\\\\stout\\\\Desktop\\\\BDMPathfinder", # **CHANGE HERE** - USE MS-Windows PATH style
   "OUTPUT-FILE"     => "output.txt",  # output file name
   "DURATION"        => 96,            # scale is 'hours'
   "PROB-THRESHOLD"  => 0.8,           # probability threshold
   "PLOT-X-TICS"     => 1,             # xtics parameter in the plot
   "PLOT-Y-TICS"     => 0.02,          # ytics
   "TOP-PATHS"       => 0,             # discover top N paths ** if TOP-PATHS > 0, then only the TOP N paths are considered, otherwise, all are considered **
);
```

## Case studies and examples
TBD.

## Corresponding author
Ricardo M. Czekster -- rczekster at gmail com


