#!/usr/bin/perl
# openLDAP secure ldap
# used to add some basic security to the ldap installation
# version .1

use strict;

my @paths = ("/etc/openldap/","/usr/local/etc/openldap/");
my $path = check_for_config_file(@paths);
my $ssl_path = $path . "ssl";

unless(-d $ssl_path){
	mkdir($ssl_path) or die "You are running this as a user who doesn't have rights to make a directory in $path\n";
}

chdir($ssl_path);
`openssl req -newkey rsa:1024 -x509 -nodes -out ldap_server.pem -keyout ldap_server.pem -days 3650`;

sub check_for_config_file
{
	my @paths = @_;
	foreach my $path (@paths)
	{
		if(-e "$path/slapd.conf")
		{
			return $path;
		}
	}
	die "Couldn't find the config file. We looked for it in $paths[0] and $paths[1]";
}
