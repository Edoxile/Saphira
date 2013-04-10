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

sub init {
    my ( $self, $message, $args ) = @_;

    $self->registerHook('said', \&handleSaid);
    $self->registerHook('emoted', \&handleEmoted);
    
    $self->registerHook('said', \&handleSaidQuote);
    $self->registerHook('said', \&handleSaidSubstitute);
}

sub handleSaid {
    my ( $wrapper, $server, $message ) = @_;
    
    return if ( $message->{body} =~ m/^(s\/|q\/|!)/ or $message->{channel} eq 'msg' );
    
    $buffer{$message->{channel}} = () if not defined $buffer{$message->{channel}};
    my $msg = {};
    $msg->{channel} = $message->{channel};
    $msg->{who}     = $message->{real_who};
    $msg->{message} = $message->{body};
    $msg->{emoted}  = 0;
    unshift( @{$buffer{$message->{channel}}}, $msg );
    $buffer{$message->{channel}} = [ splice ( @{$buffer{$message->{channel}}}, 0, 99 ) ];
}

sub handleEmoted {
    my ( $wrapper, $server, $message ) = @_;
    
    return if ( $message->{channel} eq 'msg' );
    
    $buffer{$message->{channel}} = () if not defined $buffer{$message->{channel}};
    my $msg = {};
    $msg->{channel} = $message->{channel};
    $msg->{who}     = $message->{real_who};
    $msg->{message} = $message->{body};
    $msg->{emoted}  = 1;
    unshift( @{$buffer{$message->{channel}}}, $msg );
    $buffer{$message->{channel}} = [ splice( @{$buffer{$message->{channel}}}, 0, 99 ) ];
}

sub handleSaidQuote {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^q\/(.+?)\// );
    my $search = $1;
    
    foreach my $msg (@{$buffer{$message->{channel}}}) {
        if ( $msg->{message} =~ m/$search/i ) {
            $server->{bot}->reply( ( $msg->{emoted} ? "* $msg->{who} $msg->{message}" : "<$msg->{who}> $msg->{message}" ), $message);
            last;
        }
    }
}

sub handleSaidSubstitute {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^s\/(.+?)\/(.+?)\/([^ ]+)?/ );
    my $search = $1;
    my $replace = $2;
    my $modifiers = $3 || '';
    $modifiers =~ s/[^\w]//g;
    
    foreach my $msg (@{$buffer{$message->{channel}}}) {
        if ( $msg->{message} =~ m/$search/i ) {
            eval("\$msg->{message} =~ s/$search/$replace/i$modifiers;");
            $server->{bot}->reply( ( $msg->{emoted} ? "* $msg->{who} $msg->{message}" : "<$msg->{who}> $msg->{message}" ), $message);
            last;
        }
    }
}

1;