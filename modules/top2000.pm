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

package Saphira::Module::Top2000;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;

use LWP::Simple;
use JSON::XS;

our $parser = undef;
our $apiKey = undef;

sub init {
    my ( $self, $message, $args ) = @_;

    $parser = JSON::XS->new->ascii->pretty->allow_nonref;

    $self->registerHook( 'said', \&handleSaidTop2000 );
}

sub handleTop2000 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!top2000/ );
    my $user = $1;
    $user = $message->{real_who} if ( not defined $user or $user eq '' );
    my $url = "http://radiobox2.omroep.nl/track/search.json?q=channel.id:'2'%20AND%20startdatetime%3CNOW%20AND%20stopdatetime%3ENOW%20AND%20songfile.id%3E'0'";
    my $raw_data = get($url);
    if ( not defined $raw_data or $raw_data eq '' ) {
        $server->{bot}->reply("\x02Error:\x0F Couldn't fetch data.");
    }

    my $data = $parser->decode($raw_data);
    if ( not defined $data ) {
        $server->{bot}->reply("\x02Error:\x0F Couldn't decode data.");
    }

    my $reply = '';

    foreach my $track ( @{ $data->{results} } ) {
            $reply = "Op dit moment speelt: \x02" . $track->{songfile}->{artist} . ' - ' . $track->{songfile}->{title} . "\x0F.";
            last;
    }

    if ( $reply ne '' ) {
        $server->{bot}->reply( $reply, $message );
    } else {
        $server->{bot}->reply( "Er is iets fout gegaan. Probeer het later nog eens.", $message );
    }
}

1;
