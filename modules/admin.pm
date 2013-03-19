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

sub init {
    my ( $self, $message, $args ) = @_;

    $self->registerHook( 'said', \&handleSaidKick );

    #$self->registerHook('said', \&handleSaidInvite);
}

sub getAuthLevel {
    my ( $server, $message ) = @_;
    my $user = $server->getUser( $message->{raw_nick} );
    return 0 unless defined $user;
    return 9 if $user->isOperator();
    return 6 if $user->isChannelOperator();
    return $user->getPermission( $message->{channel} );
}

sub handleSaidKick {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!kick\s(.+?)(?:\s(.+?))$/ );

    $server->getChannel( $message->{channel} )->kick( $1, $2 );
}

1;