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

package Saphira::Module::Quote;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;

my %buffer = {};
my @colors = ( 05, 04, 07, 08, 03, 09, 10, 11, 02, 12, 06, 13 );

sub init {
    my ( $self, $message, $args ) = @_;

    $self->registerHook('said', \&handleSaid);
    $self->registerHook('emoted', \&handleEmoted);
    
    $self->registerHook('said', \&handleSaidQuote);
    $self->registerHook('said', \&handleSaidSubstitute);
    $self->registerHook('said', \&handleSaidQuoteUser);
    $self->registerHook('said', \&handleSaidSubstituteUser);
    $self->registerHook('said', \&handleSaidSwitch);
}

sub handleSaid {
    my ( $wrapper, $server, $message ) = @_;
    
    return if ( $message->{body} =~ m/^(sd?u?\/|qu?\/|!)/ or $message->{channel} eq 'msg' );
    
    $buffer{$server->getServerName . '-' . $message->{channel}} = () if not defined $buffer{$server->getServerName . '-' . $message->{channel}};
    my $msg = {};
    $msg->{channel} = $message->{channel};
    $msg->{who}     = $message->{real_who};
    $msg->{message} = $message->{body};
    $msg->{emoted}  = 0;
    unshift( @{$buffer{$server->getServerName . '-' . $message->{channel}}}, $msg );
    $buffer{$server->getServerName . '-' . $message->{channel}} = [ splice ( @{$buffer{$server->getServerName . '-' . $message->{channel}}}, 0, 249 ) ];
}

sub handleEmoted {
    my ( $wrapper, $server, $message ) = @_;
    
    return if ( $message->{channel} eq 'msg' );
    
    $buffer{$server->getServerName . '-' . $message->{channel}} = () if not defined $buffer{$message->{channel}};
    my $msg = {};
    $msg->{channel} = $message->{channel};
    $msg->{who}     = $message->{real_who};
    $msg->{message} = $message->{body};
    $msg->{emoted}  = 1;
    unshift( @{$buffer{$server->getServerName . '-' . $message->{channel}}}, $msg );
    $buffer{$server->getServerName . '-' . $message->{channel}} = [ splice( @{$buffer{$server->getServerName . '-' . $message->{channel}}}, 0, 99 ) ];
}

sub handleSaidQuote {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^q\/(.+?)\/(\w+)?/ );
    my $search = $1;
    my $modifiers = $2 || '';
    my $caseInsensitive = ($modifiers =~ m/i/);
    
    foreach my $msg (@{$buffer{$server->getServerName . '-' . $message->{channel}}}) {
        if ( ( $msg->{message} =~ m/$search/ ) or ( $caseInsensitive and $msg->{message} =~ m/$search/i ) ) {
            $server->{bot}->reply( ( $msg->{emoted} ? "* $msg->{who} $msg->{message}" : "<$msg->{who}> $msg->{message}" ), $message);
            last;
        }
    }
}

sub handleSaidSubstitute {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^s\/(.+?)\/(.*?)\/(\w+)?/ );
    my $search = $1;
    my $replace = $2;
    my $modifiers = $3 || '';
    my $caseInsensitive = ($modifiers =~ m/i/);
    
    foreach my $msg (@{$buffer{$server->getServerName . '-' . $message->{channel}}}) {
        if ( ( $msg->{message} =~ m/$search/ ) or ( $caseInsensitive and $msg->{message} =~ m/$search/i ) ) {
            my $response = $msg->{message};
            eval("\$response =~ s/$search/$replace/$modifiers;");
            $server->{bot}->reply( ( $msg->{emoted} ? "* $msg->{who} $response" : "<$msg->{who}> $response" ), $message);
            last;
        }
    }
}

sub handleSaidSwitch {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^sd\/(.+?)\/(.*?)\/(\w+)?/ );
    my $word1 = $1;
    my $word2 = $2;
    my $modifiers = $3 || '';
    my $caseInsensitive = ($modifiers =~ m/i/);
    
    foreach my $msg (@{$buffer{$server->getServerName . '-' . $message->{channel}}}) {
        my $response = $msg->{message};
        if ( $msg->{message} =~ m/$word1/ and $msg->{message} =~ m/$word2/ ){
            $response =~ s/\Q$word1\E/\x1A/g;
            $response =~ s/\Q$word2/$word1\E/g;
            $response =~ s/\x1A/\Q$word2\E/g;
            $response =~ s/\\(.)/$1/g;
        } elsif ( $caseInsensitive and $msg->{message} =~ m/$word1/i and $msg->{message} =~ m/$word2/i ) {
            $response =~ s/\Q$word1\E/\x1A/ig;
            $response =~ s/\Q$word2/$word1\E/ig;
            $response =~ s/\x1A/\Q$word2\E/ig;
            $response =~ s/\\(.)/$1/ig;
        } else {
            next;
        }
        $server->{bot}->reply( ( $msg->{emoted} ? "* $msg->{who} $response" : "<$msg->{who}> $response" ), $message);
    }
}

sub handleSaidQuoteUser {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^qu\/(.+?)\/(.+?)\/(\w+)?/ );
    my $who = $1;
    my $search = $2;
    my $modifiers = $3 || '';
    my $caseInsensitive = ($modifiers =~ m/i/);
    
    foreach my $msg (@{$buffer{$server->getServerName . '-' . $message->{channel}}}) {
        if ( $msg->{who} =~ m/^$who/i and ( ( $msg->{message} =~ m/$search/ ) or ( $caseInsensitive and $msg->{message} =~ m/$search/i ) ) ) {
            $server->{bot}->reply( ( $msg->{emoted} ? "* $msg->{who} $msg->{message}" : "<$msg->{who}> $msg->{message}" ), $message);
            last;
        }
    }
}

sub handleSaidSubstituteUser {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^su\/(.+?)\/(.+?)\/(.*?)\/(\w+)?/ );
    my $who = $1;
    my $search = $2;
    my $replace = $3;
    my $modifiers = $4 || '';
    my $caseInsensitive = ($modifiers =~ m/i/);
    
    foreach my $msg (@{$buffer{$server->getServerName . '-' . $message->{channel}}}) {
        if ( $msg->{who} =~ m/^$who/i and ( ( $msg->{message} =~ m/$search/ ) or ( $caseInsensitive and $msg->{message} =~ m/$search/i ) ) ) {
            my $response = $msg->{message};
            eval("\$response =~ s/$search/$replace/$modifiers;");
            $server->{bot}->reply( ( $msg->{emoted} ? "* $msg->{who} $response" : "<$msg->{who}> $response" ), $message);
            last;
        }
    }
}

sub handleSaidRainbow {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^r\/(.+?)\/(\w+)?/ );
    my $search = $1;
    my $modifiers = $2 || '';
    my $caseInsensitive = ($modifiers =~ m/i/);
    
    foreach my $msg (@{$buffer{$server->getServerName . '-' . $message->{channel}}}) {
        if ( ( $msg->{message} =~ m/$search/ ) or ( $caseInsensitive and $msg->{message} =~ m/$search/i ) ) {
            my $rainbow = $self->makeRainbow( $msg->{message}, $modifiers );
            $server->{bot}->reply( ( $msg->{emoted} ? "* $msg->{who} $rainbow" : "<$msg->{who}> $rainbow" ), $message);
            last;
        }
    }
}

sub makeRainbow {
    my ( $self, $input, $flags ) = @_;
    my $background = ( $flags =~ m/b/ );
    my $bg = scalar ( @colors ) - 1;
    my $fg = 0;
    my $output = '';
    my @in = split( '',$input );
    foreach my $char (@in) {
        if ( $char =~ m/\S/ ) {
            $output .= "\x03" . $colors[$fg] . ( $background ? ( ',' . $colors[$bg] . $char ) : $char );
            $fg = ++$fg % ( scalar (@colors) );
            $bg = ( --$bg >= 0 ? $bg : scalar ( @colors ) - 1 );
        } else {
            $output .= $char;
        }
    }
}

1;