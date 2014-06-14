#!/usr/bin/env perl

BEGIN{ push @INC,'/data/local/perl/modules';}
use strict;
use warnings;
use feature 'say';
use gphoto2::control;
use Data::Dumper;
use File::Path 'make_path';

my $picturesCounter=10000;
my $picturesPreffix="gerena-";
my $picturesSuffix="-test.CR2";
my $cameraModel="Canon EOS 40D";
my $outputDir="/data/tmp/timeLapse/test-hdr-new";
my $sleepTime=5;
my @bracketedFotos=('-3','-2.0','-1.0','1.0','2','3','0'); # NOTE: The normal picture is the last because we need it to calibrate the future camera adjustments.

say "Checking outpur Dir: $outputDir";
unless (-d $outputDir){
	make_path($outputDir);
	die "Failed to create dir: $outputDir" unless (-d $outputDir);
	say "$outputDir created !";
}
no File::Path;
say "Done !";

my $g=gphoto2::control->new;

my $devices=$g->getConnectedDevices;
die $g->getLastError unless ($devices);

my %devices=%$devices;
my $port=undef;

foreach (keys %$devices){
	# TODO: get this from web interface !
	if ($$devices{$_}=~m/$cameraModel/i){
		$g->setDevice("$$devices{$_}") or
			die $g->getLastError;
		$g->setOutputDir($outputDir) or
			die $g->getLastError;
			
		# TODO: Introduce getCurrentPicturePath, in order to get the measurements from the camera	
		my $picture=$g->getLastPicturePath();
		$g->setPicturePrefix($picturesPreffix);
		$g->setPictureSufix($picturesSuffix);
		#TODO: Implement setPicturesCounter as public method ! This is in case we resume the timelapse.
		
		foreach (1..$picturesCounter){
			say "Will take picture with number: " . $g->getPicturesCounter . "of $picturesCounter";
			#~ die $g->getLastError unless ($g->takeSingleShot());
			die $g->getLastError unless ($g->takeBracketedShots(@bracketedFotos));
			print Dumper $g;
			
			last if ($picturesCounter eq $_);
			sleep $sleepTime;
		}
	}
}

print Dumper $g;
exit 7;

__DATA__

my @hist_data = $image->Histogram;
my @hist_entries;
# Histogram returns data as a single list, but the list is actually groups of
# 5 elements. Turn it into a list of useful hashes.
while (@hist_data) {
    my ($r, $g, $b, $a, $count) = splice @hist_data, 0, 5;
    push @hist_entries, {
        r => $r,
        g => $g,
        b => $b,
        alpha => $a,
        count => $count,
    };
}
# Sort the colors in decreasing order
@hist_entries = sort { $b->{count} <=> $a->{count} } @hist_entries;
