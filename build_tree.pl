#!/usr/bin/perl
# NetOS build tree
# script used to display the LDAP tree. For now this will be used to create the navigational pane for the GUI admin program
# due to ease of creating this script.  To be replaced with something faster later.
# version .1

use strict;
use Getopt::Long::Descriptive;
use Net::LDAP;
use Term::ReadKey;

my ($opt,$usage) = describe_options('slapd_conf_setup.pl %o',['admin|a=s',"The admin user name (full dn)"],['password|p=s',"The admin password"],['base|d=s',"The base_dn for your search (should be top level)"],['server|s=s',"The ldap server"],['help|h',"Print usage message and exit"],["example usage:"],["slapd_conf_setup.pl -s=192.168.1.200"]);

print ($usage->text), exit if $opt->help;

my $server = $opt->server;
my $admin = $opt->admin;
my $password = $opt->password;
my $base_dn = $opt->base;

if(!defined($server))
{
	print "Your server (for example some.server.com or 192.168.1.10): ";
	$server = <STDIN>;
}

if(!defined($base_dn))
{
	print "Enter your base_dn (Top level of tree): ";
	$base_dn = <STDIN>;
}

if(!defined($admin))
{
	print "Name of your ldap admin account: ";
	$admin = <STDIN>;
}

if(!defined($password))
{
	print "Enter the admin password: ";
	ReadMode('noecho');
	$password = ReadLine(0);
	ReadMode('normal');
}

chomp($server);
chomp($admin);
chomp($password);
chomp($base_dn);

my $ldap = Net::LDAP->new($server, port => 636,version => 3) or die "$@";

#my $mesg = $ldap->start_tls(verify => 'none',sslversion => 'sslv3') or die "$@"; #this needs to be updated later when we get NetOS to the point of being it's own CA. but for now this will do and it's better than nothing.

#$mesg->code && die $mesg->error;

my $mesg = $ldap->bind($admin,password => $password) or die "$@";

$mesg->code && die $mesg->error;

my $result = $ldap->search(base => "$base_dn", scope => "sub", filter => "cn=*");

$result->code && die $result->error;

foreach my $entry ($result->entries)
{
	$entry->dump;
}

$mesg = $ldap->unbind;
