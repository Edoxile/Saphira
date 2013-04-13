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

package Saphira::Module::Netutils;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;


sub init {
    my ( $self, $message, $args ) = @_;

    $self->registerHook( 'said', \&handleSaidPing );
    $self->registerHook( 'said', \&handleSaidHost );
}

sub handleSaidPing {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ($message->{body} =~ m/^!ping ([\w\d\.\-]+)$/);
    
    my $ping = $1;
    my $ip   = '';
    my $host = '';
    
    if ( $ping =~ m/^((?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9]?[0-9]))$/ ){
        $ip = $ping;
        my @data = `host $ip`;
        $host = shift @data;
        $host =~ s/(?:.+?)domain name pointer (.+?).$/$1/;
    } else {
        $host = $ping;
        my @data = `host $host`;
        $ip = shift @data;
        $ip =~ s/(?:.+?)has address (.+?)/$1/;
    }
    $ip =~ s/\n//gs;
    $host =~ s/\n//gs;
    
    if(`host $ip` =~ m/not found:/) {
        $server->{bot}->reply("I'm sorry $message->{who}, the input is either an invalid hostname or an invalid ipv4-address.", $message);
    } else {
        my @data = `ping -q -c 4 $ip`;
        my $packetinfo = $data[3];
        my $timeinfo = $data[4];
        $packetinfo =~ s/\n//gs;
        $timeinfo =~ s/\n//gs;
        print ">> Ping [$message->{who}, $message->{real_who}, $host, $ip]: Ping statistics for $host ($ip): $packetinfo; $timeinfo\n";
        $server->{bot}->reply("$message->{real_who}: Ping statistics for $host ($ip): $packetinfo; $timeinfo", $message);
    }
}

sub handleSaidHost {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ($message->{body} =~ m/^!host ([\w\d\.\-]+)$/);
    
    my $host = $1;
    
    my @data = `host $host`;
    @data = grep ( !m/mail is handled by/, @data );
    
    $server->{bot}->reply("$message->{real_who}: host info for $host: " . join ( '; ', @data ), $message );
}
1;