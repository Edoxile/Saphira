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

package Saphira::Module::Interactive;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;
use Switch;
use List::Util 'shuffle';

sub init {
    my ( $self, $message, $args ) = @_;

    $self->registerHook( 'said',   \&handleSaidThanks );
    $self->registerHook( 'said',   \&handleSaidAsk );
    $self->registerHook( 'emoted', \&handleEmotedThanks );
}

sub round {
    my $input = shift;
    return int ($input + 0.5);
}

sub handleSaidAsk {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^!ask (.+?)\?$/ );
    
    my $question = $1;
    my $reply = '';
    
    if ( $question =~ m/,| or / ) {
        my @choices = split ( m/, | or /, $question );
        @choices = grep( /\S/, @choices );
        @choices = shuffle(@choices);
        $reply = $message->{real_who} . ': ' . $choices[0] . '.';
    } else {
        $reply = $message->{real_who} . ': ' . (round(rand()) eq 1 ? 'yes' : 'no') . '.';
    }

    $server->{bot}->reply( $reply, $message );
}

sub handleSaidThanks {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/(thanks|thank you),? Saphira/i );

    $server->{bot}->reply( "You're welcome, $message->{real_who}!", $message );
}

sub handleEmotedThanks {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/(greets|kicks|hits|spanks|thanks|slaps) Saphira/si );

    my $reply = '';

    switch ($1) {
        case m/thanks/si        { $reply = 'No problem ' . $message->{real_who} . '!'; }
        case m/greets/si        { $reply = 'Hey there ' . $message->{real_who} . '!'; }
        case m/(hits|spanks|slaps)/si { $reply = 'That\'s not nice ' . $message->{real_who} . '...'; }
        case m/kicks/si {
            if ( $message->{real_who} ne $message->{who} ) {
                $server->{bot}->reply( 'Kicking me from inside your game, ' . $message->{real_who} . '? Don\'t be a wuss and try that again in IRC!', $message );
                return;
            }
            if ( $server->isChannelOperator( $message->{who}, $message->{channel} ) ) {
                $server->{bot}->reply(
                    'You\'re an operator, '
                      . $message->{who}
                      . ', you should set an example instead of kicking me for no reason...',
                    $message
                );
            } else {
                $server->{bot}->reply( 'Thanks ' . $message->{who} . '! Let me return the favour!', $message );
                $server->kick->kick( $message->{who}, $message->{channel}, 'Bye bye!' );
            }
            return;
        }
    }

    $server->{bot}->reply( $reply, $message );
}

1;
