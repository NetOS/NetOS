#!/usr/bin/perl
# openLDAP add accounts
# used to add accounts
# version .1

use strict;
use Getopt::Long::Descriptive;
use Term::ReadKey;

my $user;
my $domain;
my $base_dn;
my $company;
my $user_password;
my @temp_array;

my ($opt,$usage) = describe_options('slapd_conf_setup.pl %o',['user|u=s',"The user name"],['domain|d=s',"The domain name for your organization"],['company|c=s',"The company name"],['help|h',"Print usage message and exit"],["example usage:"],["slapd_conf_setup.pl -u=user -d=test.com"]);

print ($usage->text), exit if $opt->help;

$user = $opt->user;
$domain = $opt->domain;
$company = $opt->company;

if(!defined($domain))
{
	print "Your domain name (for example domain.com): ";
	$domain = <STDIN>;
}

if(!defined($company))
{
	print "Your company name: ";
	$company = <STDIN>;
}

if(!defined($user))
{
	print "Name of your ldap user account: ";
	$user = <STDIN>;
}

print "Enter your user password: ";

ReadMode('noecho');
$user_password = ReadLine(0);
ReadMode('normal');
