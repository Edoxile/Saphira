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

package Saphira::Module::Digest;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;

use Digest::MD5 qw( md5_hex );
use Digest::SHA qw( sha1_hex sha224_hex sha256_hex sha384_hex sha512_hex sha512224_hex sha512256_hex );
use MIME::Base64;

sub init {
    my ( $self, $message, $args ) = @_;

    $self->registerHook( 'said', \&handleSaidMD5 );
}

sub handleSaidMD5 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!md5 (.+)$/i );

    $server->{bot}->reply( $message->{who} . ': ' . md5_hex($1), $message );
}

sub handleSaidSHA1 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!sha1 (.+)$/i );

    $server->{bot}->reply( $message->{who} . ': ' . sha1_hex($1), $message );
}

sub handleSaidSHA224 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!sha224 (.+)$/i );

    $server->{bot}->reply( $message->{who} . ': ' . sha224_hex($1), $message );
}

sub handleSaidSHA256 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!sha256 (.+)$/i );

    $server->{bot}->reply( $message->{who} . ': ' . sha256_hex($1), $message );
}

sub handleSaidSHA384 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!sha384 (.+)$/i );

    $server->{bot}->reply( $message->{who} . ': ' . sha384_hex($1), $message );
}

sub handleSaidSHA512 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!sha512 (.+)$/i );

    $server->{bot}->reply( $message->{who} . ': ' . sha512_hex($1), $message );
}

sub handleSaidSHA512224 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!sha512224 (.+)$/i );

    $server->{bot}->reply( $message->{who} . ': ' . sha512224_hex($1), $message );
}

sub handleSaidSHA512256 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!sha512256 (.+)$/i );

    $server->{bot}->reply( $message->{who} . ': ' . sha512256_hex($1), $message );
}

sub handleSaidROT13 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!rot13 (.+)/i );

    my $input = $1;
    $input =~ tr/A-Za-z/N-ZA-Mn-za-m/;

    $server->{bot}->reply( "$message->{who}: $input", $message );
}

sub handleSaidReverse {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!reverse (.+)/i );

    $server->{bot}->reply( $message->{who} . ': ' . reverse($1), $message );
}

sub handleSaidBinary {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!binary (.+)/i );

    $server->{bot}->reply( $message->{who} . ': ' . unpack( 'B*', $1 ), $message );
}

sub handleSaidHex {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!hex(?:adecimal) (.+)/i );

    $server->{bot}->reply( $message->{who} . ': ' . unpack( 'H*', $1 ), $message );
}

sub handleSaidBase64 {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/!base64 (.+)/i );

    $server->{bot}->reply( $message->{who} . ': ' . encode_base64($1), $message );
}

1;