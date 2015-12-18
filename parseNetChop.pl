#!/usr/bin/perl

use warnings;
use strict;
use IO::File;
use List::MoreUtils qw(indexes);
use List::Util qw(max);

my $inresults=0;
my $header = 0;
my @pos;
my @aa;
my @cleave;
my @score;
my @name;


my $inFh = IO::File->new( $ARGV[0] ) || die "can't open file\n";

print "sequence_name	max_cleavage_score	cleavage_pos\n";
while( my $line = $inFh->getline )
{
    chomp($line);
    if($line =~ /-----/){ #could be a divider or the line before the data, depending on context
        if(!$inresults){ 
            if($header==1){ #this is the line after the header, next line starts the results
                $header=0;
                $inresults=1;
            }
            next;
        } else { #this signals the end of the results
            $inresults=0;
            
            #print data we need
            my @sites = indexes { $_ ne "." } @cleave;
            print $name[0] . "\t";
            print max(@score) . "\t";
            print join(",",@pos[@sites]) . "\n";
            
            #empty arrays for next sequence
            @pos = ();
            @aa = ();
            @cleave = ();
            @score = ();
            @name = ();
            next;
        }
    } else { 
        if($inresults){
            my @F = split(/\s+/,$line);
            push(@pos, $F[1]);
            push(@aa, $F[2]);
            push(@cleave, $F[3]);
            push(@score, $F[4]);
            push(@name, join(" ",@F[5..$#F]));
        } else {
            if($line =~ /pos  AA/){
                $header=1;
                next;
            }
        }
    }
}
close($inFh);
