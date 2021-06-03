#!/usr/bin/perl

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 3 as
# published by the Free Software Foundation;
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

## Perl script for processing a number of FIGARO template files
## Active Building Center Research Programme (ABC-RP) @ Newcastle University
## Start: 06/04/2021
## Modified: 07/04/2021

# BASIC INSTRUCTIONS
#1. Create a BDMP model in RiskSpectrum ModelBuilder (RSMB)
#   - open the properties and set option: GLOBAL_TYPE>OPTIONS>enable_detection to FALSE
#2. For each leaf, assign a number that is unique to your analysis (e.g. 123.456)
#   - the idea is that the script will substitute this string by a set of parameters
#   - assign 'unique' values in the BDMP model in RSMB
#   - for ISE leaves you will have to add values between 0 and 1, so I suggest adding 0.011010101, for instance
#       - then generating the FIGARO0 file and replacing this string by something else more close to your original selected pattern (e.g. "123.456")
#3. Convert the BDMP model to a FIGARO file: Open model, on tab 'Processing', click "Generate Figaro0"
#   - change the directory to save the model to inside the BDMPathfinder is, click "save", click "instantiate"
#4. Edit a properties file (we shipped one called 'bdmp-properties.txt')
#   - change parameters and paths as you see fit
#5. Edit the hash variable %parameters in the Perl script 'bdmp-scenario-builder.pl'
#   - change the string you set in RSMB with all the variations you wish to run (e.g. '123.456' => "1;3;10;15" in hours, it will divide by 3600)
#6. Run perl bdmp-scenario-builder.pl <MODEL>
#   - the model must be a FIGARO model (extension .fi)
#   - this will create a folder (with the timestamp), copy this folder and paste on the next step
#   - this script will also create a file called 'scenarios.txt' with all scenario variations according to the model's leaaves
#7. Run perl bdmp-run-all.pl <FOLDER> <PROPERTY-FILE>
#   - in the end, it will create a file called 'script.R', for plotting ALL scenarios
#8. Open RStudio, and then go to <FOLDER> and open the 'script.R', executing all commands


use strict;
use warnings;

use Time::Local;
use Cwd qw();

use 5.010;
use XML::LibXML;
use List::Util qw(max);

require './bdmp-routines.pl';

if (@ARGV != 2) { 
   print "missing FOLDER parameter. \nusage: perl bdmp-run-all.pl FOLDER PROPERTY-FILE\n";
   exit;
}

# save all properties into one array variable
my $folder = $ARGV[0];
my $propertyfile = $ARGV[1];
my $path = ".\\";

my %properties = read_properties($propertyfile);

#clean
system("del $path$folder\\*.txt >nul 2>&1");
system("del $path$folder\\*.R >nul 2>&1");
system("del $path$folder\\*.mcr >nul 2>&1");

#iterate through folders
print "directory read $folder\n";
my @files;
opendir FILE, $path.$folder or die("Folder not found.\n");
@files = grep !/^\.\.?$/,, readdir FILE;
closedir FILE;

my $max_prob = 0.0;
my $tot_colours;

#build new R file with MANY datasets

#create a new script for RStudio
my $R_file_contents = "".
   "#used for the transpose function\n".
   "library(data.table)\n".
   "\n".
   "#remove all objects defined earlier\n".
   "rm(list=ls(all=TRUE))\n".
   "#remove all plots in the environment\n".
   "graphics.off()\n".
   "\n".
   "#set working directory\n";

#iterate over the files and call bdmpathfinder.pl
my $count = 0;
my $ss_cbind = "";
foreach my $file (sort @files) {
   my $command = "perl bdmpathfinder.pl $path$folder/$file $propertyfile";
   print "\tRunning $path$folder/$file ...\n";
   system($command);
   my $outfile = $file;
   $outfile =~ s/.fi/.txt/g;
   $outfile = ".//$outfile";

   $count++;
   $ss_cbind .= "t_data$count,";

   $R_file_contents .= "".
      "setwd(\"$properties{'WORKING-PATH'}//$folder\")\n".
      "outputfile$count = \"$outfile\"\n".
      "data$count <- read.table(outputfile$count, header=FALSE, sep=\";\")\n".
      "maxf$count = max(count.fields(outputfile$count, sep = ';'))\n".
      "data$count <- read.table(outputfile$count, header = FALSE, sep = \";\",  \n".
      "           col.names = paste0(\"V\",seq_len(maxf$count)), fill = TRUE)\n".
      "#save first column with the path names\n".
      "pathnames$count <- data".($count)."[,1]\n".
      "#remove first column\n".
      "data$count\$V1 <- NULL\n".
      "#transpose the data, because each column corresponds to a probab. over time\n".
      "t_data$count <- transpose(data$count)\n".
      "\n";
}
$ss_cbind = substr($ss_cbind, 0, length($ss_cbind)-1); #remove extra ',' in the end

$tot_colours = $count;
$max_prob = 0.3; #todo: find the maximum probability of *all* scenarios

$R_file_contents .= "".
   "#xaxs and yaxs: make the plot start at the right origin in x and y\n".
   "#col: choose colors, if col=1 then set ONE color (black), otherwise, a set of colours (e.g. col=2:10)\n".
   "graphics.off()\n".
   "matplot(cbind($ss_cbind), type = c(\"l\"),main=\"Ensemble of attack paths\",cex.main=1.5,\n".
   "        pch=1,col = 2:$tot_colours,xlim=c(1,$properties{'DURATION'}), xaxs=\"i\", yaxs=\"i\",\n".
   "        ylim=c(0,$max_prob),ylab=\"Path probability\",xlab=\"Time (in hours)\",axes=F)\n".
   "box()\n".
   "axis(1, seq(0,$properties{'DURATION'},$properties{'PLOT-X-TICS'}),las=1, cex.axis=0.75, font=1)\n".
   "axis(2, seq(0,$max_prob,$properties{'PLOT-Y-TICS'}),cex.axis=0.85, las=2)\n".
   "par(xpd=TRUE)\n";
#if ($properties{'TOP-PATHS'} > 0) { #commented here, because of the multiple scenarios, it gets pretty messy to draw legends inside the plotting area...
#   $R_file_contents .= "legend(2, $max_prob, pathnames, col=2:$tot_colours, lty=1:2,pch = 1, bty = \"n\")\n";
#}
$R_file_contents .= "\n";

my $R_file_name = "script.R";
open(RFILE,'>', "$path$folder//".$R_file_name) or die $!;
print RFILE $R_file_contents;
close(RFILE);

print "\nR commands (for plotting) written in file $path$folder/'$R_file_name'\n";












