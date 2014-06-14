#!/usr/bin/env perl 
use strict;
use warnings;
use feature 'say';

my $statFile="/data/tmp/statUniq.txt";

open (FILE,$statFile) or 
	die "Failed to open file: $statFile";
	my $sum=undef;
	my @file=<FILE>;
	
foreach (@file){
	chomp $_;
	# $_=sqrt ($_ * $_);
	$sum+=$_;
}

say "===============================";
say "Сумата е: $sum";
my $middle=($sum / ($#file + 1));
say "Средно аритметично: " . $middle;
$sum=0;

foreach (@file){
	my $temp=$_ - $middle;
	$sum +=$temp * $temp;
}

say "Междинна сума: всяка стойност минус средната: " . $sum;
say "Стандартното отклонение е: " . $sum / ($#file + 1);
close (FILE);
