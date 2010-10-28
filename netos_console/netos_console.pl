#!/usr/bin/env perl

use strict;
use Tk;
use YAML ();
use Net::LDAP;

draw_window();

sub draw_window{
	
	my $ldap;
	my $mw = new MainWindow;
	$mw->geometry('1024x768');
	
	#menu
	my $menu_bar = $mw->Menu();
	$mw->configure(-menu=>$menu_bar);
	
	#right and left side list boxes
	my $right_list_box = $mw->Listbox(-selectmode=>'single',-width=>95,-height=>45);
	my $left_list_box = $mw->Listbox(-selectmode=>'single',-width=>50,-height=>45);
	$left_list_box->insert('end');
	$right_list_box->insert('end');
	
	#menu buttons
	my $file_btn = $menu_bar -> cascade(-label=>"File", -underline=>0, -tearoff => 0);
	my $edit_btn = $menu_bar -> cascade(-label=>"Edit", -underline=>0, -tearoff => 0);
	my $action_btn = $menu_bar -> cascade(-label=>"Action", -underline=>0, -tearoff => 0);
	
	#submenu buttons
	$file_btn->command(-label =>"Exit", -underline => 1,-command => sub { exit } );
	$edit_btn->command(-label => "Settings", -underline => 2,-command => sub { display_edit_settings() } );
	$action_btn->command(-label => "Connect", -underline => 0, -command => sub {$ldap = ldap_bind($ldap); populate_tree($ldap,$left_list_box)});
	$action_btn->command(-label => "Add User", -underline=>2, -command=> sub{ add_user() } );
	$action_btn->command(-label => "Delete User", -underline=>2, -command=> sub{ del_user() } );
	$action_btn->command(-label => "Edit User", -underline=>2, -command=> sub{ edit_user() } );
	$action_btn->separator();
	$action_btn->command(-label => "Create OU", -underline=>0, -command=> sub{ create_ou() } );
	$action_btn->command(-label => "Delete OU", -underline=>4, -command=> sub{ del_ou() } );
	$action_btn->command(-label => "Edit OU", -underline=>5, -command=> sub{ edit_ou() } );

	$left_list_box->grid(-row=>1,-column=>1);
	$right_list_box->grid(-row=>1,-column=>2);	
	
	MainLoop;
}

sub add_user{
	exit;
}

sub del_user{
	
}

sub edit_user{
	
}

sub create_ou{
	
}

sub del_ou{
	
}

sub edit_ou{
	
}

sub populate_tree{
	my $l = shift;
	my $list_box = shift;
	
	my $settings;
	if(-e "settings.yml")
	{
		$settings = YAML::LoadFile("settings.yml");
	}
	else
	{
		#display a warning somehow that they need to go edit the connection settings first.
	}
	
	my $result = $l->search(base => "$settings->{'base_dn'}", scope => "sub", filter => "(objectclass=top)");

	#$result->code && die $result->error;

	my $list_length = $list_box->size();
	$list_box->delete(0,$list_length);
	my $i = 0;
	foreach my $entry ($result->entries)
	{
		if(defined($entry->get_value('ou')))
		{
			$list_box->insert($i, $entry->get_value('ou'));
		}
		if(defined($entry->get_value('cn')))
		{
			$list_box->insert($i, $entry->get_value('cn'));
		}
		$i++;
	}
}

sub display_edit_settings{
	my $settings;
	if(-e "settings.yml")
	{
		$settings = YAML::LoadFile("settings.yml");
	}
	else
	{
		`touch settings.yml`;
		$settings = YAML::LoadFile("settings.yml");
	}
	my $settings_window = new MainWindow;
	$settings_window->geometry('640x480');
	my $header = $settings_window->Label(-text => 'Connection Settings');
	my $server_label = $settings_window->Label(-text => 'Server Address:');
	my $port_label = $settings_window->Label(-text => 'Port:');
	my $base_dn_label = $settings_window->Label(-text => 'Base DN:');
	my $user_label = $settings_window->Label(-text => 'Username:');
	my $password_label = $settings_window->Label(-text => 'Password:');
	my $server_entry = $settings_window->Entry(-textvariable=>$settings->{'server'});
	my $port_entry = $settings_window->Entry(-textvariable=>$settings->{'port'});
	my $base_dn_entry = $settings_window->Entry(-textvariable=>$settings->{'base_dn'});
	my $user_entry = $settings_window->Entry(-textvariable=>$settings->{'user'});
	my $password_entry = $settings_window->Entry(-textvariable=>$settings->{'password'});
	my $save_btn = $settings_window->Button(-text=>'Save Settings', -command=> sub{ save_settings($server_entry,$port_entry,$base_dn_entry,$user_entry,$password_entry,$settings_window) });
	
	$header->grid(-row=>1,-column=>1,-columnspan=>2);
	$server_label->grid(-row=>2,-column=>1);
	$server_entry->grid(-row=>2,-column=>2);
	$port_label->grid(-row=>3,-column=>1);
	$port_entry->grid(-row=>3,-column=>2);
	$base_dn_label->grid(-row=>4,-column=>1);
	$base_dn_entry->grid(-row=>4,-column=>2);
	$user_label->grid(-row=>5,-column=>1);
	$user_entry->grid(-row=>5,-column=>2);
	$password_label->grid(-row=>6,-column=>1);
	$password_entry->grid(-row=>6,-column=>2);
	$save_btn->grid(-row=>7,-column=>1,-columnspan=>2);
	
	MainLoop;
}

sub save_settings{
	my $server = shift;
	my $port = shift;
	my $base_dn = shift;
	my $user = shift;
	my $password = shift;
	my $settings_window = shift;
	my $settings = {};
	
	$settings->{'server'} = $server->get();
	$settings->{'port'} = $port->get();
	$settings->{'base_dn'} = $base_dn->get();
	$settings->{'user'} = $user->get();
	$settings->{'password'} = $password->get();
	YAML::DumpFile('settings.yml',$settings);
	$settings_window->destroy();
}

sub ldap_bind{
	my $l = shift;
	my $settings;
	if(-e "settings.yml")
	{
		$settings = YAML::LoadFile("settings.yml");
	}
	else
	{
		#display a warning somehow that they need to go edit the connection settings first.
	}
	
	$l = Net::LDAP->new($settings->{'server'},port => $settings->{'port'}, version => 3) or die "$@";
	
	my $user = "cn=$settings->{'user'},$settings->{'base_dn'}";
	my $mesg = $l->bind($user,password => $settings->{'password'}) or die "$@";
	
	return $l;
}