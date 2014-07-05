#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';
use File::Path 'make_path';

my $outputDir="/data/certs/openssl/lightfromthepast.com";
my $secretKey="secret.key";
my $certName="lightfromthepast.com.cert";
my $certificateDays="3650"; # How long the certificate is valid (10 years).

unless (-d $outputDir){
		make_path $outputDir;
		die "Failed to create $outputDir" unless (-d $outputDir); 
}

chmod (0700,$outputDir) or 
	die "Failed to chmod $outputDir";

say $outputDir;
chdir ($outputDir) or 
	die "Failed to chdir to $outputDir";

unless (-f $secretKey){
	say "Generating new RSA key.";
	system("openssl","genrsa","-out","$secretKey");
	die "Failed to generate secret key. The error was: $!" if ($? != 0);
}

say "Generating certificate request ...";
system("openssl","req","-new","-key","$secretKey","-out","$certName" . '.req');
die "Failed to generate certificate request " if ($? != 0);

say "Generating self signed certificate ...";
system("openssl","x509","-req","-days","$certificateDays","-in","$certName" . ".req","-signkey",$secretKey,"-out","$certName");
die "Failed to generate self signed certificate" if ($? != 0);
