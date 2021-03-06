#!/usr/bin/env perl

=begin comment
Copyright (c) 2013.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=end comment
=cut

package Saphira::Module::Manage;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;

sub init {
    my ( $self, $message, $args ) = @_;

    $self->registerHook( 'said',    \&handleSaidListModules );
    $self->registerHook( 'said',    \&handleSaidListAvailable );
    $self->registerHook( 'said',    \&handleSaidListLoaded );
    $self->registerHook( 'said',    \&handleSaidListActive );
    $self->registerHook( 'said',    \&handleSaidLoadModule );
    $self->registerHook( 'said',    \&handleSaidUnloadModule );
    $self->registerHook( 'said',    \&handleSaidReloadModule );
    $self->registerHook( 'said',    \&handleSaidEnableModule );
    $self->registerHook( 'said',    \&handleSaidDisableModule );
    $self->registerHook( 'said',    \&handleSaidModuleLoaded );
    $self->registerHook( 'said',    \&handleSaidModuleActive );
    $self->registerHook( 'said',    \&handleSaidInfo );
    $self->registerHook( 'said',    \&handleSaidUpdate );
    $self->registerHook( 'said',    \&handleSaidCmd );
    $self->registerHook( 'said',    \&handleSaidMode );
    $self->registerHook( 'said',    \&handleSaidRaw );
    $self->registerHook( 'said',    \&handleSaidLogin );
    $self->registerHook( 'said',    \&handleSaidLogout );
    $self->registerHook( 'said',    \&handleSaidRegister );
    $self->registerHook( 'said',    \&handleSaidChanJoin );
    $self->registerHook( 'said',    \&handleSaidChanPart );
    $self->registerHook( 'said',    \&handleSaidOp );
    $self->registerHook( 'said',    \&handleSaidDeop );
    $self->registerHook( 'said',    \&handleSaidSave );
    $self->registerHook( 'said',    \&handleSaidLog );
    $self->registerHook( 'said',    \&handleSaidListOps );
    $self->registerHook( 'said',    \&handleSaidWhoami );
    $self->registerHook( 'invited', \&handleInvited );
    $self->registerHook( 'kicked',  \&handleKicked );
}

sub getAuthLevel {
    my ( $server, $message ) = @_;
    return 6 if ( ( $message->{channel} ne 'msg' ) and $server->isChannelOperator( $message->{nick}, $message->{channel} ) );
    my $user = $server->getUser( $message->{raw_nick} );
    return 0 unless defined $user;
    return $user->getPermission( $message->{channel} );
}

sub handleInvited {
    my ( $wrapper, $server, $message ) = @_;

    print '>> Joining channel: ' . $message->{channel} . ', invited by: ' . $message->{inviter} . "\n";

    $server->joinChannel( $message->{channel} );
}

sub handleSaidListOps {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!list ops/ );

    my @ops   = ();
    my @users = $server->getUsers();
    foreach my $user (@users) {
        push( @ops, $user->getUsername() ) if $user->isOperator();
    }
    $server->{bot}->reply( "\x02Operators: \x0F" . join( ', ', @ops ) . '.', $message );
}

sub handleSaidLog {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!log/ );
    return unless ( getAuthLevel( $server, $message ) gt 6 );

    my $chan = $server->getChannel( $message->{channel} );
    return unless defined $chan;
    if ( $chan->enableLogging() ) {
        $server->{bot}->reply( "\x02Logging enabled.\x0F", $message );
    } else {
        $server->{bot}->reply( "\x02Failed.\x0F Perhaps logging is already enabled?", $message );
    }
    
}

sub handleSaidWhoami {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!whoami/ );

    my $user  = $server->getUser( $message->{raw_nick} );
    my $reply = '';
    if ( not defined $user ) {
        $reply = "You're not logged in at the moment.";
    } else {
        $reply =
          "You're logged in as" . ( $user->isOperator() ? ' operator' : '' ) . " \x02" . $user->getUsername() . ".\x0F";
    }
    $server->{bot}->reply( $reply, $message );
}

sub handleSaidSave {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{channel} ne 'msg' and $message->{body} =~ m/^!save/ );
    return unless ( getAuthLevel( $server, $message ) gt 6 );

    my $chan = $server->getChannel( $message->{channel} );
    return unless defined $chan;
    if ( $chan->setState(1) ) {
        $server->{bot}->reply( "\x02Channel state changed successfully.\x0F", $message );
    } else {
        $server->{bot}->reply( "\x02Channel state change failed.\x0F (Perhaps a MySQL error?)", $message );
    }
}

sub handleSaidChanJoin {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!join (.+?)(?: (.+?))?$/ );

    print '>> Joining channel: ' . $1 . ', invited by: ' . $message->{who} . "\n";

    my $channel = $1;
    my $key = $2 || '';

    $server->joinChannel( $channel, $key );
}

sub handleSaidChanPart {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!part (.+?)(?: (.+?))?$/ );
    return unless ( getAuthLevel( $server, $message ) gt 5 );

    print '>> Parting channel: ' . $1 . ', called by: ' . $message->{who} . "\n";

    my $channel = $1;
    my $msg     = $2;

    $server->partChannel( $channel, $msg );
}

sub handleSaidLogin {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!login ([^ ]+) ([^ ]+)/ );

    print '>> Logging in: <' . $message->{raw_nick} . '>, using username: ' . $1 . "\n";

    if ( Saphira::API::User::login( $wrapper, $server, $message->{who}, $1, $message->{raw_nick}, $2 ) ) {
        $server->{bot}->reply( "\x02Logged in succesful!\x0F", $message );
    } else {
        $server->{bot}->reply( "\x02Logging in failed!\x0F Perhaps you used the wrong password?", $message );
    }
}

sub handleSaidRegister {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!register ([a-zA-Z0-9\-_\.]+) ([^ ]+)/ );
    return unless not defined $server->getUser( $message->{raw_nick} );

    print '>> Registering: <' . $message->{raw_nick} . '>, using username: ' . $1 . "\n";

    if ( Saphira::API::User::register( $wrapper, $server, $message->{who}, $1, $message->{raw_nick}, $2 ) ) {
        $server->{bot}
          ->reply( "\x02Registered succesful!\x0F You've also been logged in for your convenience", $message );
    } else {
        $server->{bot}->reply( "\x02Registering failed!\x0F Probably a MySQL error. Try to kick my owner!", $message );
    }
}

sub handleSaidLogout {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!logout/ );
    my $user = $server->getUser( $message->{raw_nick} );
    if ( defined $user ) {
        $user->logout();
        $server->{bot}->reply( "\x02Successfuly logged out!\x0F", $message );
    } else {
        $server->{bot}->reply( "You're not even logged in, silly!", $message );
    }
}

sub handleSaidOp {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!op\s([a-zA-Z0-9\-_\.]+)/ );
    return unless ( getAuthLevel( $server, $message ) gt 8 );

    my $user = $server->getUserByName($1);

    $server->{bot}->reply( "User \x02$1\x0F wasn't found. (Is he/she logged in?)", $message ) if not defined $user;

    my $result = $user->setOperator(1);
    if ($result) {
        $server->{bot}->reply( "User \x02$1\x0F is now an operator.", $message );
    } else {
        $server->{bot}->reply( "\x02Error:\x0F user could not be opped. (Perhaps a MySQL problem?)", $message );
    }
}

sub handleSaidDeop {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!deop\s([a-zA-Z0-9\-_\.]+)/ );
    return unless ( getAuthLevel( $server, $message ) gt 8 );

    my $user = $server->getUserByName($1);

    $server->{bot}->reply( "User \x02$1\x0F wasn't found. (Is he/she logged in?)", $message ) if not defined $user;

    my $result = $user->setOperator(0);
    if ($result) {
        $server->{bot}->reply( "User \x02$1\x0F is not an operator anymore.", $message );
    } else {
        $server->{bot}->reply( "\x02Error:\x0F user could not be deopped. (Perhaps a MySQL problem?)", $message );
    }
}

sub handleSaidListModules {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!list(?: all)? modules$/ );

    my @availableModules = $wrapper->getAvailableModules();
    my @activeModules    = $wrapper->getActiveModules();
    my @loadedModules    = $wrapper->getLoadedModules();

    my %activeModulesHash = map { $_ => 1 } @activeModules;
    my %loadedModulesHash = map { $_ => 1 } @loadedModules;

    my @loadedButDisabledModules     = grep( !defined( $activeModulesHash{$_} ), @loadedModules );
    my @availableButNotLoadedModules = grep( !defined( $loadedModulesHash{$_} ), @availableModules );

    my $reply = ( "\x02Active:\x0F " . join( ', ', sort(@activeModules) ) . '.' );
    $reply .= ( " \x02Disabled:\x0F " . join( ', ', sort(@loadedButDisabledModules) ) . '.' )
      if ( scalar(@loadedButDisabledModules) > 0 );
    $reply .= ( " \x02Available:\x0F " . join( ', ', sort(@availableButNotLoadedModules) ) . '.' )
      if ( scalar(@availableButNotLoadedModules) > 0 );

    $server->{bot}->reply( $reply, $message );
}

sub handleSaidListAvailable {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!list available(?: modules)?$/ );

    $server->{bot}
      ->reply( ( 'Available modules: ' . join( ', ', sort( $wrapper->getAvailableModules() ) ) ), $message );
}

sub handleSaidListLoaded {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!list loaded(?: modules)?$/ );

    $server->{bot}->reply( ( 'Loaded modules: ' . join( ', ', sort( $wrapper->getLoadedModules() ) ) ), $message );
}

sub handleSaidListActive {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!list active(?: modules)?$/ );

    $server->{bot}->reply( ( 'Active modules: ' . join( ', ', sort( $wrapper->getActiveModules() ) ) ), $message );
}

sub handleSaidLoadModule {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!load(?: module)? ([^ ]+)(?: (.+))?/ );
    return unless ( getAuthLevel( $server, $message ) gt 6 );

    my $module = $1;
    my $args   = $2;

    if ( $module =~ /,/ ) {
        my @modules = split( ',', $module );
        foreach (@modules) {
            my $reply = $wrapper->loadModule( $_, $message );
            $server->{bot}->reply( "$reply->{string} [Status: $reply->{status}, Code: $reply->{code}]", $message );
        }
    } else {
        my $reply = $wrapper->loadModule( $module, $message, $args );
        $server->{bot}->reply( "$reply->{string} [Status: $reply->{status}, Code: $reply->{code}]", $message );
    }
}

sub handleSaidUnloadModule {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!unload(?: module)? (.+)/ );
    return unless ( getAuthLevel( $server, $message ) gt 6 );

    my @modules = split( ',', $1 );

  MODULE: foreach (@modules) {
        if ( lc($_) eq 'manage' ) {
            $server->{bot}->reply( "I can't unload the Manage module... How else would you control me?", $message );
            next MODULE;
        }
        my $reply = $wrapper->unloadModule($_);
        $server->{bot}->reply( "$reply->{string} [Status: $reply->{status}, Code: $reply->{code}]", $message );
    }
}

sub handleSaidReloadModule {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!reload(?: module)? ([^ ]+)(?: (.+))?/ );
    return unless ( getAuthLevel( $server, $message ) gt 6 );

    my $module = $1;
    my $args   = $2;

    if ( $module =~ /,/ ) {
        my @modules = split( ',', $module );

        foreach (@modules) {
            my $ret = $wrapper->reloadModule( $_, $message );
            $server->{bot}->reply( "$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message );
        }

    } else {
        my $ret = $wrapper->reloadModule( $module, $message, $args );
        $server->{bot}->reply( "$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message );
    }
}

sub handleSaidEnableModule {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!enable(?: module)? (.+)/ );
    return unless ( getAuthLevel( $server, $message ) gt 6 );

    my $ret = $wrapper->enableModule($1);

    $server->{bot}->reply( "$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message );
}

sub handleSaidDisableModule {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!disable(?: module)? (.+)/ );
    return unless ( getAuthLevel( $server, $message ) gt 6 );

    my $ret = $wrapper->disableModule($1);

    $server->{bot}->reply( "$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message );
}

sub handleSaidModuleLoaded {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!(?:is )?(?:module )?(.+)(?: loaded)\?$/ );

    $server->{bot}
      ->reply( ( $wrapper->moduleLoaded($1) ? 'It\'s loaded alright!' : 'Nope! Module not loaded.' ), $message );
}

sub handleSaidModuleActive {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!(?:is )?(?:module )?(.+)(?: active)\?$/ );

    $server->{bot}
      ->reply( ( $wrapper->moduleActive($1) ? 'It\'s active alright!' : 'Nope! Module not active.' ), $message );
}

sub handleSaidInfo {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^(?:!Saphira|Saphira\?|!info)$/i );

    $server->{bot}->reply( $server->{bot}->help(), $message );
}

sub handleSaidPassword {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!password\s([^ ])\s([^ ])$/ );
    my $user = $server->getUser( $message->{raw_nick} );
    return unless defined $user;

    $server->{bot}->reply(
        (
            $user->setPassword( $1, $2 )
            ? "\x02Password update successful!\x0F"
            : "\x02Password update failed!\x0F (Perhaps you entered the wrong password?)"
        ),
        $message
    );
}

sub handleSaidUpdate {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!update$/ );

    my @output = `git pull`;

    if ( $? ne 0 ) {
        $server->{bot}->reply( "\x02Error:\x0F " . join( '', @output ), $message );
    } else {
        $server->{bot}->reply( 'Successfully pulled update from github!', $message );
    }
}

sub handleSaidRaw {
    my ( $wrapper, $server, $message ) = @_;
    return unless ( $message->{body} =~ m/^!raw (.+)$/ );
    return unless ( getAuthLevel( $server, $message ) gt 6 );
    print ">> Sending raw IRC: '$1' by $message->{who}\n";
    $server->sendRawIRC( $1 . "\n" );
}

sub handleSaidMode {
    my ( $wrapper, $server, $message ) = @_;
    return unless ( $message->{channel} ne 'msg' and $message->{body} =~ m/^!mode (.+?)$/);
    return unless ( getAuthLevel( $server, $message) gt 5 );
    print ">> Setting mode: '$message->{channel} $1' by $message->{who}\n";
    $server->setMode("$message->{channel} $1");
}

sub handleSaidCmd {
    my ( $wrapper, $server, $message ) = @_;
    return unless ( $message->{body} =~ m/^!cmd (.+)$/ );
    my $cmd = $1;
    return
      unless ( ( getAuthLevel( $server, $message ) gt 8 ) and ( $message->{raw_nick} =~ m/^(.+?)\@edoxile\.net$/i ) );
    print ">> $1 is running raw command [ $cmd ]\n";

    my @output = `$cmd 2>&1`;

    my $prefix = '';
    if ( $? != 0 ) {
        $prefix .= "\x02Error:\x0F ";
    }

    $server->{bot}->reply( ( $prefix . join( '', @output ) ), $message );
}

sub handleKicked {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{kicked} eq $server->{bot}->nick );

    my $chan = $server->getChannel( $message->{channel} );

    return unless defined $chan;

    $server->joinChannel( $message->{channel} ) if $chan->getState() eq 1;
}

1;
