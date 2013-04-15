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

package Saphira::Module::Log;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;

my %ps;
my $dbd;

sub init {
    my ( $self, $message, $args ) = @_;

    $dbd = $self->{wrapper}->createDBD();
    foreach my $server (values %{$wrapper->{servers}}) {
        $ps{$server->getName()} = 'INSERT INTO ' . $server->getName() . '_logs (type, when, who, raw_nick, channel, body, address) VALUES (?, NOW(), ?, ?, ?, ?, ?);';
    }

    $self->registerHook('said', \&handleSaid);
    $self->registerHook('emoted', \&handleEmoted);
    $self->registerHook('noticed', \&handleNoticed);
    $self->registerHook('chanjoin', \&handleChanJoin);
    $self->registerHook('chanpart', \&handleChanPart);
    $self->registerHook('topic', \&handleTopic);
    $self->registerHook('kicked', \&handleKicked);
    $self->registerHook('mode', \&handleMode);
}

sub isChannelLoggingEnabled {
    my ($server, $channel) = @_;
    my $chan = $server->getChannel($channel);
    return 0 unless defined $chan;
    return $chan->isLoggingEnabled();
}

sub handleSaid {
    my ( $wrapper, $server, $message ) = @_;
    return if ($message->{channel} eq 'msg');
    return unless isChannelLoggingEnabled($server, $message->{$channel});
    $ps{$server->getName()}->execute('said', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleEmoted {
    my ( $wrapper, $server, $message ) = @_;
    return unless isChannelLoggingEnabled($server, $message->{$channel});
    $ps{$server->getName()}->execute('emote', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleNoticed {
    my ( $wrapper, $server, $message ) = @_;
    return unless isChannelLoggingEnabled($server, $message->{$channel});
    $ps{$server->getName()}->execute('notice', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleChanJoin {
    my ( $wrapper, $server, $message ) = @_;
    return unless isChannelLoggingEnabled($server, $message->{$channel});
    $ps{$server->getName()}->execute('chanjoin', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleChanPart {
    my ( $wrapper, $server, $message ) = @_;
    return unless isChannelLoggingEnabled($server, $message->{$channel});
    $ps{$server->getName()}->execute('chanpart', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleTopic {
    my ( $wrapper, $server, $message ) = @_;
    return unless isChannelLoggingEnabled($server, $message->{$channel});
    $ps{$server->getName()}->execute('topic', $message->{who}, $message->{raw_nick}, $message->{channel}, $message->{body}, $message->{address});
}

sub handleKicked {
    my ( $wrapper, $server, $message ) = @_;
    return unless isChannelLoggingEnabled($server, $message->{$channel});
    $ps{$server->getName()}->execute('kicked', $message->{who}, $message->{kicked}, $message->{channel}, $message->{reason}, undef);
}

sub handleMode {
    my ( $wrapper, $server, $message ) = @_;
    return unless isChannelLoggingEnabled($server, $message->{channel});
    $ps{$server->getName()}->execute('mode', undef, $message->{source}, $message->{channel}, ($message->{mode} . ' ' . $message->{args}), undef);
}

1;