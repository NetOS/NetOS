#!/usr/bin/perl
# openLDAP add initial user
# used to add the initial admin user
# version .1

use strict;
use Getopt::Long::Descriptive;
use Term::ReadKey;

my $admin_user;
my $domain;
my $base_dn;
my $company;
my $admin_password;
my @temp_array;

my ($opt,$usage) = describe_options('add_admin_user.pl %o',['admin|a=s',"The admin user name"],['domain|d=s',"The domain name for your organization"],['company|c=s',"The company name"],['help|h',"Print usage message and exit"],["example usage:"],["slapd_conf_setup.pl -a=admin -d=test.com"]);

print ($usage->text), exit if $opt->help;

$admin_user = $opt->admin;
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

if(!defined($admin_user))
{
	print "Name of your ldap admin account: ";
	$admin_user = <STDIN>;
}

#print "Enter your admin password: ";

#ReadMode('noecho');
#$admin_password = ReadLine(0);
#ReadMode('normal');

@temp_array = split(/\./,$domain);

foreach my $element (@temp_array)
{
	chomp($element);
	$base_dn = $base_dn . "dc=" . $element . ",";
}
chop($base_dn); #getting rid of that extra , at the end
chomp($admin_user);
$admin_user = "cn=$admin_user,$base_dn";
chomp($company);

#### create the temporary LDIF file ####
open LDIF, ">/tmp/admin.ldif";
my $temp = <<"END";
dn: $base_dn
objectclass: dcObject
objectclass: organization
o: $company
dc: $temp_array[0]

dn: $admin_user
objectclass: organizationalRole
cn: Admin
END

print LDIF $temp;
system("ldapadd -x -D \"$admin_user\" -W -f /tmp/admin.ldif");
`rm /tmp/admin.ldif`;
