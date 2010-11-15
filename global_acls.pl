#!/usr/bin/perl
# openLDAP global acls
# used to add default global acls
# version .1

use strict;

my @paths = ("/etc/openldap/","/usr/local/etc/openldap/");
my $path = check_for_config_file(@paths);
my $config_file = $path. "slapd.access.conf";

my $acls = <<"END";
access to attr=userPassword
        by self =xw
        by anonymous auth
        by * none

      access to *
        by self write
        by users read
        by * none

access to attr=cn,entry
	by * read
END

open ACLS, ">$config_file";
print ACLS $acls;
close ACLS;

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
