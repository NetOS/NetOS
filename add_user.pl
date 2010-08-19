#!/usr/bin/perl
# openLDAP add accounts
# used to add accounts
# still very manual and needs to be improved before the general public uses this.  Mainly a wrapper to make adding users easier
# version .1

use strict;
use Getopt::Long::Descriptive;
use Term::ReadKey;

my $user;
my $admin_user;
my $base_dn;
my $user_password;
my $dn;
my $cn;
my $first;
my $last;
my $email;
my $home_phone;
my @temp_array;

my ($opt,$usage) = describe_options('add_user.pl %o',['user|u=s',"The user name"],['basedn|b=s',"Where the user should be placed"],['first|f=s',"The user's first name"],['sn|s=s',"The user's last name"],['email|e=s',"The user's email"],['home_phone|h=s',"The user's home phone #"],['help|h',"Print usage message and exit"],["example usage:"],["slapd_conf_setup.pl -u=user -b=ou=users,dc=test,dc=com -f=John -l=Doe -e=john.doe\@company.com -h=123-456-7890"]);

print ($usage->text), exit if $opt->help;

$user = $opt->user;
$base_dn = $opt->basedn;
$first = $opt->first;
$last = $opt->sn;
$email = $opt->email;
$home_phone = $opt->home_phone;

if(!defined($base_dn))
{
	print "Base DN to place user (for example ou=users,dc=domain,dc=com): ";
	$base_dn = <STDIN>;
}

if(!defined($user))
{
	print "Name of your ldap user account: ";
	$user = <STDIN>;
}

if(!defined($first))
{
	print "First name of your ldap user account: ";
	$first = <STDIN>;
}

if(!defined($last))
{
	print "Last name of your ldap user account: ";
	$last = <STDIN>;
}

if(!defined($email))
{
	print "Email Address of your ldap user account: ";
	$email = <STDIN>;
}

if(!defined($home_phone))
{
	print "Home phone number of your ldap user account: ";
	$home_phone = <STDIN>;
}

chomp($first);
chomp($last);
chomp($user);

$cn = "$first $last";
print "Enter user password: ";

ReadMode('noecho');
$user_password = ReadLine(0);
ReadMode('normal');

$user_password = `slappasswd -h {MD5} -s $user_password`;
chomp($user_password);
chomp($dn);
chomp($cn);
chomp($email);
chomp($home_phone);
chomp($base_dn);
$dn = "cn=$user,$base_dn";

print "Enter your admin user's full dn: ";
$admin_user = <STDIN>;

my $ldif =<<"END";
dn: $dn
cn: $cn
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
mail: $email
givenName: $first
sn: $last
homePhone: $home_phone
userPassword: $user_password
END

open LDIF, ">/tmp/tmp.ldif";
print LDIF $ldif;
close LDIF;
system("ldapadd -x -D \"$admin_user\" -W -f /tmp/tmp.ldif");
`rm /tmp/tmp.ldif`;
