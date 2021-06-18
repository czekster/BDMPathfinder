# BDMPathfinder
A tool for analysing attack paths in BDMP (Boolean logic Driven Markov Processes) models.
Look also at the [Wiki page](https://github.com/czekster/BDMPathfinder/wiki) for latest news on the tool.

The tool has been **accepted** at the [17th EDCC](http://edcc.dependability.org/) (2021) for presentation (details on publication at IEEE will follow).
- Title: **_"BDMPathfinder: a tool for exploring attack paths in models defined by Boolean logic Driven Markov Processes"_**
   - Authors: Ricardo M. Czekster, Charles Morisset
   - Newcastle University - School of Computing

## Disclaimer
We stress the fact the BDMPathfinder tool is a **prototype** -- it has not being implemented with any kind of performance mindset.
It will run and process scripts in a reasonable amount of time, depending on parameters used.
You are free to take the ideas discussed herein and code it all in C or C++ or any other language you feel more comfortable with.
Just bear in mind that most of the toolchain required to actually execute BDMP models is based on MS-Windows platform.

## Toolchain
BDMPathfinder runs (and was extensively tested) on MS-Windows.

- To build a BDMP model: install Lloyd's Register [RiskSpectrum ModelBuilder (RSMB)](https://www.lr.org/en-gb/riskspectrum/technical-information/modelbuilder/) -- tested with version 2.0.0.11 (March/2021) -- this tool runs on MS-Windows only;
   - it is worth mentioning that this tool is **proprietary**;
   - **You will have to ask for an Evaluation License (or buy the tool), then download and install it**
- [Perl](https://www.perl.org/get.html) (tested in version 5.28);
   - **You will have to download and install it**
- [Yet Another Monte Carlo Simulator (YAMS)](https://sourceforge.net/projects/visualfigaro/files/YAMS/) version 2.0.3.1 (for MS-Windows).
   - YAMS is **free**, but _not open source_ (freely provided by *Electricité de France* - [EDF](https://www.edf.fr/en/meta-home))
      - Here is the [SourceForge link to download YAMS](https://sourceforge.net/projects/visualfigaro/files/YAMS/)
      - [Website to download VisualFigaro and example models](https://sourceforge.net/projects/visualfigaro/files/)
      - You may also look at [KB3 and tools at EDF's website](https://www.edf.fr/en/the-edf-group/inventing-the-future-of-energy/r-d-global-expertise/our-offers/simulation-softwares/kb3)
   - **This tool is shipped with BDMPathfinder**
- [RStudio](https://www.rstudio.com/products/rstudio/download/) version 1.4.1106 (multi-platform tool).
   - **You will have to download and install it**

You may use [Visual Figaro](https://sourceforge.net/projects/visualfigaro/) to open and work with FIGARO files using jEdit.

## Features
- Multiple scenario analysis of BDMP models;
- Advanced plotting using the R environment;
- Top Path analysis, where modellers select only the ones having highest probabilities;
- Iteration over multiple mission times set by the modeller (ie, analysis over time as paths increase their likelihood);
- Customisation of plotting axis (X,Y);

## Basic instructions
The following instructions are for the case where you are creating a new model in RSMB and would like to use BDMPathfinder to create a new analysis session.
Please, look at the Section "Running the case study" below to learn how to use a pre-generated Figaro0 file and running BDMPathfinder for generating graphs in R.

Here is the list of tasks:
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

Here is a list of steps performed by the tool for processing the Figaro0 file and generating the probability paths:
1. From a base model, the scenario builder scripts creates as many new models as required by the parameter variation (set in the variable ``%parameters`` in the Perl script ``bdmp-scenario-builder.pl``)
2. For each DURATION (from 1 to the value set in the property), and for each model, it calls YAMS for this duration
3. YAMS generates a list of paths and probabilities for this specific duration. The script saves all the paths, for this duration, and assigns its computed probability
4. This process iterates over all durations and all files, so, in the end, BDMPathfinder will have a data structure comprised of all generated paths by YAMS, and its probability
5. The final stage is to generate an R script for all paths, that shows the probability, as described by the figure presented here


## Properties
Set up a few properties in a properties file (you can choose the name and use it as parameter for ``bdmp-scenario-builder.pl`` (use '#' for commenting lines).
The file below 'looks odd' just to show modellers the use of properties, and how lenient the parser will behave to extract actual (useful) parameters from this file.
```# use this for commenting lines
WORKING-PATH    = C://temp//BDMPathfinder # **CHANGE HERE** - USE MS-Windows PATH style
#duration of the simulation (mission time)
DURATION        = 6            # scale is 'hours'
       
PROB-THRESHOLD  = 0.8           # probability threshold
  # options for new plots
PLOT-X-TICS     = 1             # xtics parameter in the plot
PLOT-Y-TICS     = 0.01          # ytics
TOP-PATHS       = 0             # discover top N paths ** if TOP-PATHS > 0, then only the TOP N paths are considered, otherwise, all are considered **
VERBOSE         = 0             # shows output as they are computed
```

## Example: casestudy2-markings
This case study runs the multiple scenario analysis (generating a folder with as many scenarios as set by the modeller).
[Click here to open casestudy2-markings results](https://github.com/czekster/BDMPathfinder/blob/main/casestudy2-markings_results.png)
It is called _'markings'_ because the modeller uses numerical values in the RSMB model that will be substituted by parameters.

## Running the case study - reproduce the results!
Before running this, install RStudio (latest version), and Perl.

Steps to run the case study (the tool was tested in MS-Windows 10 - RSMB is bound to this platform, however, our script will take the Figaro0 file and run on GNU/Linux without any problem):
1. Clone the repository at GitHub - [https://github.com/czekster/BDMPathfinder](https://github.com/czekster/BDMPathfinder)
2. Run the Command Line Interface (on MS-Windows, it is the `command.exe` tool)
3. Go to the folder where you clone the GitHub repository (mine is `C:\Users\stout\Desktop\BDMPathfinder-GitClone`)
4. Edit the properties file to adjust to your configuration and parameters (file is `bdmp-properties.txt`, but you could create any other from this one and then pass it as argument to `bdmp-run-all.pl` script)
   - Note: I used the property `DURATION=6` (eg, simulating six hours), for the actual figure, you should put `DURATION=96` here! *I stress that it will take several hours to complete.*
5. Run the Perl script that iterates over the scenarios
   - Command: `perl bdmp-scenario-builder.pl models_/casestudy2-markings.fi`
   - Observe that the script created a folder in `models_` folder with the current timestamp (`models_/casestudy2-markings03-06-2021_09-52-13`)
   - Inspect file `scenarios.txt` (inside that folder) for the list of scenarios the script has created, for each leaf
6. Run the Perl script that runs YAMS as many scenarios that are present in the new folder, for the parameters set in the properties file `bdmp-properties.txt`
   - Mind that it took approx. 25 min in an Intel(R) Core(TM) i7-7700HQ CPU @ 2.80GHz with 16Gb RAM for all 16 scenarios
   - Command: `perl bdmp-run-all.pl models_/casestudy2-markings03-06-2021_09-52-13 bdmp-properties.txt`
7. Run RStudio, open file `models_/casestudy2-markings03-06-2021_09-52-13/script.R`
   - Run the full script (eg, select all with CTRL-A, then hit ALT-RETURN)
   - It will generate the multi-scenario graph for six hour of simulation time (see note on step 4)

And that's it, now you can analyse the path probabilities for BDMP models over time, for multiple parameters for the attack leaves!
Check the [Wiki page](https://github.com/czekster/BDMPathfinder/wiki) for a graph showing the results for the multi-scenario simulation.

## Funding

Authors are funded by the Industrial Strategy Challenge Fund and EPSRC, [EP/V012053/1](https://gow.epsrc.ukri.org/NGBOViewGrant.aspx?GrantRef=EP/V012053/1), [Active Building Centre Research Programme (ABC RP)](https://abc-rp.com/).

## Acknowledgements

We thank Dr Marc Bouissou (EDF) for valuable discussions about BDMP modelling and toolchains.

## Corresponding author
Any problem that you may encounter, please drop me an e-mail!

Ricardo M. Czekster -- rczekster at gmail com


