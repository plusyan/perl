#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
use Image::ExifTool;
use Data::Dumper;



my $filename=undef;
my $dirname="/home/iliyan/Desktop/stat/";
my @CR2=();

opendir (DIR,$dirname) or 
	die "Failed to open directory: $dirname. The error was: $!";
foreach $filename (readdir(DIR)){
	next unless ($filename=~m/\.CR2$/i);	
	push @CR2,"$dirname/$filename";
}
close DIR;
@CR2=sort(@CR2);
foreach $filename (@CR2){
	my $exifTool = new Image::ExifTool;
	$exifTool->Options(Unknown => 1);
	my $info = $exifTool->ImageInfo("$filename");
	my @tags = $exifTool->GetFoundTags('MeasuredEV');
	 #~ say foreach @tags;
	 
	 say "\n\n\n\n";
	 say "File: " . $filename;
	 say "########################################";
	 say 'MeasuredEV: ' . $exifTool->GetValue('MeasuredEV');
	 say 'MeasuredEV2: ' . $exifTool->GetValue('MeasuredEV2');
	 
	 my $shutterSpeed=$exifTool->GetValue('ShutterSpeed');
	 say 'ShutterSpeed: ' . $shutterSpeed  . ";
	 say 'Aperture: ' . $exifTool->GetValue('Aperture');
	 
	 #~ say 'ShutterSpeedValue2: ' . $exifTool->GetValue('ShutterSpeedValue2');
	 
	 
	 
	 say "#########################################";
	 my $t=$exifTool->GetValue('ShutterSpeed');
	 $t=eval($t);
	 my $f =$exifTool->GetValue('Aperture');
	 
	 my $calculatedEV=log(($f * $f) / $t )/log(2); 
	 say  "The exposure value is: " . $calculatedEV;

	my $measuredEV=$exifTool->GetValue('MeasuredEV');
	my $measuredEV2=$exifTool->GetValue('MeasuredEV2');
	say "EV difference is: " . ($measuredEV -  $calculatedEV);
	open (ADD,">>/data/tmp/stat.txt") or 
		die "Failed to open /data/stat.txt. The error was: $!";
		say ADD ($measuredEV -  $calculatedEV);
	close(ADD) or 
		die "Failed to close file /data/stat.txt. The error was: $!";
	
	my $fsq= $f * $f;
	say "speed = ". (2 ** $measuredEV) / $fsq;
	
}
