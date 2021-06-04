#!/usr/bin/perl

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
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
## Modified: 06/04/2021

# BASIC INSTRUCTIONS - all instructions are in 'bdmp-run-all.pl'
#1. Run perl script: perl bdmp-scenario-builder.pl <FIGARO-FILE>

#If you wish (you don't have/need to) run YAMS using the command line: #yams.exe parameters.mcp -o model1.mcr
#  (this executable should be at the same folder as the Perl script for BDMPathfinder)

use strict;
use warnings;

use Time::Local;
use Cwd qw();

use 5.010;
use XML::LibXML;
use List::Util qw(max);

if (@ARGV != 1) { 
   print "missing FIGARO-FILE parameter. \nusage: perl bdmp-scenario-builder.pl FIGARO-FILE\n";
   exit;
}

# warning only print information whereas error will exit
my %messages = (
   "FILE-NOT-FOUND"     => "Error 01. File not found.",
);

# save all properties into one array variable
my $file = $ARGV[0];
my $rootfile = $file;
$rootfile =~ s/.fi//g;
my $fullpath = $rootfile;
$rootfile = substr($rootfile, rindex($rootfile,"/")+1, length($rootfile)-rindex($rootfile,"/")-1);

my $SECONDS = 3600;  # total of seconds in one hour (main scale)

my %parameters = (   # model in HOURS, e.g., for '123.458' there is two possibilities: 3 hours and 12 hours, and so on
   #"777"     => "1;3",   # this one is shipped commented
   "123.456"     => "1",
   "123.457"     => "2",
   "123.458"     => "3;12",
   "123.459"     => "5;10",
   #"123.460"     => "0.2;0.5",   # also commented, just to show that it is possible to avoid some scenarios altogether
   "123.461"     => "1",
   "123.462"     => "3",
   "123.463"     => "4;16",
   #"123.481"     => "1",
   "123.464"     => "0.1;0.9",   # this one is the between 0 and 1 - GAMMA property
);

#current localtime
(my $sec,my $min,my $hour,my $mday,my $mon,my $year,my $wday,my $yday,my $isdst)=localtime(time);
my $date = sprintf("%02d-%02d-%4d_%02d-%02d-%02d",$mday,$mon+1,$year+1900,$hour,$min,$sec);

#create directory with the current date-time
my $dirname = $fullpath."".$date;
print "mkdir \"$dirname\"\n";
system("mkdir \"$dirname\"");

# start of permutation algorithm for creating all the possible scenarios from the parameters (above)
my $tam = keys %parameters;

my @scenarios;
my $cont = 0;
my @keys;
foreach my $key (keys %parameters) {
   my @arr = split(";", $parameters{$key});
   $scenarios[$cont] = @arr; #gets the size of the variations
   $keys[$cont] = $key;
   $cont++;
}

#incredible permutation algorithm! See Knuth.
my @pgs;
#initialisation
for (my $i=0;$i<$tam;$i++) { $pgs[$i] = 0; }
my @vv;
$vv[0] = $scenarios[0];
for (my $i=1;$i<$tam;$i++) { $vv[$i] = $scenarios[$i] - 1; }
#algorithm 'per se'
$pgs[$tam-1] = -1;
my $a = $tam - 1;
my $nz;
$cont = 0;
my @idx_scenarios = ();
while ($pgs[0] != $vv[0]) {
   if ($pgs[$a] < $vv[$a]) {
       $pgs[$a] = $pgs[$a] + 1;
       $a = $tam - 1;
       if ($pgs[0] != $vv[0]) {
           my $str = "";
           for (my $i = 0; $i < $tam; $i++) {
               $str .= "$pgs[$i]";
               $str .= $i==$tam-1?"":";";
           }
           #print "".($cont++).": $str\n";
           push @idx_scenarios, $str;
       }
   } else {
       $a--;
       #restart from a+1 till the end with zeroes
       for (my $i = $a + 1; $i < $tam; $i++) {
           $nz = ($pgs[$i] != -1) ? 0 : -1;
           $pgs[$i] = $nz;
       }
   }
}
$cont = 0;
#print
for (my $i=0; $i < @idx_scenarios; $i++) { 
   $cont++;
   my @aux = split(";", $idx_scenarios[$i]);
   #print "aux=$idx_scenarios[$i]\n";
   #print "new model: [$cont] ";
   for (my $j=0; $j < @aux; $j++) {
      my @elem = split(";",$parameters{$keys[$j]});
      #print "\tkey=$keys[$j] j=$j aux[j]=$aux[$j] elem=$elem[$aux[$j]]\n";
      #print "key:$keys[$j]=$elem[$aux[$j]],";
      my $sscont = sprintf("%02d",$cont);
      my $newfile = $rootfile."$sscont.fi";
      if ($j == 0) {
         print "New file created: '$dirname/$newfile'\n";
         open(INFILE, "<$file") or die ($messages{"FILE-NOT-FOUND"}." File: $file\n");
      } else {
         #print "File updated: '$newfile'\n";
         open(INFILE, "<$dirname/$newfile") or die ($messages{"FILE-NOT-FOUND"}." File: $dirname/$newfile\n");
      }
      my(@lines) = <INFILE>;
      close(INFILE);
      # now that the lines are saved, create a new file each time with the old contents
      #print "New file created: '$dirname/$newfile'\n";
      #print "dir name: '$dirname'\n";
      #print "newfile : '$newfile'\n";
      open(OUTFILE, ">$dirname/$newfile") or die ("Some error just happened. File: $dirname/$newfile\n");
      foreach my $line (@lines) {
         if ($line =~ /$keys[$j]/) {
            my $vval = $elem[$aux[$j]]/$SECONDS; # it's a rate, and the parameters are times, so f=1/t
            $line =~ s/$keys[$j]/$vval/g;
            #last;
         }
         print OUTFILE "$line";
      }
      close(OUTFILE);
   }
   #print "\n";
}

#discover BDMP elements' names
my %elemnames = ();
open(INFILE, "<$file") or die ($messages{"FILE-NOT-FOUND"}." File: $file\n");
my(@lines) = <INFILE>;
close(INFILE);
for (my $i=0; $i < @idx_scenarios; $i++) { 
   $cont++;
   my @aux = split(";", $idx_scenarios[$i]);
   for (my $j=0; $j < @aux; $j++) {
      my @elem = split(";",$parameters{$keys[$j]});
      my $elem;
      foreach my $line (@lines) {
         if ($line =~ /OBJECT (.*) IS_A (aa_leaf|tse_leaf|ise_leaf);/) {
            $elem = "[$2] $1";
         }
         if ($line =~ /$keys[$j]/) {
            $elemnames{$keys[$j]} = $elem;
         }
      }
   }
}

#create a file describing the scenarios
$cont = 0;
my $ssacum;
my $error = 0;
my %errormsg = ();
open(OUTFILE, ">$dirname/scenarios.txt") or die ("Some error just happened. File: $dirname/scenarios.txt\n");
for (my $i=0; $i < @idx_scenarios; $i++) { 
   $cont++;
   $ssacum = "";
   my @aux = split(";", $idx_scenarios[$i]);
   for (my $j=0; $j < @aux; $j++) {
      my @elem = split(";",$parameters{$keys[$j]});
      my $sscont = sprintf("%02d",$cont);
      my $newfile = $rootfile."$sscont.fi";
      if ($j == 0) {
         $ssacum .= "[$sscont] File: $newfile\n";
      }
      if (not exists $elemnames{$keys[$j]}) {
         $errormsg{"Error: Parameter '$keys[$j]' was never used."} .= $error++;
         next;
      }
      $ssacum .= "\t$elemnames{$keys[$j]} = $elem[$aux[$j]]\n";
   }
   print OUTFILE "$ssacum";
}
#print error messages - e.g. parameter not used (it should be removed by the modeller)
foreach my $key (keys %errormsg) {
   print "$key\n";
}
close(OUTFILE);
print "\nFile describing the scenarios and parameters: 'scenarios.txt'\n";

