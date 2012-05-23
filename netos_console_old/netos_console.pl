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
	
	#right and left side boxes
	my $right_frame = $mw->Listbox(-selectmode=>'single',-width=>95,-height=>45);
	my $left_tree = $mw->Scrolled('Tree',-command=>sub{my $selection = shift; display_more($selection, $right_frame,$ldap)},-width=>50,-height=>53);
	
	#menu buttons
	my $file_btn = $menu_bar -> cascade(-label=>"File", -underline=>0, -tearoff => 0);
	my $edit_btn = $menu_bar -> cascade(-label=>"Edit", -underline=>0, -tearoff => 0);
	my $action_btn = $menu_bar -> cascade(-label=>"Action", -underline=>0, -tearoff => 0);
	
	#submenu buttons
	$file_btn->command(-label =>"Exit", -underline => 1,-command => sub { exit } );
	$edit_btn->command(-label => "Settings", -underline => 2,-command => sub { display_edit_settings() } );
	$action_btn->command(-label => "Connect", -underline => 0, -command => sub {$ldap = ldap_bind($ldap); populate_tree($ldap,$left_tree); $left_tree->autosetmode()});
	$action_btn->command(-label => "Add User", -underline=>2, -command=> sub{ add_user() } );
	$action_btn->command(-label => "Delete User", -underline=>2, -command=> sub{ del_user() } );
	$action_btn->command(-label => "Edit Object", -underline=>5, -command=> sub{ display_object($right_frame->get($right_frame->curselection())) } );
	$action_btn->separator();
	$action_btn->command(-label => "Create OU", -underline=>0, -command=> sub{ create_ou() } );
	$action_btn->command(-label => "Delete OU", -underline=>4, -command=> sub{ del_ou() } );

	$left_tree->grid(-row=>1,-column=>1);
	$right_frame->grid(-row=>1,-column=>2);
	
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
	my $tree = shift;
	
	my $settings;
	if(-e "settings.yml")
	{
		$settings = YAML::LoadFile("settings.yml");
	}
	else
	{
		#display a warning somehow that they need to go edit the connection settings first.
	}
	
	my $result = $l->search(base => "$settings->{'base_dn'}", scope => "sub", filter => "(objectclass=organizationalUnit)");

	#$result->code && die $result->error;

	#clear the box
	$tree->delete('all');
	#add the base
	#let me explain myself because I am sure in the morning I will not remember what I did here.
	#basically the ldap dn is structure very closely to how the Tree widget from Tk wants data to be.
	#the only problem is if I did a straight split and then loop over the array and build the tree from that then the results would be in the opposite order
	#so instead what I do is take the dn and split that into an array and then loop over it starting at the highest element working my way back
	#this gives the tree the loop of the ldap tree.  Might be a better way to do this but this works.
	my @base_dn = split(/\,/,$settings->{'base_dn'});
	my $j = @base_dn;
	my $dc = "";
	while($j != 0)
	{
		$j--;
		if(($j + 1) == @base_dn){
			$dc =$base_dn[$j];
		} else {
			$dc .= ".$base_dn[$j]";
		}
		
		$tree->add($dc,-text=>$base_dn[$j]);
	}

	foreach my $entry ($result->entries)
	{
		my $pos;
		my @dn = split(/\,/,$entry->dn());
		my $i = @dn;
		while($i != 0){
			$i--; #we are reversing the layout of the dn, basically flopping it so it fits the Tk tree model
			$pos .= "$dn[$i].";
			if($i == 0){
				chop($pos); #removes the trailing . that doesn't need to be there
			}
		}
		$tree->add($pos,-text=>"ou=" . $entry->get_value('ou'));
	}
}

sub display_more{
	my $selection = shift;
	my $right_frame = shift;
	my $l = shift;
	
	#clear list box
	my $size = $right_frame->size();
	$right_frame->delete(0,$size);
	my @temp = split(/\./,$selection);
	my $base_dn = "";
	my $i = @temp;
	while($i != 0) #flipping the order back around so it looks like a proper dn
	{
		$i--;
		$base_dn .= $temp[$i]. ",";
	}
	chop($base_dn); #gets rid of the extra ,
	my $result = $l->search(base => "$base_dn", scope => "one", filter => "(objectclass=top)");
	$i = @temp; 
	$i = $i - 1; #used to get the last value in the temp array.
	foreach my $entry ($result->entries)
	{
		if($entry->exists('ou'))
		{
			my $j = "ou=" . $entry->get_value('ou');
			if($temp[$i] ne $j) #temp[@temp] should be the last ou in the dn.  this will exclude that being showed in the right pane so people don't get confused.
			{
				$right_frame->insert('end',$entry->get_value('ou'));
			}
		}
		else
		{
			$right_frame->insert('end',$entry->get_value('cn'));
		}
	}
}

sub display_object{
	my $selection = shift;
	
	if(defined($selection))
	{
		warn $selection;
		my $object_window = new MainWindow;
		$object_window->geometry('640x480');

		my %ou = ('Name' => 'text');
		my %user = (1 => {'First Name' => 'text'},2 => {'Middle Initial' => 'text'}, 3 => {'Surname' => 'text'});
		my @hash_order = keys %user;
		@hash_order = sort {$a <=> $b} @hash_order;
		my @labels;
		foreach my $key (@hash_order)
		{
			my $temp_hashref = $user{$key};
			push(@labels,$object_window->Label(-text => keys %$temp_hashref)); 
		}
		my $i = 1; #row incrementer

		foreach my $label (@labels)
		{
			$label->grid(-row => $i, -column => 1);
			$i++;
		}
		
		MainLoop;
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