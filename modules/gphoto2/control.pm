#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';
package gphoto2::control;
use Data::Dumper;

use POSIX 'strftime';
my $lastError=undef;
sub getLastError{return $lastError};

sub _setTimeStamp{
	my $self=shift;
	$$self{timeStamp}=strftime( "%Y%m%d%H%M%S", localtime);
}

sub getTimeStamp{
	my $self=shift;
	unless ($$self{timeStamp}){
		$self->_setError("No time stamp.");
		return undef;
	}
	
	return $$self{timeStamp};
}

sub getPicturesCounter{
	my $self=shift;
	return $self->_getConfigParameter('picturesCounter');
}

sub _setError{
	shift;
	$lastError= (caller(1))[3] . " @_";
}

sub _setConfig{
	my ($self,$key,$value)=@_;
	
	unless ($key && $value){
		$self->_setError("No key, or value passed.");
		return undef;
	}
	
	$$self{$key}=$value;
	1;
	
}

sub _getConfigParameter{
	my ($self,$parameter)=@_;
	$$self{$parameter};
}

sub new {
	my %config=(
		'picturesCounter' => '00001'
	);

	return bless \%config;
}

sub _execCommand{
	my ($self,@command)=@_;
	# TODO: Check if the device is sleeping. If so, wake it up (if possible).
	
	unshift @command,'gphoto2';
	if ($$self{device}){
		push @command,'--camera=' . '"' . $$self{device}. '"';
	}
	
	say "Command: @command";
	
	my @result=`@command 2>&1`;
	unless ($? == 0){
		$self->_setError("Error durring command execution: @command. The otuput was: @result");
		return undef;
	}
	$self->_setTimeStamp;
	return @result;
}

sub getBatteryLevel{
	my $self=shift;
	my @result=$self->_execCommand( '--get-config /main/status/batterylevel');
	foreach (@result){
		chomp $_;
		if (/Current: {0,}(.*)$/){
			return $1;
		}

	}
		$self->_setError('Failed to get battery status.');
		return undef;
}

sub getConnectedDevices{
	my $self=shift;
	my %result=();
	my @result=$self->_execCommand('--auto-detect');
	return undef unless defined $result[0];
	foreach (@result){
		next if (m/----|^Model.*Port/i);
		my ($camera,$port)=($1,$2) if (m/(.*?)(usb:.*)/i);
		if ($camera && $port ){
			$camera=~s/^\s+//;
			$camera=~s/\s+$//;
			$port=~s/^\s+//;
			$port=~s/\s+$//;
			
			# We may connect two Canon 40D cameras for example, but we cannot connect them the to the same port.
			$result{$port}=$camera;
		}

	}
	if ((keys %result) == 0 ){
		$self->_setError("No camera is connected, or recognized by gphoto2.");
		return undef;
	}
	return \%result;
}

sub setDevice{
	my ($self,$device)=@_;
	unless ($device){
		_setError("No device given.");
		return undef;
	}
	$self->_setConfig('device',$device);
}

sub setPicturePrefix{
	my ($self,$prefix)=@_;	
	unless ($prefix){
		_setError("No prefix given.");
		return undef;
	}
	$self->_setConfig('filePrefix',$prefix);

}

sub setPictureSufix{
	my ($self,$sufix)=@_;	
	unless ($sufix){
		_setError("No sufix given.");
		return undef;
	}
	$self->_setConfig('fileSufix',$sufix);
}

sub setOutputDir{
		my ($self,$outputDir)=@_;
		unless ($outputDir){
			$self->_setError("No output dir given.");
			return undef;
		}
		$self->_setConfig('outputDir',$outputDir);
		unless (-d $outputDir){
			$self->_setError("Output Dir: \'$outputDir\' is not accessible. The error was: $!");
			return undef;
		}
}

sub takeSingleShot{
	my ($self,$device)=@_;
	unless ($device){
		$device=$self->_getConfigParameter('device');
		unless ($device){
			$self->_setError("No device given !");
			return undef;
		}
	}
	# Take the picture BEFORE increasing the counter. This way we may return the counter any time for user reference.
	# I.e. way may print: Will take the picture with number: xxxxx
	
	########################## Take The Picture Here #################################
	my $workDir=$self->_getConfigParameter('outputDir');
	if ( defined $workDir){
		unless (chdir ($workDir)){
			$self->_setError("Failed to change directory to $workDir.\nThe error was: $!");
			return undef;
		}
	}
	my @command=('--capture-image-and-download','--force-overwrite','--filename');
	my $prefix=$self->_getConfigParameter('filePrefix');
	my $sufix=$self->_getConfigParameter('fileSufix');
	my $counter=$self->_getConfigParameter('picturesCounter');
	my $filename=undef;
	$filename=$prefix if $prefix;
	$filename .=$counter;
	$filename .=$sufix if $sufix;
	push @command,$filename;
	say "Command:";
	print Dumper \@command;

	$self->_execCommand(@command);
	my $c=$self->_getConfigParameter('picturesCounter');
	$c++;
	$self->_setConfig('picturesCounter',$c);
	$self->_setConfig('lastPictureName',$filename);
}

sub getLastPicturePath{
	my $self=shift;
	my $filename=$self->_getConfigParameter('lastPictureName');
	my $outputDir=$self->_getConfigParameter('outputDir');
	unless ($filename){
		$self->_setError("No picture taken yet !");
		return undef
	}
	return $outputDir . '/' . $filename;
}

sub takeBracketedShots{
	my ($self,$device,@stops)=@_;
	if ($#stops==-1){
		$self->_setError("No stops sent for bracketed photos !");
	}
	# Check if we have digits for bracketing.
	say "Taking pictures with the following compensations:  (@stops)";
	
	unless ($device){
		$device=$self->_getConfigParameter('device');
		unless ($device){
			$self->_setError("No device given !");
			return undef;
		}
	}
	
	########################## Take The Picture Here #################################
	my $workDir=$self->_getConfigParameter('outputDir');
	if ( defined $workDir){
		unless (chdir ($workDir)){
			$self->_setError("Failed to change directory to $workDir.\nThe error was: $!");
			return undef;
		}
	}
	
	foreach my $compensation (@stops){
		my @command=('--capture-image-and-download','--force-overwrite',"--set-config-value /main/capturesettings/exposurecompensation=$compensation", '--filename');
		my $prefix=$self->_getConfigParameter('filePrefix');
		my $sufix=$self->_getConfigParameter('fileSufix');
		my $counter=$self->_getConfigParameter('picturesCounter');
		my $filename=undef;
		$filename=$prefix if $prefix;
		$filename .=$counter ."[$_][$compensation]" ;
		
		#TODO: Set the bracketed exposure somewhere here !
		
		$filename .=$sufix if $sufix;
		push @command,$filename;
		say "Command:";
		print Dumper \@command;

		return undef unless ($self->_execCommand(@command));
		$self->_setConfig('lastPictureTaken',$filename);
	}
	my $c=$self->_getConfigParameter('picturesCounter');
	$c++;
	$self->_setConfig('picturesCounter',$c);
	
}

1;

__DATA__
http://islandinthenet.com/2012/08/hdr-photography-with-raspberry-pi-and-gphoto2/
