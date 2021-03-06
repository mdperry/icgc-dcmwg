#!/usr/bin/env perl 
#===============================================================================
#
#         FILE:  get_dictionaries.pl
#
#        USAGE:  ./get_dicitonaries.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Brett Whitty (), Brett.Whitty@oicr.on.ca
#      COMPANY:  Ontario Institute for Cancer Research
#      VERSION:  1.0
#      CREATED:  01/24/2013 09:45:40
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Getopt::Long;

use File::Slurp;
use JSON;
use MIME::Base64;
use Cwd qw{ abs_path };

my $output;
my $user;
my $pass;

GetOptions(
    'output|o=s'    =>  \$output,
    'user|u=s'      =>  \$user,
    'pass|p=s'      =>  \$pass,
);

unless (defined($output) && -d $output) {
    die "Must provide an output directory that exists with --output";
}

unless (defined($user) && defined($pass)) {
    die "Must provide a user and password with --user / --pass flags";        
}

my $server  = 'submissions.dcc.icgc.org';
my $url     = "https://$server/ws";

my $auth    = 'X-DCC-Auth '.encode_base64("$user:$pass");
chomp $auth;

$output = abs_path($output);

print qq{curl -k -v -XGET $url/dictionaries -H "Authorization: $auth" -H "Accept: application/json"\n};
my $json = `curl -k -v -XGET $url/dictionaries -H "Authorization: $auth" -H "Accept: application/json"`;
my $obj = decode_json($json);

foreach my $item(@{$obj}) {
    my $version = $item->{'version'};

    my $json = `curl -k -v -XGET $url/dictionaries/$version -H "Authorization: $auth" -H "Accept: application/json"`;

    my $jsonp = JSON->new->allow_nonref;
    my $obj = $jsonp->decode($json);
    $json = $jsonp->pretty->encode($obj); # pretty-printing

    write_file($output.'/'.$version.'.json', $json);
}
