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

package Saphira::Module::Calculate;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;

use WWW::WolframAlpha;
our $wolframAlpha = undef;

sub init {
    my ( $self, $message, $args ) = @_;

    my $id = Config::IniFiles->new( -file => 'saphira.ini' )->val( 'irc', 'WolframAlphaID' );

    print "[E] WolframAlpha AppID not found; not registering hooks\n" if not defined $id;
    return unless defined $id;

    $wolframAlpha = WWW::WolframAlpha->new( appid => $id );

    $self->registerHook( 'said', \&handleSaidCalculate );
    $self->registerHook( 'said', \&handleSaidInlineCalculate );
}

sub handleSaidCalculate {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!calc(?:ulate)? (.+)$/ );
    if ( $1 =~ m/^[\-\+\^\/\*0-9\s]+$/ ) {
        my $input  = $1;
        $input =~ s/\^/\*\*/;
        my $answer = eval ($input);
        if ($@) {
            $server->{bot}->reply( "\x02Error:\x0F $@", $message );
        } else {
            $server->{bot}->reply( "$message->{who}: $input = $answer", $message );
        }
    } else {
        print '>> WolframAlpha query: [ ' . $1 . " ]\n";
        my $query     = $wolframAlpha->query( input => $1, format => 'plaintext' );
        my $response  = '';
        my @responses = ();

        if ( $query->success && $query->numpods > 0 ) {
            my @pods = @{ $query->pods };
            @pods = @pods[ 1 .. $#pods ];
            if ( scalar @pods gt 5 ) {
                $response = $message->{who}
                  . ': your query has to many possible answers. Please refine your query and try again.';
            } else {
                foreach my $pod ( @{ $query->pods } ) {
                    foreach my $subPod ( @{ $pod->subpods } ) {
                        push( @responses, $subPod->plaintext ) if defined $subPod->plaintext;
                    }
                }
                $response = $message->{who} . ', WolframAlpha returned: ' . join( ' and ', @responses );
            }
        } else {
            $response =
              'I\'m sorry ' . $message->{who} . ', I can\'t find anything for \'' . $1 . "' on WolframAlpha.\n";
        }
        $server->{bot}->reply( $response, $message );
    }
}

sub handleSaidInlineCalculate {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/calc(?:ulate)?\[(.+?)\]/ );
    if ( $1 =~ m/^[\-\+\^\/\*0-9\s]+$/ ) {
        my $input  = $1;
        $input =~ s/\^/\*\*/;
        my $answer = eval ($input);
        if ($@) {
            $server->{bot}->reply( "\x02Error:\x0F $@", $message );
        } else {
            $server->{bot}->reply( "$message->{who}: $input = $answer", $message );
        }
    } else {
        $server->{bot}
          ->reply( "\x02Error:\x0F Only simple calculations are possible when using inline calc[]!", $message );
    }
}

1;
