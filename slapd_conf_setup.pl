#!/usr/bin/perl
# openLDAP slapd.conf setup
# run to configure slapd.conf
# version .1

use strict;
use Getopt::Long::Descriptive;
use Term::ReadKey;

my $admin_user;
my $domain;
my $base_dn;
my $admin_password;
my @temp_array;
my @paths = ("/etc/openldap/slapd.conf","/usr/local/etc/openldap/slapd.conf");

my $config_file = check_for_config_file(@paths);

my ($opt,$usage) = describe_options('slapd_conf_setup.pl %o',['admin|a=s',"The admin user name"],['domain|d=s',"The domain name for your organization"],['help|h',"Print usage message and exit"],["example usage:"],["slapd_conf_setup.pl -a=admin -d=test.com"]);

print ($usage->text), exit if $opt->help;

$admin_user = $opt->admin;
$domain = $opt->domain;

if(!defined($domain))
{
	print "Your domain name (for example domain.com): ";
	$domain = <STDIN>;
}

if(!defined($admin_user))
{
	print "Name of your ldap admin account: ";
	$admin_user = <STDIN>;
}

print "Enter your admin password: ";

ReadMode('noecho');
$admin_password = ReadLine(0);
ReadMode('normal');

#taking the user input and switching it to dc=domain,dc=com
@temp_array = split(/\./,$domain);

foreach my $element (@temp_array)
{
	chomp($element);
	$base_dn = $base_dn . "dc=" . $element . ",";
}
chop($base_dn); #getting rid of that extra , at the end
chomp($admin_user);
$admin_user = "cn=$admin_user,$base_dn";

#### Generate a hashed password for the admin in ldap####
my $hashed_password = `slappasswd -h {MD5} -s $admin_password`;
chomp($hashed_password);
#########

#### open slapd config file and edit it ####
open SLAPDOLD, "<$config_file" or die "Can't open original config file";
my $temp_config = $config_file."~";
open SLAPDNEW, ">$temp_config" or die "Can't open temp config file";
while(<SLAPDOLD>)
{
	$_ =~ s/^suffix\s+.+/suffix\t\t"$base_dn"/;
	$_ =~ s/^rootdn\s+.+/rootdn\t\t"$admin_user"/;
	$_ =~ s/^rootpw\s+.+/rootpw\t\t$hashed_password/;
	print SLAPDNEW $_;
}
rename $temp_config,$config_file;
close SLAPDNEW;
close SLAPDOLD;

sub check_for_config_file
{
	my @paths = @_;
	foreach my $path (@paths)
	{
		if(-e $path)
		{
			return $path;
		}
	}
	die "Couldn't find the config file. We looked for it in $paths[0] and $paths[1]";
}
