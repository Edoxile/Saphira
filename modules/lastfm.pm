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

package Saphira::Module::Lastfm;
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

    $apiKey = Config::IniFiles->new( -file => 'saphira.ini' )->val( 'irc', 'LastFMkey' );

    print "[E] LastFM key not found; not registering hooks\n" if not defined $apiKey;
    return unless defined $apiKey;

    $parser = JSON::XS->new->ascii->pretty->allow_nonref;

    $self->registerHook( 'said', \&handleSaidNowPlaying );
}

sub handleSaidNowPlaying {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!n(?:ow)?p(?:laying)?(?: ([^\s]+))?$/ );
    my $user = $1;
    $user = $message->{who} if ( not defined $user or $user eq '' );
    my $url =
      'http://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&format=json&user=' . $user . '&api_key=' . $apiKey;
    my $raw_data = get($url);
    if ( not defined $raw_data or $raw_data eq '' ) {
        $server->{bot}->reply("\x02Error:\x0F Couldn't fetch data for user $user. Is his/her name spelled correctly?");
    }

    my $data = $parser->decode($raw_data);
    if ( not defined $data ) {
        $server->{bot}->reply("\x02Error:\x0F Couldn't fetch data for user $user. Is his/her name spelled correctly?");
    }

    my $reply = '';

    foreach my $track ( @{ $data->{recenttracks}->{track} } ) {
        if (    defined $track->{'@attr'}
            and defined $track->{'@attr'}->{nowplaying}
            and $track->{'@attr'}->{nowplaying} eq 'true' )
        {
            $reply = $user . " is now playing: \x02" . $track->{artist}->{'#text'} . ' - ';
            $reply .= $track->{album}->{'#text'} . ' - ' if ( defined $track->{album}->{'#text'} and $track->{album}->{'#text'} ne '' );
            $reply .= $track->{name} . "\x0F.";
            last;
        }
    }

    if ( $reply ne '' ) {
        $server->{bot}->reply( $reply, $message );
    } else {
        $server->{bot}->reply( "Couldn't find ", $message );
    }
}

1;
