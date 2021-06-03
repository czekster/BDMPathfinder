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

## Perl sub-routines file
## Active Building Center Research Programme (ABC-RP) @ Newcastle University
## Start: 07/04/2021
## Modified: 07/04/2021

# removes spaces from beginning and end of strings
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

# substitutes extra spaces in the middle of strings for single spaces
sub strip { my $s = shift; $s =~ s/ +//g; return $s };

# read the properties (file is passed by the sub-routine as parameter)
sub read_properties {
   my $propertyfile = shift;
   
   my %pprop = ();

   open(INFILE, "<$propertyfile") or die ($messages{"PROPERTY-FILE-NOT-FOUND"}." File: $propertyfile\n");
   my(@proplines) = <INFILE>;
   close(INFILE);

   foreach my $line (@proplines) {
      $line =~ s/\r\n//g;
      $line = trim($line);
      $line = strip($line);
      $line = substr($line, 0, index($line, '#'));
      next if ($line eq "" || $line =~ /^'#'/); #next if line is empty of starts with '#'
      my($prop,$val) = split("=",$line);
      $pprop{$prop} = $val;
   }
   return %pprop;
}

#print a hash
#example of use: print_hash(\%properties); #don't forget the '\'
sub print_hash {
   my %hash = %{ $_[0] };
   foreach my $key (keys %hash) {
      print "$key -> $hash{$key}\n";
   }
}

1;
