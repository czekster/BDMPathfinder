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
## Start: 11/03/2021
## Modified: 25/03/2021

# BASIC INSTRUCTIONS - all instructions are in 'bdmp-run-all.pl'
#1. Run perl script: perl bdmpathfinder.pl <FIGARO-FILE>

#If you wish (you don't have/need to) run YAMS using the command line: #yams.exe parameters.mcp -o model1.mcr
#  (this executable should be at the same folder as the Perl script for BDMPathfinder)

use strict;
use warnings;

use Time::Local;
use Cwd qw();

use 5.010;
use XML::LibXML;
use List::Util qw(max);

require './bdmp-routines.pl';

if (@ARGV != 2) { 
   print "missing FIGARO-FILE parameter. \nusage: perl bdmpathfinder.pl FIGARO-FILE PROPERTIES-FILE\n";
   exit;
}

# warning only print information whereas error will exit
my %messages = (
   "FILE-NOT-FOUND"           => "Error 01. File not found.",
   "PROPERTY-FILE-NOT-FOUND"  => "Error 02. Property file not found.",
   "UE_NAME-NOT-FOUND"        => "Error 03. Undesired event name not found.",
);

# save all properties into one array variable
my $file = $ARGV[0];
open(INFILE, "<$file") or die ($messages{"FILE-NOT-FOUND"}." File: $file\n");
my(@lines) = <INFILE>;
close(INFILE);

# script start, global parameters
my $rootfile = $file;
$rootfile =~ s/.fi//g;
my $OUTPUT_FILE = "$rootfile.txt";

my %properties = read_properties($ARGV[1]);

#discover the undesired event name from the figaro file (input)
my $ue_name = "";
foreach my $line (@lines) {
   if ($line =~ /OBJECT (\w*) IS_A undes_event;/) {
      $ue_name = $1;
      last;
   }
}

# undesired event was not found, exiting
if ($ue_name eq "") {
   print $messages{"UE_NAME-NOT-FOUND"}."\nExiting.\n";
   exit;
}

my $max_prob = 0.0; #saves the maximum probability (for setting up the Y axis properly)
my %hashres = ();

for (my $i = 1*3600; $i <= $properties{'DURATION'}*3600; $i=$i+3600) {
   my $progression = sprintf("%2.2f",((($i/3600)/($properties{'DURATION'}))*100));
   print "Running for time = $i seconds... (".$progression."%)\n";
   my $resfile = $rootfile.".mcr";
   my $figarofile = $rootfile.".fi";

   #create a new 'parameters' file for YAMS
   my $paramYAMScontents = "".
      "<?xml version= \"1.0\" encoding=\"UTF-8\" ?>\n".
      "<AMC_ENTREES xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mc_param.xsd\" COPYRIGHT=\"Yams Copyright© EDF 2003-2013. All rights reserved.\" VERSION=\"2.0.3.1\">\n".
      "	<FIGARO0>#\\".$figarofile."</FIGARO0>\n".
      "	<PARAMETRES MAX_NB_TOURS_REGLES=\"200\" MAX_NB_TOURS_TPS_FIXE=\"10\" MAX_NB_HISTOIRES=\"100000\" MEM_ETATS=\"10000\" OPTIM_INTERACTIONS=\"VRAI\" GRAINE=\"0\" RNG=\"yarn5\" FREQ_TRANS=\"VRAI\" PROBA_SEQ=\"100\"/>\n".
      "	<HISTOIRE>\n".
      "		<INTERVALLE T0=\"0\" T1=\"".($i)."\" N=\"10\"/>\n".
      "	</HISTOIRE>\n".
      "	<GROUPES>\n".
      "		<GROUPE NOM=\"WITHOUT_NAME\"/>\n".
      "		<GROUPE NOM=\"ALL\"/>\n".
      "		<GROUPE NOM=\"simu_group\"/>\n".
      "	</GROUPES>\n".
      "	<ETATS>\n".
      "		<ETAT NOM=\"TopEvent\" TYPE=\"CIBLE\" EXPRESSION=\"S($ue_name)\" CONTRAINTE=\"TANGIBLE, ABSORBANT\"/>\n".
      "	</ETATS>\n".
      "	<INDICATEURS>\n".
      "		<INDICATEUR NOM=\"Unrealiability\" EXPRESSION=\"TopEvent\" FONCTION=\"MOYENNE;INT_CONF_90;INT_CONFIANCE\" TYPE=\"LOCAL\"/>\n".
      "	</INDICATEURS>\n".
      "</AMC_ENTREES>\n";
   my $paramYAMSfile = "parameters.mcp";
   open(YAMSFILE,'>', $paramYAMSfile) or die $!;
   print YAMSFILE $paramYAMScontents;
   close(YAMSFILE);

   #run YAMS for this new experiment file
   print "running YAMS...\n";
   system("del $resfile >nul 2>&1");  #remove previous result file (if exists)
   print "Executing 'yams.exe parameters.mcp -o $resfile'...\n" if ($properties{'VERBOSE'});
   system("yams.exe parameters.mcp -o $resfile"); #run yams sending output to $resfile

   #process results file (should be the same name as the model, plus termination mcr
   my $dom = XML::LibXML->load_xml(location => $resfile);
   my $parser = XML::LibXML->new();
   my $tree = $parser->parse_file($resfile);
   my $root = $tree->getDocumentElement;

   my $acum_prob = 0.0;
   my $count = 0;
   my $contribution;
   #find the most likely attack path probabilities (according to $properties{'PROB-THRESHOLD'} variable)
   print "identifier;probability;contribution;path\n" if ($properties{'VERBOSE'}); # print header

   #find last acum prob :( just to compute an accurate 'contribution'
   foreach my $camelid ($root->findnodes('//AMC_SORTIES/PROBABILITES_SEQUENCES/SEQUENCE')) {
      my $prob =  $camelid->findvalue('@PROBABILITE');
      $acum_prob += $prob;
      if ($acum_prob > $properties{'PROB-THRESHOLD'}) { last; }
   }
   my $lastprob = $acum_prob;
   $acum_prob = 0.0;

   #now print it
   foreach my $camelid ($root->findnodes('//AMC_SORTIES/PROBABILITES_SEQUENCES/SEQUENCE')) {
      $count++;
      my $prob =  $camelid->findvalue('@PROBABILITE');
      $contribution = $prob/$lastprob;
      $acum_prob += $prob;
      print "$count;$prob;$contribution;" if ($properties{'VERBOSE'});
      my $acumobjet = "";
      foreach my $trans ($camelid->findnodes('./BRANCHE/TRANSITION')) {
         my $objet =  $trans->findvalue('@OBJET');
         my $realization = $trans->findvalue('@TRANS');
         $realization = ($realization eq "no_realization" ? "off" : "on");
         print "".$objet.";" if ($properties{'VERBOSE'});
         $acumobjet .= $objet."[".$realization."]"."-";
      }
      $hashres{$acumobjet} .= ($i/3600)."#".$prob.";";
      $max_prob = ($prob > $max_prob ? $prob : $max_prob);
      print "\n" if ($properties{'VERBOSE'});
      if ($acum_prob > $properties{'PROB-THRESHOLD'}) { last; } # exits if reaches the accumulated probability threshold
   }
   print "Prob sum: ".$acum_prob."\n" if ($properties{'VERBOSE'});
} # end for - over time

#fix times in hashres -> add 0.0 where it skipped the time
#the previous code only saved the probabilities (storing the time between '#' symbols)
#the next part takes each path and add 'zeroes' whenever one is not provided, so, in the end, there will be a matrix PATHS x TIME (in hours)
foreach my $key (keys %hashres) {
   my $aux = $hashres{$key};
   my(@timeaux) = split(";",$aux);
   #if (@timeaux == $properties{'DURATION'}) { next; } #skip if all times are present
   my(@timearray);
   for (my $tempi=0;$tempi<$properties{'DURATION'};$tempi++) { $timearray[$tempi] = 0.0; }
   for (my $ii=0;$ii<@timeaux;$ii++) {
      my($tindex, $tprob) = split("#",$timeaux[$ii]); #example: #1#0.00249 and then 2#0.00112
      $timearray[$tindex-1] = $tprob;
   }
   $hashres{$key} = "";
   foreach my $val (@timearray) {
      $hashres{$key} .= $val.";"; #substitute the key for the new key with the zeroed values for the missing times
   }
}
#print $hashres
#foreach my $key (keys %hashres) {
#   print "$key --> $hashres{$key}\n";
#}

#Finding most likely TOP paths
if ($properties{'TOP-PATHS'} > 0) {
   print "\nComputing TOP paths...\n";
   my %tophashres;
   foreach my $key (keys %hashres) {
      my $aux = $hashres{$key};
      my(@timeaux) = split(";",$aux);
      my $pacum = 0.0;
      for (my $ii=1;$ii<@timeaux;$ii++) {
         $pacum += $timeaux[$ii];
      }
      $tophashres{$key} = $pacum
   }
   #order hash by value
   my @keys = sort { $tophashres{$b} cmp $tophashres{$a} } keys %tophashres;
   my $ccount = 1;
   my %toppaths;
   foreach my $key (@keys) {
      print "$key => $tophashres{$key}\n";
      $toppaths{$key} = $hashres{$key};
      last if ($ccount++ >= $properties{'TOP-PATHS'});
   }
   print "\n";
   %hashres = %toppaths; # overwrite hashres with toppaths
}

#outputs some observations and files it has written
print "\nProbs over time written in file '$OUTPUT_FILE'\n";
my $hashlen = keys %hashres;
print "Total paths: $hashlen\n";

#output probabilities into a file
open(OUTPFILE,'>', $OUTPUT_FILE) or die $!;
foreach my $key (keys %hashres) {
   my $aux = $hashres{$key};
   $aux = substr($aux, 0, length($aux)-1); #remove extra ';' in the end
   print OUTPFILE "$key;$aux\n";
}
close(OUTPFILE);

$max_prob += "0.01"; #give the axis some more room for the plot
my $tot_colours = $hashlen+1; #this option will be used for the plotting in RStudio

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
   "#set working directory\n".
   "setwd(\"$properties{'WORKING-PATH'}\")\n".
   "outputfile = \"$OUTPUT_FILE\"\n".
   "data <- read.table(outputfile, header=FALSE, sep=\";\")\n".
   "maxf = max(count.fields(outputfile, sep = ';'))\n".
   "data <- read.table(outputfile, header = FALSE, sep = \";\",  \n".
   "           col.names = paste0(\"V\",seq_len(maxf)), fill = TRUE)\n".
   "#save first column with the path names\n".
   "pathnames <- data[,1]\n".
   "#remove first column\n".
   "data\$V1 <- NULL\n".
   "#transpose the data, because each column corresponds to a probab. over time\n".
   "t_data <- transpose(data)\n".
   "\n".
   "#xaxs and yaxs: make the plot start at the right origin in x and y\n".
   "#col: choose colors, if col=1 then set ONE color (black), otherwise, a set of colours (e.g. col=2:10)\n".
   "graphics.off()\n".
   "matplot(t_data, type = c(\"l\"),main=\"Ensemble of attack paths\",cex.main=1.5,\n".
   "        pch=1,col = 2:$tot_colours,xlim=c(1,$properties{'DURATION'}), xaxs=\"i\", yaxs=\"i\",\n".
   "        ylim=c(0,$max_prob),ylab=\"Path probability\",xlab=\"Time (in hours)\",axes=F)\n".
   "box()\n".
   "axis(1, seq(0,$properties{'DURATION'},$properties{'PLOT-X-TICS'}),las=1, cex.axis=0.75, font=1)\n".
   "axis(2, seq(0,$max_prob,$properties{'PLOT-Y-TICS'}),cex.axis=0.85, las=2)\n".
   "par(xpd=TRUE)\n";
if ($properties{'TOP-PATHS'} > 0) {
   $R_file_contents .= "legend(2, $max_prob, pathnames, col=2:$tot_colours, lty=1:2,pch = 1, bty = \"n\")\n";
}
$R_file_contents .= "\n";

my $R_file_name = $OUTPUT_FILE;
$R_file_name =~ s/.txt//g;
$R_file_name .= ".R";
open(RFILE,'>', $R_file_name) or die $!;
print RFILE $R_file_contents;
close(RFILE);

print "\nR commands (for plotting) written in file '$R_file_name'\n";


